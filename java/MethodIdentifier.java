import java.util.ArrayList;
import java.util.List;


/**
 * XXX: For now, we only identify a method based on its name and string names of each of the
 * types it takes as arguments.  This is a good enough approximation to uniquely identify
 * methods when there's method overloading, in most cases.  It won't work if two versions of
 * the method have the same type names, but different actual types.
 */
public class MethodIdentifier {

    private String mName;
    private List<String> mTypeNames;

    public MethodIdentifier(String pName, List<String> pTypeNames) {
        this.mName = pName;
        this.mTypeNames = pTypeNames;
    }

    public String getName() {
        return this.mName;
    }

    public List<String> getTypeNames() {
        return this.mTypeNames;
    }
    
    @Override
    public int hashCode() {
        int hashCode = this.mName.hashCode();
        for (String typeName: this.mTypeNames) {
            hashCode *= typeName.hashCode();
        }
        return hashCode;
    }

    @Override
    public boolean equals(Object other) {
        if (!(other instanceof MethodIdentifier)) return false;
        MethodIdentifier otherIdentifier = (MethodIdentifier) other;
        if (!(otherIdentifier.getName().equals(this.mName))) return false;
        if (!(otherIdentifier.getTypeNames().equals(this.mTypeNames))) return false;
        return true;
    }

    @Override
    public String toString() {
        String s = "[Method " + this.mName + " (";
        for (String typeName: this.mTypeNames) {
            s += (typeName + ",");
        }
        s += ")]";
        return s;
    }

}
