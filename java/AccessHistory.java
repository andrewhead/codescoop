import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;


public class AccessHistory extends Access {

    private Map<String, String> mFieldTypes = new HashMap<String, String>();
    private Map<String, List<Access>> mFieldAccesses = new HashMap<String, List<Access>>();

    private Map<MethodIdentifier, String> mMethodReturnTypes = (
        new HashMap<MethodIdentifier, String>());
    private Map<MethodIdentifier, List<Access>> mMethodCalls = (
        new HashMap<MethodIdentifier, List<Access>>());

    public AccessHistory (List<String> pFieldNames, List<String> pFieldTypes,
            List<MethodIdentifier> pMethodIds, List<String> pMethodReturnTypes) {
        for (int fieldIndex = 0; fieldIndex < pFieldNames.size(); fieldIndex++) {
            String fieldName = pFieldNames.get(fieldIndex);
            String type = pFieldTypes.get(fieldIndex);
            List<Access> accessesForField = new ArrayList<Access>();
            mFieldAccesses.put(fieldName, accessesForField);
            mFieldTypes.put(fieldName, type);
        }
        for (int methodIndex = 0; methodIndex < pMethodIds.size(); methodIndex++) {
            MethodIdentifier methodId = pMethodIds.get(methodIndex);
            String returnType = pMethodReturnTypes.get(methodIndex);
            List<Access> accessesForMethod = new ArrayList<Access>();
            mMethodCalls.put(methodId, accessesForMethod);
            mMethodReturnTypes.put(methodId, returnType);
        }
    }

    public void addFieldAccess(String pFieldName, Access pAccess) {
        List<Access> accesses = this.mFieldAccesses.get(pFieldName);
        accesses.add(pAccess);
    }

    public String getFieldType(String pFieldName) {
        return this.mFieldTypes.get(pFieldName);
    }

    public List<Access> getFieldAccesses(String pFieldName) {
        return this.mFieldAccesses.get(pFieldName);
    }

    public Map<String, List<Access>> getFieldAccesses() {
        return this.mFieldAccesses;
    }

    public void addMethodCall(MethodIdentifier pMethodId, Access pAccess) {
        List<Access> calls = this.mMethodCalls.get(pMethodId);
        calls.add(pAccess);
    }

    public String getMethodReturnType(MethodIdentifier pMethodId) {
        return this.mMethodReturnTypes.get(pMethodId);
    }

    public List<Access> getReturnValues(MethodIdentifier pMethodId) {
        return this.mMethodCalls.get(pMethodId);
    }

    public Map<MethodIdentifier, List<Access>> getMethodCalls() {
        return this.mMethodCalls;
    }

}
