import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertTrue;
import org.junit.Test;

import java.util.List;
import java.util.Map;

import com.sun.jdi.Value;
import com.sun.jdi.IntegerValue;


public class VariableTracerTest {

    @Test
    public void testExceptionWhenClassNotFound() {

        VariableTracer variableTracer = new VariableTracer();
        boolean exceptionThrown = false;

        try {
            variableTracer.run("NonexistentClass", "tests/analysis_examples");
        } catch (ClassNotFoundException exception) {
            exceptionThrown = true;
        }

        assertTrue(exceptionThrown);

    }

    @Test
    // An earlier version of the code could only collect symbol definitions from the main.
    // The current version no longer has this restriction.
    public void testGetValuesOutsideOfMainFunction() throws ClassNotFoundException {
        
        VariableTracer variableTracer = new VariableTracer();

        Map<String, Map<Integer, Map<String, List<Value>>>> values = (
                variableTracer.run("MultiFunction", "tests/analysis_examples"));

        // If this were only looking at the `main` function, it would completely
        // skip all of the variable values on line 5, which does not occur in the main.
        assertNotNull(values.get("MultiFunction.java").get(5));

    }

    @Test
    // An earlier version of this code wouldn't step over lines after an internal class
    // was initialized.  This seemed to be solved by starting to step again after
    // exiting from methods (instead of just entering methods).
    public void testGetValuesAtStartOfLoop() throws ClassNotFoundException {

        VariableTracer variableTracer = new VariableTracer();

        Map<String, Map<Integer, Map<String, List<Value>>>> values = (
                variableTracer.run("InternalClassCaller", "tests/analysis_examples"));

        // Line 14 is the first executable line after the call to an internal class.
        assertNotNull(values.get("InternalClassCaller.java").get(14));

    }

    @Test
    // Yet another earlier version of this code stopped stepping over lines after a
    // call to java.lang.Math.  This is presumably because the class is excluded
    // from reporting events.  The issue is now fixed.
    public void testGetValuesAfterStandardLibraryCall() throws ClassNotFoundException {

        VariableTracer variableTracer = new VariableTracer();

        Map<String, Map<Integer, Map<String, List<Value>>>> values = (
                variableTracer.run("StandardLibraryCaller", "tests/analysis_examples"));

        // Line 9 is the line that comes after a call to the standard library.
        assertNotNull(values.get("StandardLibraryCaller.java").get(9));

    }

    @Test
    public void testGetAllValuesOnAllLines() throws ClassNotFoundException {

        VariableTracer variableTracer = new VariableTracer();

        // You can find the value of a variable at a point in the execution of a file through:
        // 1. Source file name (not necessarily unique, but that's okay for now)
        // 2. Line number
        // 3. Variable name
        Map<String, Map<Integer, Map<String, List<Value>>>> values = (
                variableTracer.run("Example", "tests/analysis_examples"));

        // Check on line 6 values (j shouldn't be assigned yet)
        assertEquals(1, ((IntegerValue) values.get("Example.java").get(6).get("i").get(0)).value());
        assertNull(values.get("Example.java").get(6).get("j"));

        // Check on line 7 values (j was assigned on the line above)
        assertEquals(1, ((IntegerValue) values.get("Example.java").get(7).get("i").get(0)).value());
        assertEquals(2, ((IntegerValue) values.get("Example.java").get(7).get("j").get(0)).value());

        // Check on line 9 values (i has been reassigned)
        assertEquals(3, ((IntegerValue) values.get("Example.java").get(9).get("i").get(0)).value());
        assertEquals(2, ((IntegerValue) values.get("Example.java").get(9).get("j").get(0)).value());

    }

    @Test
    public void testGetMultipleValuesForAVariableOnOneLine() throws ClassNotFoundException {

        VariableTracer variableTracer = new VariableTracer();

        Map<String, Map<Integer, Map<String, List<Value>>>> values = (
            variableTracer.run("Loop", "tests/analysis_examples"));

        List<Value> iLine5Values = values.get("Loop.java").get(5).get("i");
        assertEquals(3, iLine5Values.size());
        assertEquals(0, ((IntegerValue) iLine5Values.get(0)).value());
        assertEquals(1, ((IntegerValue) iLine5Values.get(1)).value());
        assertEquals(2, ((IntegerValue) iLine5Values.get(2)).value());

    }

}
