import com.sun.jdi.*;
import com.sun.jdi.request.*;
import com.sun.jdi.event.*;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;


/**
 * Debugger thread that steps through a program and logs all accesses and return values for fields
 * and methods for a set of objects that a caller wants to track.
 *
 * The basic algorithm of this class is as follows:
 * A user provides a list of locations of object definitions.  The objects created at these
 * locations will be watched, and all instances and accesses on those instances will be logged.
 * To do this, we follow these steps:
 *
 * 1. When a class is "prepared", check to see if the class contains the lines corresponding to
 *    the object definitions the caller provided.  If so, add a breakpoint on each of these lines.
 * 2. When these breakpoints are reached, take minimal steps until an instance of the object is
 *    defined or redefined.
 * 3. Once that instance is defined, start watching for all events where a method of that
 *    instance returns, or when a field on that instance is accessed.
 * 4. When a field is accessed or a method returns, store a record of that access in the
 *    "access history" for that instance.
 *
 * There are a couple of subtleties in the code below.  Specifically, we want to track
 * all accesses to anonymous objects that are returned by methods or field accesses on
 * a tracked instance.  This means that any time that a field or method returns an object
 * we start watching that object too (see step #3 above), and log all of the accesses made
 * on that object.  While this might seem unnecessary, it is necessary if we want to create
 * a fully-functional stub of the object without needed to pass in additional objects.
 *
 * Obscure assumptions: we assume there are never two instances that we're stepping through to
 * see them get defined at once.  This is not a reasonable assumption (as we could be interested,
 * for example, in an instance created in another instances constructor).  We'll handle that later.
 */
public class MemberAccessTrackerThread extends Thread {

    private String[] STANDARD_PACKAGES = {"java/", "javax/", "sun/", "com/sun/"};
    private final VirtualMachine mVm;
    private boolean connected = true;  // Connected to VM

    private Map<ObjectDefinition, List<AccessHistory>> mAccessHistories;
    private Map<Long, List<AccessHistory>> mAccessHistoriesByInstanceId = (
            new HashMap<Long, List<AccessHistory>>());
    private List<ObjectDefinition> mObjectDefinitions;
    private Set<ObjectDefinition> mObjectDefinitionsWithBreakpoints = new HashSet<ObjectDefinition>();

    private Map<ObjectDefinition, ObjectReference> mCurrentInstances = (
            new HashMap<ObjectDefinition, ObjectReference>());

    // These two fields are used to keep track of a definition that we're waiting
    // to happen, between when we reach a definition breakpoint and the actual definition.
    private ObjectDefinition mPendingDefinition = null;
    private int mPendingDefinitionFrameCount;

    public MemberAccessTrackerThread(VirtualMachine vm, List<ObjectDefinition> objectDefinitions,
            Map<ObjectDefinition, List<AccessHistory>> accessHistories) {

        super("ObjectAnalysis");
        this.mVm = vm;
        this.mAccessHistories = accessHistories;
        this.mObjectDefinitions = objectDefinitions;

        // Initialize a list of access histories for instances that will be created
        for (ObjectDefinition objectDefinition: this.mObjectDefinitions) {
            this.mAccessHistories.put(objectDefinition, new ArrayList<AccessHistory>());
        }

        // Start watching for creation of the classes where the object definitions will occur.
        // Once this class is created, we can add breakpoints to watch for object definition.
        EventRequestManager requestManager = mVm.eventRequestManager();
        ClassPrepareRequest classPrepareRequest = requestManager.createClassPrepareRequest();
        for (ObjectDefinition objectDefinition: objectDefinitions) {
            classPrepareRequest.addClassFilter(objectDefinition.getClassName());
        }
        classPrepareRequest.enable();

    }

