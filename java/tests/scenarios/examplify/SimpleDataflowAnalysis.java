import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;

import soot.Body;
import soot.BodyTransformer;
import soot.G;
import soot.Local;
import soot.Main;
import soot.PackManager;
import soot.Scene;
import soot.Transform;
import soot.Type;
import soot.Unit;
import soot.Value;
import soot.ValueBox;

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
public class SimpleDataflowAnalysis {

    private String mClasspath;
    private Set mDefinitions;
    private Set mUses;

    /**
     * @param pClasspath Additional classpath beyond the default
     *     classpath to look for Soot JARs and the file to analyze.
     */
    public SimpleDataflowAnalysis(String pClasspath) {

        // Set up the path, including user-provided additions
        String classpath = Scene.v().defaultClassPath();
        if (pClasspath == null) {
            classpath += ":.";
        } else {
            classpath += (":" + pClasspath);
        }
        this.mClasspath = classpath;

        // Initialize intermediate data structures for saving definitions and uses
        this.mDefinitions = new HashSet();
        this.mUses = new HashSet();

    }

    public SimpleDataflowAnalysis() {
        this(null);
    }

    public String getClasspath() {
        return this.mClasspath;
    }

    public Set getDefinitions() {
        return this.mDefinitions;
    }

    public SymbolAppearance getLatestDefinitionBeforeUse(SymbolAppearance use) {

        Map definitionsByName = this.getDefinitionsBySymbolName();
        Set definitions = (Set) definitionsByName.get(use.getSymbolName());
        SymbolAppearance latestDefinition = null;

        // The latest definition is the one that occurs at the highest line index
        // and also before the symbol's use
        if (definitions != null) {
            for (Iterator definitionIt = definitions.iterator(); definitionIt.hasNext();) {
                SymbolAppearance definition = (SymbolAppearance) definitionIt.next();
                if (definition.getStartLine() < use.getStartLine() && (latestDefinition == null || definition.getStartLine() > latestDefinition.getStartLine())) {
                    latestDefinition = definition;
                }
            }
        }

        return latestDefinition;
    }

