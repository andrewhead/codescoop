import com.sun.jdi.*;
import com.sun.jdi.request.*;
import com.sun.jdi.event.*;
import com.sun.jdi.connect.*;

import java.io.InputStream;
import java.io.IOException;

import java.lang.ClassNotFoundException;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Scanner;

/**
 * REUSE: This code is based on the Trace.java example code for JDI.  Though all efforts have been
 * made to reduce the original code, there are a few dozen lines of boilerplate that were reused
 * because, honestly, there's presumably no other way to do the initializtion.
 */
public class SimplePrimitiveValueAnalysis {

    /**
     * @param args args[0] is a class name of the class you want to run.
     *      The class that this code analyzes need to be compiled with the `-g` flag, to preserve
     *      debugging symbols.  Otherwise, it will be impossible to find out what variables are on the
     *      stack when this utility steps through the class's code.  args[1] is the classpath that
     *      points to the class you want to run.
     */
    public static void main(String[] args) {

        /*
        String className = args[0];
        String classpath = "";
        if (args.length > 1) {
            classpath = args[1];
        }
        */
        String className = "RandomeNumberGenerator";
        String classpath = "src/com/acme/scrambler";
        SimplePrimitiveValueAnalysis tracer = new SimplePrimitiveValueAnalysis();

        Map values = null;
        try {
            values = tracer.run(className, classpath);
        } catch (ClassNotFoundException exception) {
            System.out.println("Main class " + className + " could not be found when launching the VM. Check that your second argument (classpath) points to your class.");
        }

    }

    public Map run(String className, String classpath) throws ClassNotFoundException {

        VirtualMachine vm = launchVirtualMachine(className, classpath);
        return runCode(vm);

    }

    private String streamToString(InputStream inputStream) {

        // REUSE: This trick comes from Stack Overflow post
        // http://stackoverflow.com/questions/309424/read-convert-an-inputstream-to-a-string
        Scanner scanner = new Scanner(inputStream).useDelimiter("\\A");
        return (String) (scanner.hasNext() ? scanner.next() : "");

    }

    public Map runCode(VirtualMachine vm) throws ClassNotFoundException {

        Map values = new HashMap();

        // This is the thread that will step through the code
        SimplePrimitiveValueTrackerThread trackerThread = new SimplePrimitiveValueTrackerThread(vm, values);
        trackerThread.start();

        // Shutdown begins when event thread terminates
        try {
            trackerThread.join();
        } catch (InterruptedException interruptedException) {
            // XXX: I honestly don't know when this would come up.
        }

        String vmStdout = streamToString(vm.process().getInputStream());
        String vmStderr = streamToString(vm.process().getErrorStream());

        if (vmStderr.contains("Error: Could not find or load main class")) {
            throw new ClassNotFoundException("Could not find or load main class");
        }

        return values;

    }

    public VirtualMachine launchVirtualMachine(String className, String classpath) {

        LaunchingConnector connector = findLaunchingConnector();

        // Prepare arguments to contain focal class name
        Map arguments = connector.defaultArguments();
        Connector.Argument mainArg = (Connector.Argument) arguments.get("main");
        mainArg.setValue(className);

        // REUSE: This classpath trick is thanks to the Stack Overflow tip
        // http://stackoverflow.com/questions/27140409/how-do-i-specify-the-classpath-for-a-jdi-launching-connector-using-eclipse
        Connector.Argument options = (Connector.Argument) arguments.get("options");
        options.setValue("-cp " + classpath);

        // And launch the VM!
        try {
            return connector.launch(arguments);
        } catch (IOException exc) {
            throw new Error("Failure launching VM: " + exc);
        } catch (IllegalConnectorArgumentsException exc) {
            throw new Error("Internal error: " + exc);
        } catch (VMStartException exc) {
            throw new Error("Target VM failed to initialize: " + exc.getMessage());
        }

    }

    public static LaunchingConnector findLaunchingConnector() {
        List connectors = Bootstrap.virtualMachineManager().allConnectors();
        for (int i = 0; i < connectors.size(); i++) {
            Connector connector = (Connector) connectors.get(i);
            if (connector.name().equals("com.sun.jdi.CommandLineLaunch")) {
                return (LaunchingConnector)connector;
            }
        }
        throw new Error("No launching connector");
    }