    // When a class prepare event is encountered, we get to set breakpoints
    // to watch for all object definitions.  We have to wait for class preparation
    // because the classes where we want to add breakpoints might not be initially loaded.
    private void handleClassPrepareEvent(ClassPrepareEvent event) {

        EventRequestManager requestManager = this.mVm.eventRequestManager();

        // Get the name of the class that has just been prepared
        ReferenceType classType = event.referenceType();
        String preparedClassName = classType.name();

        // For all definitions, see if they reside in this class and add a breakpoint if they are.
        for (ObjectDefinition objectDefinition: this.mObjectDefinitions) {

            // Don't add a breakpoint if it has already been added
            if (this.mObjectDefinitionsWithBreakpoints.contains(objectDefinition)) continue;

            if (objectDefinition.getClassName().equals(preparedClassName)) {

                // Add a breakpoint for the first location we can find corresponding
                // to the line of the object definition
                List<Location> breakpointLocations = null;
                try {
                    breakpointLocations = classType.locationsOfLine(
                            objectDefinition.getLineNumber());
                // If the code hasn't been compiled with line numbers, then we won't set breakpoints.
                } catch (AbsentInformationException aio) {}

                if (breakpointLocations != null && breakpointLocations.size() > 0) {

                    Location firstLocation = breakpointLocations.get(0);
                    BreakpointRequest breakpointRequest = (
                            requestManager.createBreakpointRequest(firstLocation));
                    breakpointRequest.enable();

                    // Map the breakpoint to the location information for the definition.
                    breakpointRequest.putProperty("objectDefinition", objectDefinition);

                    // Flag this definition so we don't have to add another breakpoint for it
                    this.mObjectDefinitionsWithBreakpoints.add(objectDefinition);

                }
            }
        }
    }

    // When we reach a breakpoint, we're at a line where a definition will occur.
    // Start making minimal steps through the code until the definition happens
    private void handleBreakpointEvent(BreakpointEvent event) {

        // Note the definition that we're waiting for.  We're going to step until
        // this definition finally happens.
        BreakpointRequest request = (BreakpointRequest) event.request();
        ObjectDefinition objectDefinition = (ObjectDefinition) request.getProperty("objectDefinition");
        this.mPendingDefinition = objectDefinition;
        this.mPendingDefinitionFrameCount = getFrameCount(event.thread());
        
        // Note the current instance for the defined object.  We'll step until
        // we see the instance change from this to a new instance or null.
        ObjectReference instance = getInstanceFromStack(event.thread(), objectDefinition.getName());
        this.mCurrentInstances.put(objectDefinition, instance);

        // Start stepping until we see the instance change.
        requestStep(event.thread(), StepRequest.STEP_INTO);

    }

    // When stepping, we're waiting for a definition to finish.
    // Once this definition happens, we start watching the instance's fields and methods.
    private void handleStep(StepEvent event)  {

        // If we're stepping through code, we're waiting for the instance to be (re)defined.
        // Keep an eye on the previous instance value.  When it changes, then the instance
        // variable has been assigned, and we're ready to start watching it.
        ObjectReference instanceBeforeAssignment = this.mCurrentInstances.get(mPendingDefinition);
        ObjectReference currentInstance = getInstanceFromStack(event.thread(), mPendingDefinition.getName());
    
        // We only look for the instance (re)definition in the stack frame where it is
        // expected to be defined!  When we query in other frames, we get a 'null' for its value.
        boolean inSameFrameAsInstanceAssignment = false;
        int currentFrameCount = getFrameCount(event.thread());
        inSameFrameAsInstanceAssignment = (this.mPendingDefinitionFrameCount == currentFrameCount);

        if (inSameFrameAsInstanceAssignment && instanceBeforeAssignment != currentInstance) {

            // We only start watching the new instance if it's not null
            if (currentInstance != null) {

                // Update the current instance for the object definition
                this.mCurrentInstances.put(mPendingDefinition, currentInstance);

                // Get the list of access histories for this variable.  We'll add a new
                // access history for this instance soon.
                List<AccessHistory> instanceAccessHistories = this.mAccessHistories.get(mPendingDefinition);

                // Create a data structure for storing all data about all accesses to an instance
                // Tell the debugger to start watching all of the times that fields and methods
                // are getting accessed on this instance.
                AccessHistory instanceAccessHistory = watchInstance(currentInstance);
                if (instanceAccessHistory != null) {
                    instanceAccessHistories.add(instanceAccessHistory);
                }

            }

            // Regardless of whether the new instance is null, we explicitly set
            // this variable to null to indicate we're no longer watching this instance.
            this.mPendingDefinition = null;

        // If the instance hasn't changed yet, keep stepping
        } else {

            // The next few lines are what make it feasible to just step over all of the
            // code without taking way too long.  We keep stepping "into" the code, as long
            // as we don't hit the standard libraries.  As soon as we hit the standard libraries,
            // we step out until we're no longer in the standard libraries.  This keeps the
            // focus only on user-written code.
            int stepDirection = StepRequest.STEP_INTO;

            // Gets a path that looks like a package path but with slashes. See:
            // https://docs.oracle.com/javase/7/docs/jdk/api/jpda/jdi/com/sun/jdi/ReferenceType.html#sourcePaths(java.lang.String)
            String sourcePath = null;
            try {
                sourcePath = event.location().declaringType().sourcePaths("Java").get(0);
            } catch (AbsentInformationException absentInformationException) {}

            // Check to see if the source path is one of the standard libraries.
            // If so, we need to step out to keep from stepping in unnecessary code.
            if (sourcePath != null) {
                for (String standardPackagePrefix: STANDARD_PACKAGES) {
                    if (sourcePath.startsWith(standardPackagePrefix)) {
                        stepDirection = StepRequest.STEP_OUT;
                    }
                }
            }
            requestStep(event.thread(), stepDirection);
        }
    }

