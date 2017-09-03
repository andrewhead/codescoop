import java.io.File;
import java.io.IOException;


public class Throws {

    private static class CustomException1 extends Exception {}
    private static class CustomException2 extends Exception {}

    private static class InternalClass {
        public InternalClass() {}
        public InternalClass(int i) throws CustomException1 {}
        public InternalClass(String s) throws CustomException2 {}
        public void methodWithOneThrows() throws CustomException1 {}
        public void methodWithTwoThrows() throws CustomException1, CustomException2 {}
        public void overloadedMethod(int i) throws CustomException1 {}
        public void overloadedMethod(String s) throws CustomException2 {}
    }

    private static class InternalSubclass extends InternalClass {}

    public static void main(String[] args) throws IOException, CustomException1, CustomException2 {
        File file = new File("Nonexisting location");
        file.getCanonicalPath();  // throws IOException
        InternalClass o = new InternalClass();
        o.methodWithOneThrows();  // throws CustomException1
        o.methodWithTwoThrows();  // throws CustomException1, customException2
        o.overloadedMethod(1); // throws CustomException1
        o.overloadedMethod(""); // throws CustomException2
        InternalClass o2 = new InternalClass(1);  // throws CustomException1
        InternalClass o3 = new InternalClass("");  // throws CustomException2
        InternalSubclass o4 = new InternalSubclass();
        o4.methodWithOneThrows();  // throws CustomException1
    }

}