    /**
     * This thread walks step by step through a class and queries the values of all
     * variables on the stack at each step.
     */
    private class SimplePrimitiveValueTrackerThread extends Thread {

        private String[] STANDARD_PACKAGES = {"java/", "javax/", "sun/", "com/sun/"};
        private final VirtualMachine vm;
        private boolean connected = true;  // Connected to VM
        private Map values;

        /**
         * @param values data structure into which assignments to variables will be stored.
         *      You can look up a value by indexing on class name, line number, and variable name.
         */
        public SimplePrimitiveValueTrackerThread(VirtualMachine vm, Map values) {

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
            List stepRequests = new ArrayList(requestManager.stepRequests()); 
            for (Iterator stepRequestsIt = stepRequests.iterator(); stepRequestsIt.hasNext();) { 
                StepRequest stepRequest = (StepRequest) stepRequestsIt.next();
                if (stepRequest.thread().equals(threadReference)) { 
                    requestManager.deleteEventRequest(stepRequest); 
                } 
            } 

            // Now request another step.
            StepRequest stepRequest = requestManager.createStepRequest(threadReference, StepRequest.STEP_LINE, stepDirection);
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
            List entryRequests = new ArrayList(requestManager.methodEntryRequests()); 
            for (Iterator entryRequestsIt = entryRequests.iterator(); entryRequestsIt.hasNext();) {
                MethodEntryRequest entryRequest = (MethodEntryRequest) entryRequestsIt.next();
                entryRequest.disable();
            }

        }

        private void saveVariableValue(StepEvent event, String variableName, Value value) {

            String sourceFileName;
            try {
                sourceFileName = event.location().sourceName();
            } catch (AbsentInformationException aie) {
                sourceFileName = "Unknown (compile with -g flag)";
            }
            int lineNumber = event.location().lineNumber();

            Map lineToVariableMap = (Map) values.get(sourceFileName);
            if (lineToVariableMap == null) {
                lineToVariableMap = new HashMap();
                values.put(sourceFileName, lineToVariableMap);
            }

            Map variableToValuesMap = (Map) lineToVariableMap.get(Integer.valueOf(lineNumber));
            if (variableToValuesMap == null) {
                variableToValuesMap = new HashMap();
                lineToVariableMap.put(Integer.valueOf(lineNumber), variableToValuesMap);
            }

            List values = (List) variableToValuesMap.get(variableName);
            if (values == null) {
                values = new ArrayList();
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

                List visibleVariables = null;
                try {
                    visibleVariables = stackFrame.visibleVariables();
                // If this AbsentInformationException is occurring, it's likely because
                // the class that's being debugged wasn't compiled with the `-g` flag.
                } catch(AbsentInformationException aie) {}

                if (visibleVariables != null) {
                    Map variableValues = (Map) stackFrame.getValues(visibleVariables);
                    for (Iterator variableIt = visibleVariables.iterator(); variableIt.hasNext();) {
                        
                        LocalVariable variable = (LocalVariable) variableIt.next();

                        // The most important part: for each variable, we print out
                        // a readable representation of its data at that line.
                        Value variableValue = (Value) variableValues.get(variable);

                        // XXX: string references get deleted from the VM's memory when the execution
                        // stops.  This hack of calling the `toString` method apparently keeps the
                        // StringReference in memory long enough to be referenced after the VM stops.
                        // This deserves a more stable solution soon.
                        if (variableValue instanceof StringReference) {
                            StringReference stringVariable = (StringReference) variableValue;
                            String whatever = stringVariable.toString();
                        // Only save primitive values and Strings.  If we find objects on the stack,
                        // skip them: We need more complex analysis for useful object representations.
                        } else if (variableValue instanceof ObjectReference)
                            continue;

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
                sourcePath = (String) event.location().declaringType().sourcePaths("Java").get(0);
            } catch (AbsentInformationException absentInformationException) {}

            // Check to see if the source path is one of the standard libraries.
            // If so, we need to step out to keep from stepping in unnecessary code.
            if (sourcePath != null) {
                for (int i = 0; i < STANDARD_PACKAGES.length; i++) {
                    String standardPackagePrefix = STANDARD_PACKAGES[i];
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

}


