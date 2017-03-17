import java.util.ArrayList;
import java.util.List;


public class AccessSampler {
 
    public static class Watchable {

        int primitiveField = 1;
        List objectField = new ArrayList();

        public int doPrimitiveWork(int arg) {
            return 42;
        }

        public List doObjectWork() {
            return new ArrayList();
        }

        public void setField(int newValue) {
            primitiveField = newValue;
        }

    }

    public static void main(String[] args) {
        Watchable obj = new Watchable();
        System.out.println(obj.primitiveField);
        obj.setField(2);
        System.out.println(obj.primitiveField);
        System.out.println(obj.objectField);
        System.out.println(obj.doPrimitiveWork(1));
        System.out.println(obj.doPrimitiveWork(2));
        System.out.println(obj.doObjectWork().size());
        Watchable obj2 = new Watchable();
    }

}
