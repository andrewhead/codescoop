import com.sun.jdi.*;
import com.sun.jdi.request.*;
import com.sun.jdi.event.*;

import java.util.*;


/**
 * This thread walks step by step through a class and queries the values of all
 * variables on the stack at each step.
 */
public class StepperThread extends Thread {

    private String[] STANDARD_PACKAGES = {"java.*", "javax.*", "sun.*", "com.sun.*"};
    private final VirtualMachine vm;
    private boolean connected = true;  // Connected to VM
    private Map<String, Map<Integer, Map<String, Value>>> values;

    /**
     * @param values data structure into which assignments to variables will be stored.
     *      You can look up a value by indexing on class name, line number, and variable name.
     */
    public StepperThread(VirtualMachine vm, Map<String, Map<Integer, Map<String, Value>>> values) {

        super("Stepper");
        this.vm = vm;
        this.values = values;

        // Prepare the first event: the initial method entry
        EventRequestManager mgr = vm.eventRequestManager();
        MethodEntryRequest menr = mgr.createMethodEntryRequest();
        menr.setSuspendPolicy(EventRequest.SUSPEND_ALL);
        // We should only have to look at classes outside the standard library
        // to find the one with the main.  Just skip the others.
        for (String standardPackage: STANDARD_PACKAGES) {
            menr.addClassExclusionFilter(standardPackage);
        }
        menr.enable();

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

    private void requestStep(ThreadReference threadReference) {

        // Clear out all existing step requests (should mostly be past requests).
	EventRequestManager mgr = vm.eventRequestManager();
        List<StepRequest> steps = new ArrayList<StepRequest>(mgr.stepRequests()); 
        for (StepRequest stepRequest: steps) { 
            if (stepRequest.thread().equals(threadReference)) { 
                mgr.deleteEventRequest(stepRequest); 
            } 
        } 

        // Now request another step.
        mgr = vm.eventRequestManager();
        StepRequest sr = mgr.createStepRequest(
            threadReference,
            StepRequest.STEP_LINE,
            StepRequest.STEP_INTO
        );
        sr.addCountFilter(1);

	// Only pay attention to classes that don't come from the standard library
        // This step has to be completed before we "enable" the request.
        for(String standardPackage: STANDARD_PACKAGES) {
            sr.addClassExclusionFilter(standardPackage);
        }

        sr.enable();

    }

    // Forward event for thread specific processing
    private void handleMethodEntry(MethodEntryEvent event)  {

        // "main" is my crude attempt to make sure we only start stepping through
        // the code at the beginning of the program.  I have also tried loading in
        // the first step after ThreadStartEvent or VMStartEvent, and neither of
        // these seem to work, so we're going with this.
        if (event.method().name().equals("main")) {
            requestStep(event.thread());
        }

        // Note: if we want to step through the program, DON'T resume the VM

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

        Map<Integer, Map<String, Value>> lineToVariableMap = values.get(sourceFileName);
        if (lineToVariableMap == null) {
            lineToVariableMap = new HashMap<Integer, Map<String, Value>>();
            values.put(sourceFileName, lineToVariableMap);
        }

        Map<String, Value> variableToValueMap = lineToVariableMap.get(lineNumber);
        if (variableToValueMap == null) {
            variableToValueMap = new HashMap<String, Value>();
            lineToVariableMap.put(lineNumber, variableToValueMap);
        }

        variableToValueMap.put(variableName, value);

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

        // Prepare the next step through the program
        requestStep(event.thread());

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
