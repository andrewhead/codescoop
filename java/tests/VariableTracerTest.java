import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;
import org.junit.Test;

import java.util.Map;

import com.sun.jdi.Value;
import com.sun.jdi.IntegerValue;


public class VariableTracerTest {

    @Test
    public void testExceptionWhenClassNotFound() {

        VariableTracer variableTracer = new VariableTracer();
        boolean exceptionThrown = false;

        try {
            variableTracer.run("NonexistentClass", "tests/");
        } catch (ClassNotFoundException exception) {
            exceptionThrown = true;
        }

        assertTrue(exceptionThrown);

    }

    @Test
    public void testGetAllValuesOnAllLines() throws ClassNotFoundException {

        VariableTracer variableTracer = new VariableTracer();

        // You can find the value of a variable at a point in the execution of a file through:
        // 1. Source file name (not necessarily unique, but that's okay for now)
        // 2. Line number
        // 3. Variable name
        // TODO: Save multiple values when function run multiple times
        Map<String, Map<Integer, Map<String, Value>>> values = variableTracer.run("Example", "tests/");

        // Check on line 6 values (j shouldn't be assigned yet)
        assertEquals(1, ((IntegerValue) values.get("Example.java").get(6).get("i")).value());
        assertNull(values.get("Example.java").get(6).get("j"));

        // Check on line 7 values (j was assigned on the line above)
        assertEquals(1, ((IntegerValue) values.get("Example.java").get(7).get("i")).value());
        assertEquals(2, ((IntegerValue) values.get("Example.java").get(7).get("j")).value());

        // Check on line 9 values (i has been reassigned)
        assertEquals(3, ((IntegerValue) values.get("Example.java").get(9).get("i")).value());
        assertEquals(2, ((IntegerValue) values.get("Example.java").get(9).get("j")).value());

    }

}