    // When exiting a method, look up the instance the method belongs to,
    // and update the access history for the instance with the method's return value.
    private void handleMethodExit(MethodExitEvent event) {

        Method method = event.method();
        Value returnValue = event.returnValue();

        // Get the top of the stack, from which we can get the instance the method was called on
	StackFrame stackFrame = null;
	try {
	    stackFrame = event.thread().frame(0);
	} catch (IncompatibleThreadStateException itse) {}

        // "this" is the object on which the method was called.
        // When instance filters aren't working for method exit events, this is our only
        // way to access the instance the method was called on.
        // If we couldn't find a "this", we're probably in a static method, and this isn't
        // the method exit that we were looking for.
        ObjectReference instance = stackFrame.thisObject();
        if (instance == null) return;

        Access access = makeAccessFromValue(returnValue);
        List<AccessHistory> accessHistories = 
                this.mAccessHistoriesByInstanceId.get(instance.uniqueID());

        // Save the result of this method call (skipping calls to the constructor)
        MethodIdentifier methodId = new MethodIdentifier(method.name(), method.argumentTypeNames());
        if (!(method.name().equals("<init>"))) {
            for (AccessHistory accessHistory: accessHistories) {
                accessHistory.addMethodCall(methodId, access);
            }
        }

    }

    // When a field on an instance was accessed, update the access history for the
    // instance with the value that the field resolved to at the time of access.
    private void handleAccessWatchpointEvent(AccessWatchpointEvent event) {

        ObjectReference instance = event.object();
        Field field = event.field();
        Value value = event.valueCurrent();
    
        // If this is a null instance, we might be dealing with a static variable
        // For right now, we ignore it, but we might need this at some time in the future.
        if (instance == null) return;

        Access access = makeAccessFromValue(value);
        List<AccessHistory> accessHistories =
                this.mAccessHistoriesByInstanceId.get(instance.uniqueID());
        for (AccessHistory accessHistory: accessHistories) {
            accessHistory.addFieldAccess(field.name(), access);
        }

    }

    private AccessHistory watchInstance(ObjectReference instance) {

        // Don't watch strings: we assume they're available anywhere and don't
        // have to be stubbed, as long as we have the value of the string.
        if (instance instanceof StringReference) return null;

        // If the access history for this instance doesn't exist, create a new one.
        AccessHistory accessHistory = createAccessHistory(instance);

        EventRequestManager requestManager = this.mVm.eventRequestManager();

        // Watch all field accesses for the instance
        for (Field field: instance.referenceType().allFields()) {
            AccessWatchpointRequest accessRequest = (
                    requestManager.createAccessWatchpointRequest(field));
            accessRequest.addInstanceFilter(instance);
            accessRequest.enable();
        }

        // Watch all method calls on the instance
        // We can't filter method exits by instance, like we do for field accesses.
        // This is due to a bug with the JDPA, as far as I learned.  We approximate
        // an instance filter by listening to all method exits on the class type, and
        // making looking up the instance from the method exit handler.
        // We make sure to only add one method exit event for each class.
        ReferenceType classReferenceType = instance.referenceType();
        boolean needExitRequestForClass = true;
        for (MethodExitRequest methodExitEvent: requestManager.methodExitRequests()) {
            if (methodExitEvent.getProperty("classFilterReferenceType").equals(classReferenceType))
                needExitRequestForClass = false;
        }
        if (needExitRequestForClass) {
            MethodExitRequest methodExitRequest = requestManager.createMethodExitRequest();
            methodExitRequest.addClassFilter(classReferenceType);
            methodExitRequest.putProperty("classFilterReferenceType", classReferenceType);
            methodExitRequest.enable();
        }

        // We're going to continually access the access history for the instance
        // by the instance ID (it's the one thing we'll continually have access to
        // as we step through the program.
        // Whenever an instance is watched more than once, create a new access history for
        // it.  We can't share the access histories for the same instance, as this might cause 
        // cycles in the access graph, which makes stubs with infinite nested accesses.
        // We need to update all of these access histories when the instance is accessed,
        // as we can't recall where in the access graph the instance was retrieved.  Currently,
        // this will create spurious accesses in some places of the access graph: we need a
        // more sophisticated way of disambiguating between references to an instance
        // in order to remove those spurious accesses.  For future work.
        List<AccessHistory> accessHistoriesForInstance =
                this.mAccessHistoriesByInstanceId.get(instance.uniqueID());
        if (accessHistoriesForInstance == null) {
            accessHistoriesForInstance = new ArrayList<AccessHistory>();
            this.mAccessHistoriesByInstanceId.put(instance.uniqueID(), accessHistoriesForInstance);
        }
        accessHistoriesForInstance.add(accessHistory);

        return accessHistory;

    }

