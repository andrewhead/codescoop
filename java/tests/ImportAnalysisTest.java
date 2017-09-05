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

    // This is an obscure case, though in a previous version of ImportAnalysis, it couldn't
    // find an `SSLSocket` class that is provided by `javax.net.ssl`.  The problem is
    // fixed, and we make sure we don't revert it with this test.
    public void testFindSSLSocketInJavaxPackage() {
        ImportAnalysis importAnalysis = new ImportAnalysis();
        Set<String> classNames = importAnalysis.getClassNames("javax.net.ssl.*");
        assertTrue(classNames.contains("javax.net.ssl.SSLSocket"));
    }

}
