import junit.framework.TestCase;
import org.junit.Before;
import org.junit.Test;

import java.util.List;
import java.util.Set;
import java.util.Map;


public class ThrowsAnalysisTest extends TestCase {

    private static ThrowsAnalysis throwsAnalysis;
    private static boolean setUpComplete = false;

    @Before
    public void setUp() {
        if (!setUpComplete) {
            throwsAnalysis = new ThrowsAnalysis("tests/analysis_examples");
            throwsAnalysis.analyze("Throws");
            setUpComplete = true;
        }
    }
    
    @Test
    public void testGetThrownExceptionForLine() {
        Map<Range, List<List<String>>> exceptions = throwsAnalysis.getThrowableExceptions();
        assertEquals(exceptions.get(new Range(24, 8, 24, 31)).get(0).get(0), "java.io.IOException");
    }

    @Test
    public void testAnalysisReturnsAllSuperclassesForExceptions() {
        Map<Range, List<List<String>>> exceptions = throwsAnalysis.getThrowableExceptions();
        List<List<String>> rangeExceptions = exceptions.get(new Range(24, 8, 24, 31));
        assertEquals(rangeExceptions.size(), 1);
        assertEquals(rangeExceptions.get(0).size(), 2);
        assertEquals(rangeExceptions.get(0).get(0), "java.io.IOException");
        assertEquals(rangeExceptions.get(0).get(1), "java.lang.Exception");
    }

    @Test
    public void testAnalysisReturnsExceptionHierarchiesForMultipleThrows() {
        Map<Range, List<List<String>>> exceptions = throwsAnalysis.getThrowableExceptions();
        List<List<String>> rangeExceptions = exceptions.get(new Range(27, 8, 27, 31));
        assertEquals(rangeExceptions.size(), 2);
        assertEquals(rangeExceptions.get(0).get(0), "Throws$CustomException1");
        assertEquals(rangeExceptions.get(1).get(0), "Throws$CustomException2");
    }

    @Test
    public void testFindFunctionWithRightSignature() {
        Map<Range, List<List<String>>> exceptions = throwsAnalysis.getThrowableExceptions();
        assertEquals(exceptions.get(new Range(28, 8, 28, 29)).get(0).get(0), "Throws$CustomException1");
        assertEquals(exceptions.get(new Range(29, 8, 29, 30)).get(0).get(0), "Throws$CustomException2");
    }

    @Test
    public void testDisambiguatesBetweenSignatures() {
        Map<Range, List<List<String>>> exceptions = throwsAnalysis.getThrowableExceptions();
        assertEquals(exceptions.get(new Range(30, 27, 30, 47)).get(0).get(0), "Throws$CustomException1");
        assertEquals(exceptions.get(new Range(31, 27, 31, 48)).get(0).get(0), "Throws$CustomException2");
    }

    @Test
    public void testFindsMethodsOnSuperclass() {
        Map<Range, List<List<String>>> exceptions = throwsAnalysis.getThrowableExceptions();
        assertEquals(exceptions.get(new Range(33, 8, 33, 32)).get(0).get(0), "Throws$CustomException1");
    }
}
