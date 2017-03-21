import junit.framework.TestCase;

import java.util.Set;


public class ImportAnalysisTest extends TestCase {

    public void testGetNameOfClassImportedBySingleImport() {
        ImportAnalysis importAnalysis = new ImportAnalysis();
        Set<String> classNames = importAnalysis.getClassNames("java.util.ArrayList");
        assertEquals(1, classNames.size());
        assertTrue(classNames.contains("java.util.ArrayList"));
    }

    public void testGetNamesOfClassesImportedFromPathWildcard() {
        ImportAnalysis importAnalysis = new ImportAnalysis();
        Set<String> classNames = importAnalysis.getClassNames("java.util.*");
        assertTrue(classNames.contains("java.util.ArrayList"));
        assertTrue(classNames.contains("java.util.HashSet"));
    }

}