    public Set getUndefinedUsesInLines(List lines) {

        Map definitionsByName = this.getDefinitionsBySymbolName();
        Map usesByLine = this.getUsesByLine();
        Set undefinedUses = new HashSet();

        // Look at all uses on all lines
        for (int i = 0; i < lines.size(); i++) {
            Integer line = (Integer) lines.get(i);
            Set usesOnLine = (Set) usesByLine.get(line);
            if (usesOnLine != null) {
                for (Iterator useIt = usesOnLine.iterator(); useIt.hasNext();) {
                    SymbolAppearance use = (SymbolAppearance) useIt.next();

                    // For each use, check if the symbol is defined on a line that is
                    // 1. within the set of included lines
                    // 2. before the line on which the symbol is used
                    boolean useDefined = false;
                    Set definitions = (Set) definitionsByName.get(use.getSymbolName());
                    if (definitions != null) {
                        for (Iterator definitionIt = definitions.iterator(); definitionIt.hasNext();) {
                            SymbolAppearance definition = (SymbolAppearance) definitionIt.next();
                            if (lines.contains(Integer.valueOf(definition.getStartLine())) && definition.getStartLine() < line.intValue()) {
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

    public Set getSymbolsDefinedInLines(List lines) {

        Map definitionsByLine = this.getDefinitionsByLine();

        Set symbolNames = new HashSet();
        for (int i = 0; i < lines.size(); i++) {
            Integer line = (Integer) lines.get(i);
            Set symbolsDefinedOnLine = (Set) definitionsByLine.get(line);
            if (symbolsDefinedOnLine != null) {
                for (Iterator symbolIt = symbolsDefinedOnLine.iterator(); symbolIt.hasNext();) {
                    SymbolAppearance symbol = (SymbolAppearance) symbolIt.next();
                    symbolNames.add(symbol.getSymbolName());
                }
            }
        }

        return symbolNames;

    }

    public Set getUses() {
        return this.mUses;
    }

    public Map getDefinitionsBySymbolName() {

        Set definitions = this.getDefinitions();

        HashMap symbolNamesToDefinitions = new HashMap();

        for (Iterator definitionIt = definitions.iterator(); definitionIt.hasNext();) {
            SymbolAppearance definition = (SymbolAppearance) definitionIt.next();
            String symbolName = definition.getSymbolName();
            Set symbolDefinitions = (Set) symbolNamesToDefinitions.get(symbolName);
            if (symbolDefinitions == null) {
                symbolDefinitions = new HashSet();
                symbolNamesToDefinitions.put(symbolName, symbolDefinitions);
            }
            symbolDefinitions.add(definition);
        }

        return symbolNamesToDefinitions;

    }

    public Map getUsesByLine() {

        Set uses = this.getUses();

        HashMap linesToUses = new HashMap();

        for (Iterator usesIt = uses.iterator(); usesIt.hasNext();) {
            SymbolAppearance use = (SymbolAppearance) usesIt.next();
            Integer startLine = Integer.valueOf(use.getStartLine());
            Set lineUses = (Set) linesToUses.get(startLine);
            if (lineUses == null) {
                lineUses = new HashSet();
                linesToUses.put(startLine, lineUses);
            }
            lineUses.add(use);
        }

        return linesToUses;

    }

    public Map getDefinitionsByLine() {

        Set definitions = this.getDefinitions();

        HashMap linesToDefinitions = new HashMap();

        for (Iterator definitionIt = definitions.iterator(); definitionIt.hasNext();) {
            SymbolAppearance definition = (SymbolAppearance) definitionIt.next();
            Integer startLine = Integer.valueOf(definition.getStartLine());
            Set lineDefinitions = (Set) linesToDefinitions.get(startLine);
            if (lineDefinitions == null) {
                lineDefinitions = new HashSet();
                linesToDefinitions.put(startLine, lineDefinitions);
            }
            lineDefinitions.add(definition);
        }

        return linesToDefinitions;

    }

    private SourceLnPosTag getSourceLnPosTag(List tags) {
        SourceLnPosTag positionTag = null;
        for (int i = 0; i < tags.size(); i++) {
            Tag tag = (Tag) tags.get(i);
            if (tag instanceof SourceLnPosTag) {
                positionTag = (SourceLnPosTag) tag;
                break;
            }
        }
        return positionTag;
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

        // Reset the definitions and uses
        SimpleDataflowAnalysis.this.mDefinitions = new HashSet();
        SimpleDataflowAnalysis.this.mUses = new HashSet();

        // Run the analysis!
        soot.Main.main(args);

        // This `reset` lets us run the analyze method again.
        // To my knowledge, it also clobbers all of the environmental setup.
        G.reset();

    }

    /**
     * For some crazy reason, this is run twice whenever soot.Main.main is invoked.
     * And the second time through, it looks like the iterators are exhausted,
     * or the body is empty.  Because of this, I don't reset the definitions and uses
     * inside of the analyzer but outside of it, to make sure that the data is saved
     * from the first round, and not clobbered by a no-op second pass.
     */
    private BodyTransformer analyzer = new BodyTransformer() {

        // @SuppressWarnings("rawtypes")
        protected void internalTransform(Body body, String phase, Map options) {

            Set definitions = SimpleDataflowAnalysis.this.mDefinitions;
            Set uses = SimpleDataflowAnalysis.this.mUses;

            // Make a control flow graph through the program
            UnitGraph graph = new CompleteUnitGraph(body);

            // Visit every unit looking for a definition of each local.
            // If one was found, and that symbol corresponds to something
            // in the original source, save a record of the definition of that symbol.
            LocalDefs defs = new SimpleLocalDefs(graph);

            for (Iterator localsIt = body.getLocals().iterator(); localsIt.hasNext();) {
              Local local = (Local) localsIt.next();

                for (Iterator unitIt = body.getUnits().iterator(); unitIt.hasNext();) {
                  Unit unit = (Unit) unitIt.next();

                    for (Iterator defBoxIt = unit.getDefBoxes().iterator(); defBoxIt.hasNext();) {
                      ValueBox defBox = (ValueBox) defBoxIt.next();

                        // Get the local corresponding to the def
                        Value defValue = defBox.getValue();
                        if (!(defValue instanceof Local)) continue;
                        Local defLocal = (Local) defValue;

                        if (local == defLocal) {
                            SourceLnPosTag positionTag = getSourceLnPosTag(defBox.getTags());
                            if (positionTag != null) {
                                SymbolAppearance definition = new SymbolAppearance(local.getName(), local.getType(), positionTag.startLn(), positionTag.startPos(), positionTag.endLn(), positionTag.endPos());
                                definitions.add(definition);
                            }
                        }
                    }
                }
            }

            // To find the uses of each variable, we're going to iterate through the uses
            // for all of the units and just save every local that was used.
            LocalUses localUses = new SimpleLocalUses(graph, defs);

            for (Iterator unitIt = body.getUnits().iterator(); unitIt.hasNext();) {
              Unit unit = (Unit) unitIt.next();

                List usesAtUnit = localUses.getUsesOf(unit);
                List unitValueBoxPairs = (List) usesAtUnit;

                for (Iterator unitValueBoxIt = unitValueBoxPairs.iterator(); unitValueBoxIt.hasNext();) {
                  UnitValueBoxPair unitValueBoxPair = (UnitValueBoxPair) unitValueBoxIt.next();

                    Unit localUnit = unitValueBoxPair.getUnit();
                    ValueBox localValueBox = unitValueBoxPair.getValueBox();

                    SourceLnPosTag positionTag = (
                        getSourceLnPosTag(localValueBox.getTags()));
                    if (positionTag != null) {
                        SymbolAppearance use = new SymbolAppearance(localValueBox.getValue().toString(), localValueBox.getValue().getType(), positionTag.startLn(), positionTag.startPos(), positionTag.endLn(), positionTag.endPos());
                        uses.add(use);
                    }

                }
            }

            SimpleDataflowAnalysis.this.mDefinitions = definitions;
            SimpleDataflowAnalysis.this.mUses = uses;

        }
    };

    public static void main(String[] args) {

        SimpleDataflowAnalysis analysis = new SimpleDataflowAnalysis("tests/analysis_examples");
        analysis.analyze("Example");

        System.out.println("");
        System.out.println("====");
        System.out.println("Defs");
        System.out.println("====");
        for (Iterator defIt = analysis.getDefinitions().iterator(); defIt.hasNext();) {
            SymbolAppearance def = (SymbolAppearance) defIt.next();
            System.out.println(def);
        }

        System.out.println("");
        System.out.println("====");
        System.out.println("Uses");
        System.out.println("====");
        for (Iterator useIt = analysis.getUses().iterator(); useIt.hasNext();) {
            SymbolAppearance use = (SymbolAppearance) useIt.next();
            System.out.println(use);
        }

        System.out.println("");

    }

    private class SymbolAppearance {

        private final String mSymbolName;
        private final Type mType;
        private final int mStartLine;
        private final int mStartColumn;
        private final int mEndLine;
        private final int mEndColumn;

        public SymbolAppearance(String pSymbolName, Type pType, int pStartLine, int pStartColumn,
                int pEndLine, int pEndColumn) {
            this.mSymbolName = pSymbolName;
            this.mType = pType;
            this.mStartLine = pStartLine;
            this.mStartColumn = pStartColumn;
            this.mEndLine = pEndLine;
            this.mEndColumn = pEndColumn;
        }

        public String getSymbolName() {
            return this.mSymbolName;
        }

        public Type getType() {
            return this.mType;
        }

        public int getStartLine() {
            return this.mStartLine;
        }

        public int getStartColumn() {
            return this.mStartColumn;
        }

        public int getEndLine() {
            return this.mEndLine;
        }

        public int getEndColumn() {
            return this.mEndColumn;
        }

        public String toString() {
            return ("(" + this.getSymbolName() + " (" + this.getType() + "): " +
                    "[L" + this.getStartLine() + "C" + this.getStartColumn() + ", " +
                    "L" + this.getEndLine() + "C" + this.getEndColumn() + "])");
        }

        public boolean equals(Object other) {
            if (!(other instanceof SymbolAppearance)) {
                return false;
            }
            SymbolAppearance otherAppearance = (SymbolAppearance) other;
            return (
                otherAppearance.getSymbolName() == this.getSymbolName() &&
                // Symbols might be compared to other symbols that weren't created
                // in the same Soot runtime.  In that case, they won't share the same
                // singleton object, but they will share the same hash code.
                otherAppearance.getType().hashCode() == this.getType().hashCode() &&
                otherAppearance.getStartLine() == this.getStartLine() &&
                otherAppearance.getStartColumn() == this.getStartColumn() &&
                otherAppearance.getEndLine() == this.getEndLine() &&
                otherAppearance.getEndColumn() == this.getEndColumn()
            );
        }

        public int hashCode() {
            return (
                this.mSymbolName.hashCode() *
                this.mType.hashCode() *
                this.mStartLine *
                this.mStartColumn *
                this.mEndLine *
                this.mEndColumn
            );
        }

    }

}
