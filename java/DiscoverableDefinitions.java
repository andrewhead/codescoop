public class DiscoverableDefinitions {

    public static class Watchable {
        public int i = 42;
    }

    public static void main(String[] args) {
        Watchable o = new Watchable();
        o = new Watchable();
        Watchable o2 = new Watchable();
        int i = 1;  // Should not get detected
        System.out.println(o.i);
    }

}
