public class PrimitiveMethodReturn {

    public static class Watchable {
        public int getValue() {
            return 42;
        }
    }

    public static void main(String[] args) {
        Watchable o = new Watchable();
        System.out.println(o.getValue());
    }

}
