import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;

import soot.Body;
import soot.BodyTransformer;
import soot.Main;
import soot.PackManager;
import soot.Scene;
import soot.Transform;
import soot.Unit;
import soot.ValueBox;
import soot.Local;

import soot.options.Options;

import soot.tagkit.SourceLnNamePosTag;
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
public class DataflowAnalysis {

    private String mClasspath;
    private Set<SymbolAppearance> mDefinitions;
    private Set<SymbolAppearance> mUses;

    /**
     * @param pClasspath Additional classpath beyond the default
     *     classpath to look for Soot JARs and the file to analyze.
     */
    public DataflowAnalysis(String pClasspath) {
        String classpath = Scene.v().defaultClassPath();
        if (pClasspath == null) {
            classpath += ":.";
        } else {
            classpath += (":" + pClasspath);
        }
        this.mClasspath = classpath;
        Options.v().set_soot_classpath(this.mClasspath);
    }

    public String getClasspath() {
        return this.mClasspath;
    }

    public Set<SymbolAppearance> getDefinitions() {
        return this.mDefinitions;
    }

    public SymbolAppearance getLatestDefinitionBeforeUse(SymbolAppearance use) {

        Map<String, Set<SymbolAppearance>> definitionsByName = this.getDefinitionsBySymbolName();
        Set<SymbolAppearance> definitions = definitionsByName.get(use.getSymbolName());
        SymbolAppearance latestDefinition = null;

        // The latest definition is the one that occurs at the highest line index
        // and also before the symbol's use
        if (definitions != null) {
            for (SymbolAppearance definition: definitions) {
                if (definition.getLineNumber() < use.getLineNumber() && (
                        latestDefinition == null ||
                        definition.getLineNumber() > latestDefinition.getLineNumber())) {
                    latestDefinition = definition;
                }
            }
        }

        return latestDefinition;
    }

    public Set<SymbolAppearance> getUndefinedUsesInLines(List<Integer> lines) {

        Map<String, Set<SymbolAppearance>> definitionsByName = this.getDefinitionsBySymbolName();
        Map<Integer, Set<SymbolAppearance>> usesByLine = this.getUsesByLine();
        Set<SymbolAppearance> undefinedUses = new HashSet<SymbolAppearance>();

        // Look at all uses on all lines
        for (int line: lines) {
            Set<SymbolAppearance> usesOnLine = usesByLine.get(line);
            if (usesOnLine != null) {
                for (SymbolAppearance use: usesOnLine) {

                    // For each use, check if the symbol is defined on a line that is
                    // 1. within the set of included lines
                    // 2. before the line on which the symbol is used
                    boolean useDefined = false;
                    Set<SymbolAppearance> definitions = definitionsByName.get(use.getSymbolName());
                    if (definitions != null) {
                        for (SymbolAppearance definition: definitions) {
                            if (lines.contains(definition.getLineNumber()) &&
                                    definition.getLineNumber() < line) {
                                useDefined = true;
                                break;
                            }
                        }
                    }

                    if (!useDefined) {
                        undefinedUses.add(use);
                    }

                }
            }
        }

        return undefinedUses;

    }

    public Set<String> getSymbolsDefinedInLines(List<Integer> lines) {

        Map<Integer, Set<SymbolAppearance>> definitionsByLine = this.getDefinitionsByLine();

        Set<String> symbolNames = new HashSet<String>();
        for (int line: lines) {
            Set<SymbolAppearance> symbolsDefinedOnLine = definitionsByLine.get(line);
            if (symbolsDefinedOnLine != null) {
                for (SymbolAppearance symbol: symbolsDefinedOnLine) {
                    symbolNames.add(symbol.getSymbolName());
                }
            }
        }

        return symbolNames;

    }

    public Set<SymbolAppearance> getUses() {
        return this.mUses;
    }

    public Map<String, Set<SymbolAppearance>> getDefinitionsBySymbolName() {

        Set<SymbolAppearance> definitions = this.getDefinitions();

        HashMap<String, Set<SymbolAppearance>> symbolNamesToDefinitions = (
            new HashMap<String, Set<SymbolAppearance>>());

        for (SymbolAppearance definition: definitions) {
            String symbolName = definition.getSymbolName();
            Set<SymbolAppearance> symbolDefinitions = symbolNamesToDefinitions.get(symbolName);
            if (symbolDefinitions == null) {
                symbolDefinitions = new HashSet<SymbolAppearance>();
                symbolNamesToDefinitions.put(symbolName, symbolDefinitions);
            }
            symbolDefinitions.add(definition);
        }

        return symbolNamesToDefinitions;

    }

