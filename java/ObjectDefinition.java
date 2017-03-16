public class ObjectDefinition {

    private String mName;
    private String mClassName;
    private int mLineNumber;

    public ObjectDefinition(String pName, String pClassName, int pLineNumber) {
        this.mName = pName;
        this.mClassName = pClassName;
        this.mLineNumber = pLineNumber;
    }

    public String getName() {
        return this.mName;
    }

    public String getClassName() {
        return this.mClassName;
    }

    public int getLineNumber() {
        return this.mLineNumber;
    }

    @Override
    public int hashCode() {
        return this.mClassName.hashCode() * this.mName.hashCode() * this.mLineNumber;
    }

    @Override
    public boolean equals(Object other) {
        if (!(other instanceof ObjectDefinition)) {
            return false;
        }
        ObjectDefinition otherLocation = (ObjectDefinition) other;
        return (
            otherLocation.getClassName().equals(this.getClassName()) &&
            otherLocation.getName().equals(this.getName()) &&
            otherLocation.getLineNumber() == this.getLineNumber()
        );
    }

    @Override
    public String toString() {
        return this.mName + " (class " + this.mClassName + ", L" + this.mLineNumber + ")";
    }

}
