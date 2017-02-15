import static org.junit.Assert.assertEquals;
import org.junit.Test;


public class DataflowAnalysisTest {

    @Test
    public void testDataflowAnalysis() {
        DataflowAnalysis dataflowAnalysis = new DataflowAnalysis("tests/");
        String result = dataflowAnalysis.analyze("Example");
        assertEquals(result, "Hi");
    }

}
