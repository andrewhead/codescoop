import java.util.Iterator;
import java.util.List;
import java.util.Map;

import soot.Body;
import soot.BodyTransformer;
import soot.Main;
import soot.PackManager;
import soot.Scene;
import soot.Transform;
import soot.Unit;
import soot.ValueBox;
import soot.Local;
import soot.toolkits.graph.UnitGraph;
import soot.toolkits.graph.CompleteUnitGraph;
import soot.toolkits.scalar.UnitValueBoxPair;
import soot.toolkits.scalar.SimpleLocalUses;
import soot.toolkits.scalar.SimpleLocalDefs;
import soot.toolkits.scalar.LocalDefs;
import soot.toolkits.scalar.LocalUses;
import soot.options.Options;

public class DataflowAnalysis {

    private String mClasspath;

    /**
     * @param pClasspath Additional classpath beyond the default
     *     classpath to look for Soot JARs and the file to analyze.
     */
    public DataflowAnalysis(String pClasspath) {
        String classpath = Scene.v().defaultClassPath();
        if (pClasspath == null) {
            classpath += ":.";
        } else {
            classpath += (":" + classpath);
        }
        Options.v().set_soot_classpath(classpath);
    }

    public String analyze(String javaSourceFile) {

        String[] args = new String[] {
            // Run analysis on a Java source code file with this name
            javaSourceFile,
            "-src-prec", "java",
            // Keep line numbers of def's of variables
            "--keep-line-number",
            // Keep variable names when possible
            "-p", "jb", "use-original-names:true",
            "-p", "jb.lp", "enabled:false",
            // Create readable Jimple intermediate representation
            // "-f", "j"
            // Don't create any output
            "-f", "none"
        };

        PackManager.v().getPack("jtp").add(
            new Transform("jtp.myTransform", new BodyTransformer() {
                protected void internalTransform(Body body, String phase, Map options) {

                    UnitGraph graph = new CompleteUnitGraph(body);
                    LocalDefs defs = new SimpleLocalDefs(graph);
                    LocalUses localUses = new SimpleLocalUses(graph, defs);

                    for (Local local: body.getLocals()) {
                        System.out.println("Local:" + local);
                        // List<Unit> defUnits = defs.getDefsOf(local);
                        // for (Unit defUnit: defUnits) {
                        //    System.out.println("Def'd at:" + defUnit.getTags());
                        // }
                    }

                    for (Unit unit: body.getUnits()) {
                        System.out.println("Unit: " + unit.getTags());
                        for (ValueBox use: unit.getUseBoxes()) {
                            System.out.println("Uses:" + use.getValue());
                        }
                    }
                }
            }
        ));

        soot.Main.main(args);

        return "Hi";

    }

    public static void main(String[] args) {
        DataflowAnalysis analysis = new DataflowAnalysis("tests/");
        System.out.println(analysis.analyze("Example"));
    }

}
