public class CyclicAccess {

    public static class Parent {
        public Child child;
    }

    public static class Child {
        public Parent parent;
        public Child(Parent pParent) { this.parent = pParent; }
    }

    public static void main(String[] args) {
        Parent parent = new Parent();
        Child child = new Child(parent);
        parent.child = child;
        System.out.println(parent.child.parent);
    }

}
