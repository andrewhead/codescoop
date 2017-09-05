public class FieldAccessAndMethodReturn {

    public static class Watchable {
        int i = 0;
        public String getString() {
            return "Hello";
        }
    }

    public static void main(String[] args) {
        Watchable w = new Watchable();
        System.out.println(w.i);
        System.out.println(w.getString());
    }

}
