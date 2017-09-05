public class PrimitiveAccess extends Access {

    private Object mValue;

    public PrimitiveAccess(Object pValue) {
        this.mValue = pValue;
    }

    public Object getValue() {
        return this.mValue;
    }

}
