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
 * 
 */
public class VariableTracer {

    /**
     * @param args args[0] is a class name of the class you want tor un.
     *      The class that this code analyzes need to be compiled with the `-g` flag, to preserve
     *      debugging symbols.  Otherwise, it will be impossible to find out what variables are on the
     *      stack when this utility steps through the class's code.
     */
    public static void main(String[] args) {

        String className = args[0];
        VariableTracer tracer = new VariableTracer();

        try {
            tracer.run(className);
        } catch (ClassNotFoundException exception) {
            System.out.println("Main class " + className + " could not be found when launching " +
                    "the VM. Check your classpath.");
        }

    }

    public Map<String, Map<Integer, Map<String, Value>>> run(String className) throws ClassNotFoundException {

        VirtualMachine vm = launchVirtualMachine(className);
        return runCode(vm);

    }

    private String streamToString(InputStream inputStream) {

        // REUSE: This trick comes from Stack Overflow post
        // http://stackoverflow.com/questions/309424/read-convert-an-inputstream-to-a-string   
        Scanner scanner = new Scanner(inputStream).useDelimiter("\\A");
        return (scanner.hasNext() ? scanner.next() : "");

    }

    public Map<String, Map<Integer, Map<String, Value>>> runCode(VirtualMachine vm)
            throws ClassNotFoundException {

        Map<String, Map<Integer, Map<String, Value>>> values = (
                new HashMap<String, Map<Integer, Map<String, Value>>>());

        // This is the thread that will step through the code
        StepperThread stepperThread = new StepperThread(vm, values);
        stepperThread.start();

        // Shutdown begins when event thread terminates
        try {
            stepperThread.join();
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

    public VirtualMachine launchVirtualMachine(String className) {

        LaunchingConnector connector = findLaunchingConnector();

        // Prepare arguments to contain focal class name
        Map<String, Connector.Argument> arguments = connector.defaultArguments();
        Connector.Argument mainArg = arguments.get("main");
        mainArg.setValue(className);

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
