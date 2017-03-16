public class MultipleFieldAccesses {

    public static class Watchable {
        public int myInt = 1;
    }

    public static void main(String[] args) {
        Watchable w = new Watchable();
        int result = w.myInt + w.myInt;
    }

}
