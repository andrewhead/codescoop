import java.util.ArrayList;
import java.util.List;


public class NamedReturnedObjectGetsCalled {

    public static class Watchable {
        public List<Object> doWork() {
            return new ArrayList<Object>();
        }
    }

    public static void main(String[] args) {
        Watchable o = new Watchable();
        // This list l should be stored in two places: First, we should create
        // an entry for it in the access history table.  Second, we should create
        // a reference from the return value of o.doWork to the objects access history.
        List<Object> l = o.doWork();
        System.out.println(l.size());
    }

}