    private String getNameForType(Type type) {
        if (type.name().equals("java.lang.String"))
            return "String";
        else
            return type.name();
    }

    private AccessHistory createAccessHistory(ObjectReference instance) {

        // Collect all the field names and method identifiers for the instance
        // We need these to initialize an empty access history
        List<Field> fields = instance.referenceType().allFields();
        List<String> fieldNames = new ArrayList<String>();
        List<String> fieldTypes = new ArrayList<String>();
        List<Method> methods = instance.referenceType().allMethods();
        List<MethodIdentifier> methodIds = new ArrayList<MethodIdentifier>();
        List<String> methodReturnTypes = new ArrayList<String>();
        for (Field field: fields) {
            fieldNames.add(field.name());
            String typeName = "unknown";
            try {
                typeName = getNameForType(field.type());
            } catch (ClassNotLoadedException exception) {}
            fieldTypes.add(typeName);
        }
        for (Method method: methods) {
            MethodIdentifier methodId = new MethodIdentifier(method.name(), method.argumentTypeNames());
            methodIds.add(methodId);
            String typeName = "unknown";
            try {
                typeName = getNameForType(method.returnType());
            } catch (ClassNotLoadedException exception) {}
            methodReturnTypes.add(typeName);
        }

        // Create an access history for the instance
        AccessHistory accessHistory = new AccessHistory(
                fieldNames, fieldTypes, methodIds, methodReturnTypes);

        return accessHistory;

    }

    // Format a field value or return value as an "access" that can be stored in an access history.
    private Access makeAccessFromValue(Value value) {

        Access access = null;

        // If the return value is a primitive, make a primitive access
        if (isPrimitive(value)) {
            Object valueObject = valueToObject(value);
            access = new PrimitiveAccess(valueObject);
        // If this is a new object, we need to start watching what **that** object returns
        // too!  So we start watching that object as well.  We refer to an access that
        // yields another object with the access history for that object.
        } else {
            ObjectReference instance = (ObjectReference) value;
            AccessHistory accessHistory = watchInstance(instance);
            access = accessHistory;
        }
        return access;

    }

    private void requestStep(ThreadReference threadReference, int stepDirection) {

        // Clear out all existing step requests (should mostly be past requests).
	EventRequestManager requestManager = mVm.eventRequestManager();
        List<StepRequest> stepRequests = new ArrayList<StepRequest>(requestManager.stepRequests()); 
        for (StepRequest stepRequest: stepRequests) { 
            if (stepRequest.thread().equals(threadReference)) { 
                requestManager.deleteEventRequest(stepRequest); 
            } 
        } 

        // Now request another step.
        // Not sure if it's necessary to do a MIN step here, but ideally we want to do the
        // smallest amount of execution until the the variable has been assigned.  My guess is that
        // MIN is important (and not LINE) when there are multiple statements on one line.
        StepRequest stepRequest = requestManager.createStepRequest(
            threadReference,
            StepRequest.STEP_MIN,
            stepDirection
        );
        stepRequest.addCountFilter(1);
        stepRequest.enable();

    }

    // REUSE: All four of the following functions were reused from the `Trace`
    // JDI example.  The logic of them is complex enough that I don't want to
    // mess around with it, and it looks like boilerplate that will be needed
    // regardless of whether I rename variables.
    @Override
    public void run() {
        EventQueue queue = mVm.eventQueue();
        while (connected) {
            try {
                EventSet eventSet = queue.remove();
                EventIterator it = eventSet.eventIterator();
                while (it.hasNext()) {
                    handleEvent(it.nextEvent());
                }
                eventSet.resume();
            } catch (InterruptedException exc) {
                // Ignore
            } catch (VMDisconnectedException discExc) {
                handleDisconnectedException();
                break;
            }
        }
    }

