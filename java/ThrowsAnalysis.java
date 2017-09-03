import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;

import java.lang.reflect.Method;
import java.lang.reflect.Constructor;
import java.lang.reflect.Type;

import soot.Body;
import soot.BodyTransformer;
import soot.G;
import soot.Local;
import soot.Main;
import soot.PackManager;
import soot.Scene;
import soot.Transform;
import soot.Unit;
import soot.Value;
import soot.ValueBox;

import soot.jimple.InvokeExpr;
import soot.jimple.InstanceInvokeExpr;
import soot.jimple.Stmt;

import soot.options.Options;

import soot.tagkit.SourceLnPosTag;
import soot.tagkit.Tag;

import soot.toolkits.graph.UnitGraph;
import soot.toolkits.graph.CompleteUnitGraph;
import soot.toolkits.scalar.UnitValueBoxPair;
import soot.toolkits.scalar.SimpleLocalUses;
import soot.toolkits.scalar.SimpleLocalDefs;
import soot.toolkits.scalar.LocalDefs;
import soot.toolkits.scalar.LocalUses;


/**
 * Lifetime of this class:
 * * Initialize with a classpath
 * * Run analysis on an example
 * * Then, query for the results of analysis
 */
public class ThrowsAnalysis {

    private String mClasspath;
    private Map<Range, List<List<String>>> mThrowableExceptions;

    /**
     * @param pClasspath Additional classpath beyond the default
     *     classpath to look for Soot JARs and the file to analyze.
     */
    public ThrowsAnalysis(String pClasspath) {

        // Set up the path, including user-provided additions
        String classpath = Scene.v().defaultClassPath();
        if (pClasspath == null) {
            classpath += ":.";
        } else {
            classpath += (":" + pClasspath);
        }
        this.mClasspath = classpath;

        // Initialize intermediate data structures for saving definitions and uses
        this.mThrowableExceptions = new HashMap<Range, List<List<String>>>();

    }

    public ThrowsAnalysis() {
        this(null);
    }

    public String getClasspath() {
        return this.mClasspath;
    }

    public Map<Range, List<List<String>>> getThrowableExceptions() {
        return this.mThrowableExceptions;
    }

    private Range getRangeForStatement(Stmt s) {
        SourceLnPosTag positionTag = null;
        for (Tag tag: s.getTags()) {
            if (tag instanceof SourceLnPosTag) {
                positionTag = (SourceLnPosTag) tag;
                break;
            }
        }
        if (positionTag != null) {
            return new Range(
                positionTag.startLn(),
                positionTag.startPos(),
                positionTag.endLn(),
                positionTag.endPos()
            );
        }
        return null;
    }

    private void saveExceptionForRange(Map<Range, List<List<String>>> exceptions, Range range,
            Class<?> exceptionType) {
        if (!exceptions.containsKey(range)) {
            exceptions.put(range, new ArrayList<List<String>>());
        }
        // Add a link between this range, the exception it throws, and all of the superclasses
        // of that exception.
        List<String> exceptionHierarchy = new ArrayList<String>();
        Class<?> superType = exceptionType;
        while (!superType.getName().equals("java.lang.Throwable")) {
            exceptionHierarchy.add(superType.getName());
            superType = superType.getSuperclass();
        }
        exceptions.get(range).add(exceptionHierarchy);
    }

    public void analyze(String javaSourceFile) {

        // It's important to do these two steps at the beginning of this method,
        // every time analyze is called, because at the end of the last run,
        // the Soot environment has been reset (`G.reset()`)
        Options.v().set_soot_classpath(this.mClasspath);
        PackManager.v().getPack("jtp").add(new Transform("jtp.myTransform", analyzer));

        // Arguments for configuring Soot to provide useful IR
        String[] args = new String[] {
            // Run analysis on a Java source code file with this name
            javaSourceFile,
            "-src-prec", "java",
            // Keep line numbers of def's of variables
            "-keep-line-number",
            // The "polyglot" flag lets us get line numbers of uses.
            // Though it also changes the way that locals are labeled with positions.
            // Redefinitions include the full line; initial definitions include only
            // the name of the variable (this is the reverse of the behavior when
            // polyglot is not enabled).  Character positions are 0-indexed,
            // and the end position is for the character after the last character in the substring.
            "-polyglot",
            // Keep variable names when possible
            "-p", "jb", "use-original-names:true",
            "-p", "jb.lp", "enabled:false",
            // Create readable Jimple intermediate representation
            // "-f", "j"
            // Don't create any output
            "-f", "none"
        };

        soot.Main.main(args);

        // This `reset` lets us run the analyze method again.
        // To my knowledge, it also clobbers all of the environmental setup.
        G.reset();

    }

    private BodyTransformer analyzer = new BodyTransformer() {

        @SuppressWarnings("rawtypes")
        protected void internalTransform(Body body, String phase, Map options) {

            // For every statement in the program...
            for (Unit unit: body.getUnits()) {
                Stmt s = (Stmt) unit;

                // Check to see if it contains a method invocation.
                if (s.containsInvokeExpr()) {
                    InvokeExpr invokeExpr = s.getInvokeExpr();

                    String methodName = invokeExpr.getMethod().getName();
                    String className = invokeExpr.getMethod().getDeclaringClass().getType().toString();

                    // Load up the class so we can inspect its method.
                    Class<?> klazz;
                    try {
                        klazz = Class.forName(className);
                    } catch (ClassNotFoundException e) {
                        continue;
                    }

                    // Look up the methods sharing the name of the invoked method.
                    // XXX: This doesn't bother checking parameter lists for matches, meaning
                    // that there may be some false positives and missed exceptions!

                    // Get the types of each of the arguments of the invocation
                    List<String> expectedArgTypes = new ArrayList<String>();
                    for (Value arg: invokeExpr.getArgs()) {
                        expectedArgTypes.add(arg.getType().toString());
                    }

                    if (methodName.equals("<init>")) {
                        if (klazz.getConstructors().length > 0) {
                            for (Constructor<?> constructor: klazz.getConstructors()) {
                                List<String> actualArgTypes = new ArrayList<String>();
                                for (Class<?> type: constructor.getParameterTypes()) {
                                    actualArgTypes.add(type.getName());
                                }
                                if (actualArgTypes.equals(expectedArgTypes)) {
                                    for (Class exceptionType:constructor.getExceptionTypes()) {
                                        saveExceptionForRange(mThrowableExceptions,
                                            getRangeForStatement(s), exceptionType);
                                    }
                                }
                            }
                        }
                    } else {
                        // Get the first method with a matching signature (name and parameters)
                        Method relevantMethod = null;
                        for (Method method:klazz.getDeclaredMethods()) {
                            if (method.getName().equals(methodName)) {
                                List<String> actualArgTypes = new ArrayList<String>();
                                for (Class<?> type: method.getParameterTypes()) {
                                    actualArgTypes.add(type.getName());
                                }
                                if (actualArgTypes.equals(expectedArgTypes)) {
                                    relevantMethod = method;
                                    break;
                                }
                            }
                        }
                        if (relevantMethod != null) {
                            Class<?>[] exceptionTypes = relevantMethod.getExceptionTypes();
                            for (Class exceptionType:exceptionTypes) {
                                saveExceptionForRange(mThrowableExceptions,
                                    getRangeForStatement(s), exceptionType);
                            }
                        }
                    }
                }
            }

        }
    };

    public static void main(String[] args) {

        ThrowsAnalysis analysis = new ThrowsAnalysis(args[0]);
        analysis.analyze(args[1]);

        System.out.println("");

    }

}
