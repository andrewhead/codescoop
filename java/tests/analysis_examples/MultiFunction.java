public class MultiFunction {

    public static int anotherFunctionToBeSteppedThrough() {
        int i = 1;
        int j = i + 1;
        return j;
    }

    public static void main(String[] args) {
        anotherFunctionToBeSteppedThrough();
    }

}
