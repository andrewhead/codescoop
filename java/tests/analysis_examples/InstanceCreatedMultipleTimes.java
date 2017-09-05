public class InstanceCreatedMultipleTimes {

    public static class Watchable {
        public int myInt;
        public Watchable (int pMyInt) {
            this.myInt = pMyInt;
        }
    }

    public static void main(String[] args) {
        Watchable w;
        for (int i = 0; i < 2; i++) {
            w = new Watchable(i);
            System.out.println(w.myInt);
        }
    }

}
