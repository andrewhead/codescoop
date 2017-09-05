public class AccessesFromThis {

    private static class Watchable {
        
        private int fieldAccessedFromThis = 1;

        private void methodCalledFromThis() {}

        public int doWork() {
            this.methodCalledFromThis();
            return this.fieldAccessedFromThis;
        }

    }

    public static void main(String[] args) {
        Watchable o = new Watchable();
        System.out.println(o.doWork());
    }

}
