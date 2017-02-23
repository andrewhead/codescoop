public class InternalClassCaller {

    private class InternalClass {}

    public InternalClassCaller() {}

    public void runCallCode() {
        int i = 0;

        // In previous versions of our variable tracer, the code
        // would stop stepping through a method after an internal
        // class had been initialized (line 14 wouldn't be reached).
        new InternalClass();
        int j = i + 1;

    }

    public static void main(String[] args) {
        InternalClassCaller caller = new InternalClassCaller();
        caller.runCallCode();
    }

}
