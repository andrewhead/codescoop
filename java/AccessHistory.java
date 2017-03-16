import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;


public class AccessHistory extends Access {

    private Map<String, List<Access>> mFieldAccesses = new HashMap<String, List<Access>>();
    private Map<MethodIdentifier, List<Access>> mMethodCalls = (
        new HashMap<MethodIdentifier, List<Access>>());

    public AccessHistory (List<String> pFieldNames, List<MethodIdentifier> pMethodIds) {
        for (String fieldName: pFieldNames) {
            List<Access> accessesForField = new ArrayList<Access>();
            mFieldAccesses.put(fieldName, accessesForField);
        }
        for (MethodIdentifier methodId: pMethodIds) {
            List<Access> accessesForMethod = new ArrayList<Access>();
            mMethodCalls.put(methodId, accessesForMethod);
        }
    }

    public void addFieldAccess(String pFieldName, Access pAccess) {
        List<Access> accesses = this.mFieldAccesses.get(pFieldName);
        accesses.add(pAccess);
    }

    public void addMethodCall(MethodIdentifier pMethodId, Access pAccess) {
        List<Access> calls = this.mMethodCalls.get(pMethodId);
        calls.add(pAccess);
    }

    public List<Access> getReturnValues(MethodIdentifier pMethodId) {
        return this.mMethodCalls.get(pMethodId);
    }

    public List<Access> getFieldAccesses(String pFieldName) {
        return this.mFieldAccesses.get(pFieldName);
    }

    public Map<String, List<Access>> getFieldAccesses() {
        return this.mFieldAccesses;
    }

    public Map<MethodIdentifier, List<Access>> getMethodCalls() {
        return this.mMethodCalls;
    }

}
