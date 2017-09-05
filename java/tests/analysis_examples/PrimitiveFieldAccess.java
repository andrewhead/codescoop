public class PrimitiveFieldAccess {

    public static class Watchable {
        int f;
    }

    public static void main(String[] args) {
        Watchable o = new Watchable();
        o.f = 42;
        System.out.println(o.f);
    }

}
