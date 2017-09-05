public class StringFieldAccess {

    private static class Watchable {
        public String s = "Hello world";
    }

    public static void main(String[] args) {
        Watchable o = new Watchable();
        System.out.println(o.s);
    }

}
