public class MultipleNullAssignments {

    public static class Watchable {}

    public static void main(String[] args) {
        Watchable w = null;
        w = null;
        w = new Watchable();
        w = null;
        w = null;
        w = new Watchable();
    }

}
