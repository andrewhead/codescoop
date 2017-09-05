public class MultipleInstanceDefinitionLines {

    public static class Watchable {
        public int myInt;
        public Watchable(int pMyInt) {
            this.myInt = pMyInt;
        }
    }

    public static void main(String[] args) {
        Watchable w = new Watchable(0);
        System.out.println(w.myInt);
        w = new Watchable(42);
        System.out.println(w.myInt);
    }

}