    synchronized void handleDisconnectedException() {
        EventQueue queue = mVm.eventQueue();
        while (connected) {
            try {
                EventSet eventSet = queue.remove();
                EventIterator iter = eventSet.eventIterator();
                while (iter.hasNext()) {
                    Event event = iter.nextEvent();
                    if (event instanceof VMDisconnectEvent) {
                        handleDisconnect((VMDisconnectEvent)event);
                    }
                }
                eventSet.resume(); // Resume the VM
            } catch (InterruptedException exc) {
                // ignore
            }
        }
    }

    public void handleDisconnect(VMDisconnectEvent event) {
        connected = false;
    }

    private int getFrameCount(ThreadReference thread) {
        try {
            return thread.frameCount();
        } catch (IncompatibleThreadStateException itse) {
            return -1;
        }
    }

    private void handleEvent(Event event) {
        if (event instanceof MethodExitEvent) {
            handleMethodExit((MethodExitEvent)event);
        } else if (event instanceof BreakpointEvent) {
            handleBreakpointEvent((BreakpointEvent)event);
        } else if (event instanceof ClassPrepareEvent) {
            handleClassPrepareEvent((ClassPrepareEvent)event);
        } else if (event instanceof StepEvent) {
            handleStep((StepEvent)event);
        } else if (event instanceof VMDisconnectEvent) {
            handleDisconnect((VMDisconnectEvent)event);
        } else if (event instanceof AccessWatchpointEvent) {
            handleAccessWatchpointEvent((AccessWatchpointEvent)event);
        } else { 
            // Unknown type of event was received
        }
    }

    private ObjectReference getInstanceFromStack(ThreadReference thread, String instanceName) {

	// Retrieve the top frame of the stack
	StackFrame stackFrame = null;
	try {
	    stackFrame = thread.frame(0);
	} catch (IncompatibleThreadStateException itse) {}

        // If we don't find the variable, the project has probably been compiled without debug
        // flags.  We'll just keep stepping through the code, but nothing will happen.
        LocalVariable instanceVariable = null;
        try {
            instanceVariable = stackFrame.visibleVariableByName(instanceName);
        } catch (AbsentInformationException aie) {}
        if (instanceVariable == null) return null;

        // Get the instance that is currently stored in the variable
        ObjectReference instance = (ObjectReference) stackFrame.getValue(instanceVariable);
        return instance;

    }

    private boolean isPrimitive(Value value) {
        return (!(value instanceof ObjectReference));
    }

    private Object valueToObject(Value value) {

        // Boilerplate, using the suggestions of Wayne Adams:
        // https://wayne-adams.blogspot.com/2011/12/examining-variables-in-jdi.html?showComment=1487723907415
        if (value instanceof BooleanValue) {
            BooleanValue booleanValue = (BooleanValue) value;
            return booleanValue.value();
        } else if (value instanceof IntegerValue) {
            IntegerValue integerValue = (IntegerValue) value;
            return integerValue.value();
        } else if (value instanceof ByteValue) {
            ByteValue byteValue = (ByteValue) value;
            return byteValue.value();
        } else if (value instanceof CharValue) {
            CharValue charValue = (CharValue) value;
            return charValue.value();
        } else if (value instanceof DoubleValue) {
            DoubleValue doubleValue = (DoubleValue) value;
            return doubleValue.value();
        } else if (value instanceof FloatValue) {
            FloatValue floatValue = (FloatValue) value;
            return floatValue.value();
        } else if (value instanceof LongValue) {
            LongValue longValue = (LongValue) value;
            return longValue.value();
        } else if (value instanceof ShortValue) {
            ShortValue shortValue = (ShortValue) value;
            return shortValue.value();
        } else if (value instanceof VoidValue) {
            VoidValue voidValue = (VoidValue) value;
            return null;
        // As mentioned in Wayne Adams' blog, make sure that StringReference
        // is checked before ObjectReference because a StringReference is
        // an ObjectReference, but it can be easily printed with its actual
        // string, instead of a hash value.
        } else if (value instanceof StringReference) {
            StringReference stringReference = (StringReference) value;
            return stringReference.value();
        } else if (value instanceof ObjectReference) {
            ObjectReference objectReference = (ObjectReference) value;
            return objectReference.toString();
        } else {
            return null;
        }

    }

}
