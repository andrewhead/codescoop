import com.sun.jdi.Bootstrap;
import com.sun.jdi.connect.*;
import com.sun.jdi.Value;
import com.sun.jdi.VirtualMachine;

import java.io.InputStream;
import java.io.IOException;

import java.lang.ClassNotFoundException;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Scanner;

/**
 * REUSE: This code is based on the Trace.java example code for JDI.  Though all efforts have been
 * made to reduce the original code, there are a few dozen lines of boilerplate that were reused
 * because, honestly, there's presumably no other way to do the initializtion.
 */
public class PrimitiveValueAnalysis {

    /**
     * @param args args[0] is a class name of the class you want to run.
     *      The class that this code analyzes need to be compiled with the `-g` flag, to preserve
     *      debugging symbols.  Otherwise, it will be impossible to find out what variables are on the
     *      stack when this utility steps through the class's code.  args[1] is the classpath that
     *      points to the class you want to run.
     */
    public static void main(String[] args) {

        String classpath = args[0];
        String className = "";
        if (args.length > 1) {
            className = args[1];
        }
        PrimitiveValueAnalysis tracer = new PrimitiveValueAnalysis();

        Map<String, Map<Integer, Map<String, List<Value>>>> values = null;
        try {
            values = tracer.run(className, classpath);
        } catch (ClassNotFoundException exception) {
            System.out.println("Main class " + className + " could not be found when launching " +
                    "the VM. Check that your second argument (classpath) points to your class.");
        }

        if (values != null) {
            for (String sourceFilename: values.keySet()) {
                Map<Integer, Map<String, List<Value>>> lineValues = values.get(sourceFilename);
                for (int lineNumber: lineValues.keySet()) {
                    Map<String, List<Value>> variableValues = lineValues.get(lineNumber);
                    for (String variableName: variableValues.keySet()) {
                        List<Value> valueList = variableValues.get(variableName);
                        for (Value value: valueList) {
                            System.out.println(sourceFilename + "," + Integer.toString(lineNumber) +
                                    "," + variableName + "," + value);
                        }
                    }
                }
            }
        }

    }

    public Map<String, Map<Integer, Map<String, List<Value>>>> run(
            String className, String classpath) throws ClassNotFoundException {

        VirtualMachine vm = launchVirtualMachine(className, classpath);
        return runCode(vm);

    }

    private String streamToString(InputStream inputStream) {

        // REUSE: This trick comes from Stack Overflow post
        // http://stackoverflow.com/questions/309424/read-convert-an-inputstream-to-a-string   
        Scanner scanner = new Scanner(inputStream).useDelimiter("\\A");
        return (scanner.hasNext() ? scanner.next() : "");

    }

    public Map<String, Map<Integer, Map<String, List<Value>>>> runCode(VirtualMachine vm)
            throws ClassNotFoundException {

        Map<String, Map<Integer, Map<String, List<Value>>>> values = (
                new HashMap<String, Map<Integer, Map<String, List<Value>>>>());

        // This is the thread that will step through the code
        PrimitiveValueTrackerThread trackerThread = new PrimitiveValueTrackerThread(vm, values);
        trackerThread.start();

        // Shutdown begins when event thread terminates
        try {
            trackerThread.join();
        } catch (InterruptedException interruptedException) {
            // XXX: I honestly don't know when this would come up.
        }

        String vmStdout = streamToString(vm.process().getInputStream());
        String vmStderr = streamToString(vm.process().getErrorStream());
        System.out.println(vmStdout);
        System.out.println(vmStderr);

        if (vmStderr.contains("Error: Could not find or load main class")) {
            throw new ClassNotFoundException("Could not find or load main class");
        }

        return values;

    }

    public VirtualMachine launchVirtualMachine(String className, String classpath) {

        LaunchingConnector connector = findLaunchingConnector();

        // Prepare arguments to contain focal class name
        Map<String, Connector.Argument> arguments = connector.defaultArguments();
        Connector.Argument mainArg = arguments.get("main");
        mainArg.setValue(className);

        // REUSE: This classpath trick is thanks to the Stack Overflow tip
        // http://stackoverflow.com/questions/27140409/how-do-i-specify-the-classpath-for-a-jdi-launching-connector-using-eclipse
        Connector.Argument options = arguments.get("options");
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
        List<Connector> connectors = Bootstrap.virtualMachineManager().allConnectors();
        for (Connector connector: connectors) {
            if (connector.name().equals("com.sun.jdi.CommandLineLaunch")) {
                return (LaunchingConnector)connector;
            }
        }
        throw new Error("No launching connector");
    }

}
