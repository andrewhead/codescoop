import com.sun.jdi.*;
import com.sun.jdi.request.*;
import com.sun.jdi.event.*;

import java.util.*;


/**
 * This thread walks step by step through a class and queries the values of all
 * variables on the stack at each step.
 */
public class StepperThread extends Thread {

    private String[] STANDARD_PACKAGES = {"java/", "javax/", "sun/", "com/sun/"};
    private final VirtualMachine vm;
    private boolean connected = true;  // Connected to VM
    private Map<String, Map<Integer, Map<String, List<Value>>>> values;

    /**
     * @param values data structure into which assignments to variables will be stored.
     *      You can look up a value by indexing on class name, line number, and variable name.
     */
    public StepperThread(VirtualMachine vm, Map<String, Map<Integer, Map<String, List<Value>>>> values) {

        super("Stepper");
        this.vm = vm;
        this.values = values;

        // Just listen for the first method entry.  Then we step the rest of the way
        // through the program (making sure to stop listening for method entries).
        EventRequestManager requestManager = vm.eventRequestManager();
        MethodEntryRequest methodEntryRequest = requestManager.createMethodEntryRequest();
        methodEntryRequest.setSuspendPolicy(EventRequest.SUSPEND_ALL);
        methodEntryRequest.enable();

    }

    private void handleEvent(Event event) {
        if (event instanceof MethodEntryEvent) {
            handleMethodEntry((MethodEntryEvent)event);
        } else if (event instanceof StepEvent) {
            handleStep((StepEvent)event);
        } else if (event instanceof VMDisconnectEvent) {
            handleDisconnect((VMDisconnectEvent)event);
        } else { 
            // Unknown type of event was received
        }
    }

    private void requestStep(ThreadReference threadReference, int stepDirection) {

        // Clear out all existing step requests (should mostly be past requests).
	EventRequestManager requestManager = vm.eventRequestManager();
        List<StepRequest> stepRequests = new ArrayList<StepRequest>(requestManager.stepRequests()); 
        for (StepRequest stepRequest: stepRequests) { 
            if (stepRequest.thread().equals(threadReference)) { 
                requestManager.deleteEventRequest(stepRequest); 
            } 
        } 

        // Now request another step.
        StepRequest stepRequest = requestManager.createStepRequest(
            threadReference,
            StepRequest.STEP_LINE,
            stepDirection
        );
        stepRequest.addCountFilter(1);
        stepRequest.enable();

    }

    private void handleMethodEntry(MethodEntryEvent event)  {

        // As soon as we enter any method, start the process of stepping from line to line.
        // Note: if we want to step through the program, DON'T resume the VM
        requestStep(event.thread(), StepRequest.STEP_INTO);

        // Another critical step is to stop listening for method entry events.
        // These events will interrupt our stepping through the program.
	EventRequestManager requestManager = vm.eventRequestManager();
        List<MethodEntryRequest> entryRequests = (
                new ArrayList<MethodEntryRequest>(requestManager.methodEntryRequests())); 
        for (MethodEntryRequest entryRequest: entryRequests) {
            entryRequest.disable();
        }

    }

    private String valueToString(Value value) {

        // Boilerplate, using the suggestions of Wayne Adams:
        // https://wayne-adams.blogspot.com/2011/12/examining-variables-in-jdi.html?showComment=1487723907415
        if (value instanceof BooleanValue) {
            BooleanValue booleanValue = (BooleanValue) value;
            return booleanValue.toString();
        } else if (value instanceof IntegerValue) {
            IntegerValue integerValue = (IntegerValue) value;
            return integerValue.toString();
        } else if (value instanceof ByteValue) {
            ByteValue byteValue = (ByteValue) value;
            return byteValue.toString();
        } else if (value instanceof CharValue) {
            CharValue charValue = (CharValue) value;
            return charValue.toString();
        } else if (value instanceof DoubleValue) {
            DoubleValue doubleValue = (DoubleValue) value;
            return doubleValue.toString();
        } else if (value instanceof FloatValue) {
            FloatValue floatValue = (FloatValue) value;
            return floatValue.toString();
        } else if (value instanceof LongValue) {
            LongValue longValue = (LongValue) value;
            return longValue.toString();
        } else if (value instanceof ShortValue) {
            ShortValue shortValue = (ShortValue) value;
            return shortValue.toString();
        } else if (value instanceof VoidValue) {
            VoidValue voidValue = (VoidValue) value;
            return voidValue.toString();
        // As mentioned in Wayne Adams' blog, make sure that StringReference
        // is checked before ObjectReference because a StringReference is
        // an ObjectReference, but it can be easily printed with its actual
        // string, instead of a hash value.
        } else if (value instanceof StringReference) {
            StringReference stringReference = (StringReference) value;
            return stringReference.toString();
        } else if (value instanceof ObjectReference) {
            ObjectReference objectReference = (ObjectReference) value;
            return objectReference.toString();
        } else {
            return null;
        }

    }

    private void saveVariableValue(StepEvent event, String variableName, Value value) {

        String printableValue = valueToString(value);
        String sourceFileName;
        try {
            sourceFileName = event.location().sourceName();
        } catch (AbsentInformationException aie) {
            sourceFileName = "Unknown (compile with -g flag)";
        }
        int lineNumber = event.location().lineNumber();

        Map<Integer, Map<String, List<Value>>> lineToVariableMap = values.get(sourceFileName);
        if (lineToVariableMap == null) {
            lineToVariableMap = new HashMap<Integer, Map<String, List<Value>>>();
            values.put(sourceFileName, lineToVariableMap);
        }

        Map<String, List<Value>> variableToValuesMap = lineToVariableMap.get(lineNumber);
        if (variableToValuesMap == null) {
            variableToValuesMap = new HashMap<String, List<Value>>();
            lineToVariableMap.put(lineNumber, variableToValuesMap);
        }

        List<Value> values = variableToValuesMap.get(variableName);
        if (values == null) {
            values = new ArrayList<Value>();
            variableToValuesMap.put(variableName, values);
        }
        values.add(value);

    }

    // Forward event for thread specific processing
    private void handleStep(StepEvent event)  {

	// Print out the current stack
	// REUSE: based on a tutorial from:
        // https://wayne-adams.blogspot.com/2011/12/examining-variables-in-jdi.html
	StackFrame stackFrame = null;
	try {
	    stackFrame = event.thread().frame(0);
	} catch (IncompatibleThreadStateException itse) {}

	if (stackFrame != null) {

	    List<LocalVariable> visibleVariables = null;
	    try {
		visibleVariables = stackFrame.visibleVariables();
            // If this AbsentInformationException is occurring, it's likely because
            // the class that's being debugged wasn't compiled with the `-g` flag.
	    } catch(AbsentInformationException aie) {}

	    if (visibleVariables != null) {
                Map<LocalVariable, Value> variableValues = (
                    stackFrame.getValues(visibleVariables));
                for (LocalVariable variable: visibleVariables) {

                    // The most important part: for each variable, we print out
                    // a readable representation of its data at that line.
                    Value variableValue = variableValues.get(variable);
                    saveVariableValue(event, variable.name(), variableValue);

                }
	    }
	}

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

        // Finally, prepare the next step through the program
        requestStep(event.thread(), stepDirection);

    }

    // REUSE: All four of the following functions were reused from the `Trace`
    // JDI example.  The logic of them is complex enough that I don't want to
    // mess around with it, and it looks like boilerplate that will be needed
    // regardless of whether I rename variables.
    @Override
    public void run() {
        EventQueue queue = vm.eventQueue();
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
        EventQueue queue = vm.eventQueue();
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

}
