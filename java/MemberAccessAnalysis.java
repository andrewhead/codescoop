import com.sun.jdi.Bootstrap;
import com.sun.jdi.connect.LaunchingConnector;
import com.sun.jdi.connect.Connector;
import com.sun.jdi.connect.VMStartException;
import com.sun.jdi.connect.IllegalConnectorArgumentsException;
import com.sun.jdi.Value;
import com.sun.jdi.VirtualMachine;

import soot.Type;
import soot.RefType;

import java.io.InputStream;
import java.io.IOException;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Scanner;


public class MemberAccessAnalysis {

    public static void main(String [] args) {
        MemberAccessAnalysis analysis = new MemberAccessAnalysis();
        try {
            analysis.run(args[1], args[0]);
        } catch (ClassNotFoundException cnfe) {
            System.out.println("Could not find class " + args[1]);
        }
    }

    public Map<ObjectDefinition, List<AccessHistory>> run(String pClassName, String pClasspath)
            throws ClassNotFoundException {

        // Run dataflow analysis to find which objects will be defined in this code
        DataflowAnalysis dataflowAnalysis = new DataflowAnalysis(pClasspath);
        dataflowAnalysis.analyze(pClassName);

        // Convert the found symbols to the object definition form this analysis expects.
        // Only try to track symbols that correspond to "refs" or objects.
        List<ObjectDefinition> objectDefinitions = new ArrayList<ObjectDefinition>();
        for (SymbolAppearance def: dataflowAnalysis.getDefinitions()) {
            Type defType = def.getType();
            if (defType instanceof RefType && !defType.toString().equals("java.lang.String")) {
                ObjectDefinition objectDefinition = new ObjectDefinition(
                        def.getSymbolName(), pClassName, def.getStartLine());
                objectDefinitions.add(objectDefinition);
            }
        }

        // Run the analysis using the discovered object definitions
        return run(pClassName, pClasspath, objectDefinitions);

    }

    public Map<ObjectDefinition, List<AccessHistory>> run(String pClassName, String pClasspath,
            List<ObjectDefinition> pObjectDefinitions) throws ClassNotFoundException {
        VirtualMachine vm = launchVirtualMachine(pClassName, pClasspath);
        return runCode(vm, pObjectDefinitions);
    }

    public Map<ObjectDefinition, List<AccessHistory>> runCode(VirtualMachine vm,
            List<ObjectDefinition> pObjectDefinitions) throws ClassNotFoundException {

        Map<ObjectDefinition, List<AccessHistory>> accessHistories =
                new HashMap<ObjectDefinition, List<AccessHistory>>();

        // This is the thread that will step through the code
        MemberAccessTrackerThread memberAccessTrackerThread = new MemberAccessTrackerThread(
                vm, pObjectDefinitions, accessHistories);
        memberAccessTrackerThread.start();

        // Shutdown begins when event thread terminates
        try {
            memberAccessTrackerThread.join();
        } catch (InterruptedException interruptedException) {
            // XXX: I honestly don't know when this would come up.
        }

        String vmStdout = streamToString(vm.process().getInputStream());
        String vmStderr = streamToString(vm.process().getErrorStream());
        System.out.println("Stdout: " + vmStdout);
        System.out.println("Stderr: " + vmStderr);

        if (vmStderr.contains("Error: Could not find or load main class")) {
            throw new ClassNotFoundException("Could not find or load main class");
        }

        return accessHistories;

    }

    private String streamToString(InputStream inputStream) {

        // REUSE: This trick comes from Stack Overflow post
        // http://stackoverflow.com/questions/309424/read-convert-an-inputstream-to-a-string   
        Scanner scanner = new Scanner(inputStream).useDelimiter("\\A");
        return (scanner.hasNext() ? scanner.next() : "");

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
