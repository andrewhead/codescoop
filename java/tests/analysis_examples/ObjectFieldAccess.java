import java.util.ArrayList;
import java.util.List;


public class ObjectFieldAccess {

    public static class Watchable {
        public List<Object> objects = new ArrayList<Object>();
    }

    public static void main(String[] args) {
        Watchable o = new Watchable();
        System.out.println(o.objects.size());
    }

}
