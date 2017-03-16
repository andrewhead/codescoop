import java.util.ArrayList;
import java.util.List;


public class AnonymousReturnedObjectGetsCalled {

    public static class Watchable {
        public List<Object> doWork() {
            return new ArrayList<Object>();
        }
    }

    public static void main(String[] args) {
        Watchable o = new Watchable();
        // A list is getting returned and a method on it is getting called instantly.
        // Our code should note that an object is returned from doWork that returns
        // 0 when its "size" method is called.
        o.doWork().size();
    }

}