    public Map<Integer, Set<SymbolAppearance>> getUsesByLine() {
        
        Set<SymbolAppearance> uses = this.getUses();

        HashMap<Integer, Set<SymbolAppearance>> linesToUses = (
            new HashMap<Integer, Set<SymbolAppearance>>());

        for (SymbolAppearance use: uses) {
            int lineNumber = use.getLineNumber();
            Set<SymbolAppearance> lineUses = linesToUses.get(lineNumber);
            if (lineUses == null) {
                lineUses = new HashSet<SymbolAppearance>();
                linesToUses.put(lineNumber, lineUses);
            }
            lineUses.add(use);
        }

        return linesToUses;

    }

    public Map<Integer, Set<SymbolAppearance>> getDefinitionsByLine() {
        
        Set<SymbolAppearance> definitions = this.getDefinitions();

        HashMap<Integer, Set<SymbolAppearance>> linesToDefinitions = (
            new HashMap<Integer, Set<SymbolAppearance>>());

        for (SymbolAppearance definition: definitions) {
            int lineNumber = definition.getLineNumber();
            Set<SymbolAppearance> lineDefinitions = linesToDefinitions.get(lineNumber);
            if (lineDefinitions == null) {
                lineDefinitions = new HashSet<SymbolAppearance>();
                linesToDefinitions.put(lineNumber, lineDefinitions);
            }
            lineDefinitions.add(definition);
        }

        return linesToDefinitions;

    }

    private SourceLnNamePosTag getSourceLnNamePosTag(List<Tag> tags) {
        SourceLnNamePosTag positionTag = null;
        for (Tag tag: tags) {
            if (tag instanceof SourceLnNamePosTag) {
                positionTag = (SourceLnNamePosTag) tag;
                break;
            }
        }
        return positionTag;
    }

    public void analyze(String javaSourceFile) {

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

        this.mDefinitions = new HashSet<SymbolAppearance>();
        this.mUses = new HashSet<SymbolAppearance>();

        final Set<SymbolAppearance> definitions = this.mDefinitions;
        final Set<SymbolAppearance> uses = this.mUses;

        PackManager.v().getPack("jtp").add(
            new Transform("jtp.myTransform", new BodyTransformer() {
                protected void internalTransform(Body body, String phase, Map options) {

                    UnitGraph graph = new CompleteUnitGraph(body);

                    // Save all local definition.  Visit every unit looking for
                    // a definition of eachl local.  If one was found, and that symbol
                    // corresponds to something in the original source, save a record
                    // of the definition of that symbol.
                    LocalDefs defs = new SimpleLocalDefs(graph);

                    for (Local local: body.getLocals()) {

                        for (Unit unit: body.getUnits()) {
                            try {
                                List<Unit> defUnits = defs.getDefsOfAt(local, unit);
                                for (Unit defUnit: defUnits) {
                                        SourceLnNamePosTag positionTag = (
                                            getSourceLnNamePosTag(defUnit.getTags()));
                                        if (positionTag != null) {
                                        SymbolAppearance definition = new SymbolAppearance(
                                            local.getName(),
                                            positionTag.startLn(),
                                            positionTag.startPos(),
                                            positionTag.endPos()
                                        );
                                        definitions.add(definition);
                                    }

                                }
                            } catch (RuntimeException runtimeException) {
                                // A RuntimeException is thrown when no definition found in a unit.
                                // This is expected to happen many times.  Just ignore it.
                            }
                        }
                    }

                    // To find the uses of each variable, we're going to iterate through the uses
                    // for all of the units and just save every local that was used.
                    LocalUses localUses = new SimpleLocalUses(graph, defs);

                    for (Unit unit: body.getUnits()) {

                        List usesAtUnit = localUses.getUsesOf(unit);
                        @SuppressWarnings("unchecked")
                        List<UnitValueBoxPair> unitValueBoxPairs = (List<UnitValueBoxPair>) usesAtUnit;

                        for (UnitValueBoxPair unitValueBoxPair: unitValueBoxPairs) {

                            Unit localUnit = unitValueBoxPair.getUnit();
                            ValueBox localValueBox = unitValueBoxPair.getValueBox();

                            SourceLnNamePosTag positionTag = (
                                getSourceLnNamePosTag(localValueBox.getTags()));
                            if (positionTag != null) {
                                SymbolAppearance use = new SymbolAppearance(
                                    localValueBox.getValue().toString(),
                                    positionTag.startLn(),
                                    positionTag.startPos(),
                                    positionTag.endPos()
                                );
                                uses.add(use);
                            }

                        }
                    }
                }
            }
        ));

        soot.Main.main(args);

    }

    public static void main(String[] args) {
        DataflowAnalysis analysis = new DataflowAnalysis("tests/");
        analysis.analyze("Example");
    }

}
