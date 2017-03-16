import java.util.ArrayList;
import java.util.List;


public class ChainOfAnonymousObjects {

    public static class Internal3 {
        public List<Object> objects = new ArrayList<Object>();
    }

    public static class Internal2 {
        public Internal3 internal3 = new Internal3();
    }

    public static class Internal1 {
        public Internal2 internal2 = new Internal2();
    }

    public static class Watchable {
        public Internal1 internal1 = new Internal1();
    }

    public static void main(String[] args) {
        Watchable w = new Watchable();
        System.out.println(w.internal1.internal2.internal3.objects.size());
    }

}
