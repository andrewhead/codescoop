import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;
import org.junit.Test;
import org.junit.Before;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.Map;


public class DataflowAnalysisTest {

    private static DataflowAnalysis dataflowAnalysis;
    private static boolean setUpComplete = false;

    @Before
    public void setUp() {
        if (!setUpComplete) {
            dataflowAnalysis = new DataflowAnalysis("tests/");
            dataflowAnalysis.analyze("Example");
        }
        setUpComplete = true;
    }

    @Test
    public void testGetDefinitions() {

        Set<SymbolAppearance> defs = dataflowAnalysis.getDefinitions();

        // Check for all of the expected definitions of i and j
        // Note that the way that definitions are reported are:
        // * on the first line that definitions occur, the symbol span
        // * on the next lines that definitions occur, the full line
        SymbolAppearance iDef1 = new SymbolAppearance("i", 5, 8, 9);
        SymbolAppearance jDef1 = new SymbolAppearance("j", 6, 8, 9);
        SymbolAppearance iDef2 = new SymbolAppearance("i", 7, 4, 13);
        assertTrue(defs.contains(iDef1));
        assertTrue(defs.contains(jDef1));
        assertTrue(defs.contains(iDef2));

        // Make sure that all remaining appearances are just temp variables
        // We do this with a copy to make sure we don't clobber the definition
        // results for later tests.
        Set<SymbolAppearance> defsCopy = new HashSet<SymbolAppearance>(defs);
        defsCopy.remove(iDef1);
        defsCopy.remove(jDef1);
        defsCopy.remove(iDef2);
        for (SymbolAppearance otherDef: defsCopy) {
            assertTrue(otherDef.getSymbolName().startsWith("$"));
        }
    }

    private Set<String> excludeTemps(Set<String> symbolNames) {
        Set<String> symbolNamesCopy = new HashSet<String>(symbolNames);
        for (String symbolName: symbolNames) {
            if (symbolName.startsWith("$")) {
                symbolNamesCopy.remove(symbolName);
            }
        }
        return symbolNamesCopy;
    }

    private Set<SymbolAppearance> excludeTempAppearances(Set<SymbolAppearance> symbols) {
        Set<SymbolAppearance> symbolsCopy = new HashSet<SymbolAppearance>(symbols);
        for (SymbolAppearance symbol: symbols) {
            if (symbol.getSymbolName().startsWith("$")) {
                symbolsCopy.remove(symbol);
            }
        }
        return symbolsCopy;
    }

    @Test
    public void testGetUses() {

        Set<SymbolAppearance> uses = dataflowAnalysis.getUses();
        Set<SymbolAppearance> usesWithoutTemps = excludeTempAppearances(uses);

        assertEquals(4, usesWithoutTemps.size());
        assertTrue(usesWithoutTemps.contains(new SymbolAppearance("i", 6, 12, 13)));
        assertTrue(usesWithoutTemps.contains(new SymbolAppearance("j", 7, 8, 9)));
        assertTrue(usesWithoutTemps.contains(new SymbolAppearance("j", 9, 23, 24)));
        assertTrue(usesWithoutTemps.contains(new SymbolAppearance("i", 9, 27, 28)));

    }
    
    @Test
    public void testGetDefinedSymbolsInLines() {

        // Retrieve defined symbols in lines containing definitions
        // This particular call should make sure to capture a def and not a use
        List<Integer> iLine = new ArrayList<Integer>();
        iLine.add(7);
        Set<String> definedSymbols = dataflowAnalysis.getSymbolsDefinedInLines(iLine);
        assertEquals(1, excludeTemps(definedSymbols).size());
        assertTrue(definedSymbols.contains("i"));

        // When queried with lines that contain no definitions, don't return any symbols
        List<Integer> noDefLines = new ArrayList<Integer>();
        noDefLines.add(4);
        noDefLines.add(8);
        definedSymbols = dataflowAnalysis.getSymbolsDefinedInLines(noDefLines);
        assertEquals(0, definedSymbols.size());

    }

    @Test
    public void testGetDefinitionsByName() {

        Map<String, Set<SymbolAppearance>> namesToDefs = (
            dataflowAnalysis.getDefinitionsBySymbolName());

        Set<SymbolAppearance> iDefs = namesToDefs.get("i");
        assertEquals(2, iDefs.size());
        assertTrue(iDefs.contains(new SymbolAppearance("i", 5, 8, 9)));
        assertTrue(iDefs.contains(new SymbolAppearance("i", 7, 4, 13)));

        Set<SymbolAppearance> jDefs = namesToDefs.get("j");
        assertEquals(1, jDefs.size());
        assertTrue(jDefs.contains(new SymbolAppearance("j", 6, 8, 9)));

    }

    @Test
    public void testGetDefinitionsByLine() {

        Map<Integer, Set<SymbolAppearance>> linesToDefs = (
            dataflowAnalysis.getDefinitionsByLine());

        Set<SymbolAppearance> line5Defs = linesToDefs.get(5);
        assertEquals(excludeTempAppearances(line5Defs).size(), 1);
        assertTrue(line5Defs.contains(new SymbolAppearance("i", 5, 8, 9)));

        Set<SymbolAppearance> line6Defs = linesToDefs.get(6);
        assertEquals(excludeTempAppearances(line6Defs).size(), 1);
        assertTrue(line6Defs.contains(new SymbolAppearance("j", 6, 8, 9)));

        Set<SymbolAppearance> line7Defs = linesToDefs.get(7);
        assertEquals(excludeTempAppearances(line7Defs).size(), 1);
        assertTrue(line7Defs.contains(new SymbolAppearance("i", 7, 4, 13)));

        assertNull(linesToDefs.get(8));  // Nothing on line 8

    }

    @Test
    public void testGetDefinitionsOverRange() {}

    @Test
    public void testDataflowAnalysis() {
        /*
        DataflowAnalysis dataflowAnalysis = new DataflowAnalysis("tests/");
        String result = dataflowAnalysis.analyze("Example");
        assertEquals(result, "Hi");
        */
    }

}
