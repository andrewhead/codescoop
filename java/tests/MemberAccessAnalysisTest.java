import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import org.junit.Test;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Set;


public class MemberAccessAnalysisTest {

    MemberAccessAnalysis analysis = new MemberAccessAnalysis();

    @Test
    public void testExceptionWhenClassNotFound() {

        List<ObjectDefinition> noLocations = new ArrayList<ObjectDefinition>();
        boolean exceptionThrown = false;

        try {
            analysis.run("NonexistentClass", "tests/analysis_examples", noLocations);
        } catch (ClassNotFoundException exception) {
            exceptionThrown = true;
        }

        assertTrue(exceptionThrown);

    }

    @Test
    public void testDoesNotTrackObjectThatWasntRequested() throws ClassNotFoundException {

        List<ObjectDefinition> objectDefinitions = new ArrayList<ObjectDefinition>();
        ObjectDefinition instance = new ObjectDefinition("watchable", "ObjectAssigned", 6);
        objectDefinitions.add(instance);

        Map<ObjectDefinition, List<AccessHistory>> accesses = analysis.run(
                "ObjectAssigned", "tests/analysis_examples", objectDefinitions);

        // watchable2 is also a variable in the program, but it shouldn't be tracked
        // because we didn't pass the location of the object's definition into analysis.
        assertNull(accesses.get(new ObjectDefinition("watchable2", "ObjectAssigned", 7)));

    }

    @Test
    public void testTracksInstanceAtLocation() throws ClassNotFoundException {

        List<ObjectDefinition> objectDefinitions = new ArrayList<ObjectDefinition>();
        ObjectDefinition instance = new ObjectDefinition("watchable", "ObjectAssigned", 6);
        objectDefinitions.add(instance);

        Map<ObjectDefinition, List<AccessHistory>> accesses = analysis.run(
                "ObjectAssigned", "tests/analysis_examples", objectDefinitions);
        List<AccessHistory> watchableAccesses = accesses.get(
                new ObjectDefinition("watchable", "ObjectAssigned", 6));
        assertNotNull(watchableAccesses);
        assertEquals(1, watchableAccesses.size());

    }

    @Test
    public void testDoesntTrackInstanceIfClassNameDoesntMatch() throws ClassNotFoundException {

        List<ObjectDefinition> objectDefinitions = new ArrayList<ObjectDefinition>();
        ObjectDefinition instance = new ObjectDefinition("watchable", "ObjectAssigned", 6);
        objectDefinitions.add(instance);

        Map<ObjectDefinition, List<AccessHistory>> accesses = analysis.run(
                "ObjectAssigned", "tests/analysis_examples", objectDefinitions);
        assertNull(accesses.get(new ObjectDefinition("watchable", "AnotherClass", 6)));

    }

    @Test
    public void testAddsPrimitiveFieldAccess() throws ClassNotFoundException {

        List<ObjectDefinition> objectDefinitions = new ArrayList<ObjectDefinition>();
        ObjectDefinition instance = new ObjectDefinition("o", "PrimitiveFieldAccess", 8);
        objectDefinitions.add(instance);

        Map<ObjectDefinition, List<AccessHistory>> accesses = analysis.run(
                "PrimitiveFieldAccess", "tests/analysis_examples", objectDefinitions);
        List<AccessHistory> oInstances = accesses.get(
                new ObjectDefinition("o", "PrimitiveFieldAccess", 8));
        AccessHistory accessHistory = oInstances.get(0);
        Map<String, List<Access>> allFieldAccesses = accessHistory.getFieldAccesses();
        assertEquals(1, allFieldAccesses.size());
        List<Access> fAccesses = allFieldAccesses.get("f");
        assertEquals(1, fAccesses.size());
        Access access = fAccesses.get(0);
        assertTrue(access instanceof PrimitiveAccess);
        PrimitiveAccess primitiveAccess = (PrimitiveAccess) access;
        assertEquals(42, primitiveAccess.getValue());

    }

    @Test
    public void testAddsPrimitiveMethodReturnValue() throws ClassNotFoundException {

        List<ObjectDefinition> objectDefinitions = new ArrayList<ObjectDefinition>();
        ObjectDefinition instance = new ObjectDefinition("o", "PrimitiveMethodReturn", 10);
        objectDefinitions.add(instance);

        Map<ObjectDefinition, List<AccessHistory>> accesses = analysis.run(
                "PrimitiveMethodReturn", "tests/analysis_examples", objectDefinitions);

        List<AccessHistory> oInstances = accesses.get(
                new ObjectDefinition("o", "PrimitiveMethodReturn", 10));
        AccessHistory accessHistory = oInstances.get(0);
        Map<MethodIdentifier, List<Access>> allMethodCalls = accessHistory.getMethodCalls();

        MethodIdentifier methodId = new MethodIdentifier("getValue", new ArrayList<String>());
        List<Access> getValueCalls = allMethodCalls.get(methodId);
        assertEquals(1, getValueCalls.size());
        Access access = getValueCalls.get(0);
        assertTrue(access instanceof PrimitiveAccess);
        PrimitiveAccess primitiveAccess = (PrimitiveAccess) access;
        assertEquals(42, primitiveAccess.getValue());

    }

    @Test
    public void testSavesFieldAndReturnTypes() throws ClassNotFoundException {

        List<ObjectDefinition> objectDefinitions = new ArrayList<ObjectDefinition>();
        ObjectDefinition instance = new ObjectDefinition("w", "FieldAccessAndMethodReturn", 11);
        objectDefinitions.add(instance);

        Map<ObjectDefinition, List<AccessHistory>> accesses = analysis.run(
                "FieldAccessAndMethodReturn", "tests/analysis_examples", objectDefinitions);

        List<AccessHistory> oInstances = accesses.get(instance);
        AccessHistory accessHistory = oInstances.get(0);
        assertEquals("int", accessHistory.getFieldType("i"));
        assertEquals("String", accessHistory.getMethodReturnType(
                new MethodIdentifier("getString", new ArrayList<String>())));

    }

    @Test
    public void testAddsObjectFieldAccess() throws ClassNotFoundException {

        List<ObjectDefinition> objectDefinitions = new ArrayList<ObjectDefinition>();
        ObjectDefinition instance = new ObjectDefinition(
                "o", "ObjectFieldAccess", 12);
        objectDefinitions.add(instance);

        Map<ObjectDefinition, List<AccessHistory>> accesses = analysis.run(
                "ObjectFieldAccess", "tests/analysis_examples", objectDefinitions);

        MethodIdentifier listMethodId = new MethodIdentifier("size", new ArrayList<String>());
        List<Access> fieldAccesses = accesses.get(instance).get(0).getFieldAccesses("objects");
        assertEquals(1, fieldAccesses.size());
        AccessHistory listAccess = (AccessHistory) fieldAccesses.get(0);
        List<Access> sizeResults = listAccess.getReturnValues(listMethodId);
        assertEquals(1, sizeResults.size());
        assertEquals(0, ((PrimitiveAccess) sizeResults.get(0)).getValue());

    }

    @Test
    public void testTracksChangesToNamedReturnedObject() throws ClassNotFoundException {

        List<ObjectDefinition> objectDefinitions = new ArrayList<ObjectDefinition>();
        ObjectDefinition oLocation = new ObjectDefinition("o", "NamedReturnedObjectGetsCalled", 14);
        ObjectDefinition lLocation = new ObjectDefinition("l", "NamedReturnedObjectGetsCalled", 18);
        objectDefinitions.add(oLocation);
        objectDefinitions.add(lLocation);

        Map<ObjectDefinition, List<AccessHistory>> accesses = analysis.run(
                "NamedReturnedObjectGetsCalled", "tests/analysis_examples", objectDefinitions);

        // First, traverse the list of accesses to 'o', and make sure we can reach the returned list
        MethodIdentifier oMethodId = new MethodIdentifier("doWork", new ArrayList<String>());
        MethodIdentifier listMethodId = new MethodIdentifier("size", new ArrayList<String>());
        List<Access> doWorkResults = accesses.get(oLocation).get(0).getReturnValues(oMethodId);
        assertEquals(1, doWorkResults.size());
        AccessHistory listAccess = (AccessHistory) doWorkResults.get(0);
        List<Access> sizeResults = listAccess.getReturnValues(listMethodId);
        assertEquals(1, sizeResults.size());
        assertEquals(0, ((PrimitiveAccess) sizeResults.get(0)).getValue());

        // Second, traverse the list of accesses to 'l', and make sure they are the same accesses
        sizeResults = accesses.get(lLocation).get(0).getReturnValues(listMethodId);
        assertEquals(0, ((PrimitiveAccess) sizeResults.get(0)).getValue());

    }

    @Test
    public void testTracksAccessesOnAnonymousReturnedObject() throws ClassNotFoundException {

        List<ObjectDefinition> objectDefinitions = new ArrayList<ObjectDefinition>();
        ObjectDefinition instance = new ObjectDefinition(
                "o", "AnonymousReturnedObjectGetsCalled", 14);
        objectDefinitions.add(instance);

        Map<ObjectDefinition, List<AccessHistory>> accesses = analysis.run(
                "AnonymousReturnedObjectGetsCalled", "tests/analysis_examples", objectDefinitions);

        MethodIdentifier oMethodId = new MethodIdentifier("doWork", new ArrayList<String>());
        MethodIdentifier listMethodId = new MethodIdentifier("size", new ArrayList<String>());
        List<Access> doWorkResults = accesses.get(instance).get(0).getReturnValues(oMethodId);
        assertEquals(1, doWorkResults.size());
        AccessHistory listAccess = (AccessHistory) doWorkResults.get(0);
        List<Access> sizeResults = listAccess.getReturnValues(listMethodId);
        assertEquals(1, sizeResults.size());
        assertEquals(0, ((PrimitiveAccess) sizeResults.get(0)).getValue());

    }

    @Test
    public void testTrackChainOfAnonymousReturnedObjects() throws ClassNotFoundException {

        List<ObjectDefinition> objectDefinitions = new ArrayList<ObjectDefinition>();
        ObjectDefinition instance = new ObjectDefinition(
                "w", "ChainOfAnonymousObjects", 24);
        objectDefinitions.add(instance);

        Map<ObjectDefinition, List<AccessHistory>> accesses = analysis.run(
                "ChainOfAnonymousObjects", "tests/analysis_examples", objectDefinitions);

        MethodIdentifier listMethodId = new MethodIdentifier("size", new ArrayList<String>());
        AccessHistory internal1Accesses = ((AccessHistory) accesses.get(instance).get(0)
                .getFieldAccesses("internal1").get(0));
        AccessHistory internal2Accesses = ((AccessHistory) internal1Accesses
                .getFieldAccesses("internal2").get(0));
        AccessHistory internal3Accesses = ((AccessHistory) internal2Accesses
                .getFieldAccesses("internal3").get(0));
        AccessHistory objectsAccesses = ((AccessHistory) internal3Accesses
                .getFieldAccesses("objects").get(0));
        PrimitiveAccess sizeAccess = ((PrimitiveAccess) objectsAccesses
                .getReturnValues(listMethodId).get(0));
        assertEquals(0, sizeAccess.getValue());

    }

    @Test
    public void testSaveMultipleInstancesWithDifferenceValues() throws ClassNotFoundException {

        List<ObjectDefinition> objectDefinitions = new ArrayList<ObjectDefinition>();
        ObjectDefinition instance = new ObjectDefinition(
                "w", "InstanceCreatedMultipleTimes", 13);
        objectDefinitions.add(instance);

        Map<ObjectDefinition, List<AccessHistory>> accesses = analysis.run(
                "InstanceCreatedMultipleTimes", "tests/analysis_examples", objectDefinitions);

        List<AccessHistory> wAccesses = accesses.get(instance);
        assertEquals(2, wAccesses.size());
        PrimitiveAccess firstInstanceInt = (PrimitiveAccess)
                wAccesses.get(0).getFieldAccesses("myInt").get(0);
        assertEquals(0, firstInstanceInt.getValue());
        PrimitiveAccess secondInstanceInt = (PrimitiveAccess)
                wAccesses.get(1).getFieldAccesses("myInt").get(0);
        assertEquals(1, secondInstanceInt.getValue());

    }

    // An earlier test showed that the run time converts an instance variable to "null" before it
    // assigns to it a second time in a loop.  Here, we are making sure that that behavior holds
    // when we assign the same instance twice (we are currently using a non-null check to tell
    // when the instance has been initialized).
    @Test
    public void testSaveMultipleInstancesCreatedOnDifferenceLines() throws ClassNotFoundException {

        List<ObjectDefinition> objectDefinitions = new ArrayList<ObjectDefinition>();
        ObjectDefinition instance1 = new ObjectDefinition(
                "w", "MultipleInstanceDefinitionLines", 11);
        ObjectDefinition instance2 = new ObjectDefinition(
                "w", "MultipleInstanceDefinitionLines", 13);
        objectDefinitions.add(instance1);
        objectDefinitions.add(instance2);

        Map<ObjectDefinition, List<AccessHistory>> accesses = analysis.run(
                "MultipleInstanceDefinitionLines", "tests/analysis_examples", objectDefinitions);

        List<AccessHistory> w1Accesses = accesses.get(instance1);
        assertEquals(1, w1Accesses.size());
        List<Access> w1IntAccesses = w1Accesses.get(0).getFieldAccesses("myInt");
        assertEquals(1, w1IntAccesses.size());
        assertEquals(0, ((PrimitiveAccess) w1IntAccesses.get(0)).getValue());

        List<AccessHistory> w2Accesses = accesses.get(instance2);
        assertEquals(1, w2Accesses.size());
        List<Access> w2IntAccesses = w2Accesses.get(0).getFieldAccesses("myInt");
        assertEquals(1, w2IntAccesses.size());
        assertEquals(42, ((PrimitiveAccess) w2IntAccesses.get(0)).getValue());

    }

    // Knowing the implementation of our object access analysis, there could be
    // problems in the logic if an object is assigned 'null' multiple times in that
    // in one version of our analysis, we rely on a change in instance variable to
    // to add debugger events for its variables.
    @Test
    public void testStillUpdateInstanceHistoryAfterMultipleNulls() throws ClassNotFoundException {

        // Only two of these locations should have any access history (lines 8 and 11, where
        // the object is assigned a non-null value.
        List<ObjectDefinition> objectDefinitions = new ArrayList<ObjectDefinition>();
        objectDefinitions.add(new ObjectDefinition("w", "MultipleNullAssignments", 8));
        objectDefinitions.add(new ObjectDefinition("w", "MultipleNullAssignments", 9));
        objectDefinitions.add(new ObjectDefinition("w", "MultipleNullAssignments", 10));
        objectDefinitions.add(new ObjectDefinition("w", "MultipleNullAssignments", 11));
        objectDefinitions.add(new ObjectDefinition("w", "MultipleNullAssignments", 12));
        objectDefinitions.add(new ObjectDefinition("w", "MultipleNullAssignments", 13));

        Map<ObjectDefinition, List<AccessHistory>> accesses = analysis.run(
                "MultipleNullAssignments", "tests/analysis_examples", objectDefinitions);

        assertEquals(1, accesses.get(new ObjectDefinition("w", "MultipleNullAssignments", 8)).size());
        assertEquals(0, accesses.get(new ObjectDefinition("w", "MultipleNullAssignments", 9)).size());
        assertEquals(0, accesses.get(new ObjectDefinition("w", "MultipleNullAssignments", 10)).size());
        assertEquals(1, accesses.get(new ObjectDefinition("w", "MultipleNullAssignments", 11)).size());
        assertEquals(0, accesses.get(new ObjectDefinition("w", "MultipleNullAssignments", 12)).size());
        assertEquals(0, accesses.get(new ObjectDefinition("w", "MultipleNullAssignments", 13)).size());

    }

    @Test
    public void testSaveResultsOfMultipleFieldAccesses() throws ClassNotFoundException {

        List<ObjectDefinition> objectDefinitions = new ArrayList<ObjectDefinition>();
        ObjectDefinition objectDefinition = new ObjectDefinition("w", "MultipleFieldAccesses", 8);
        objectDefinitions.add(objectDefinition);

        Map<ObjectDefinition, List<AccessHistory>> accesses = analysis.run(
                "MultipleFieldAccesses", "tests/analysis_examples", objectDefinitions);
        
        assertEquals(2, accesses.get(objectDefinition).get(0).getFieldAccesses("myInt").size());

    }

    @Test
    public void testIfNoDefinitionsProvidedDefinitionsAreDiscovered() throws ClassNotFoundException {
        
        Map<ObjectDefinition, List<AccessHistory>> accesses = analysis.run(
                "DiscoverableDefinitions", "tests/analysis_examples");
        assertEquals(3, accesses.size());
        Set<ObjectDefinition> definitions = accesses.keySet();

        // Make sure that the list of definitions include those that we expect
        assertTrue(definitions.contains(new ObjectDefinition("o", "DiscoverableDefinitions", 8)));
        assertTrue(definitions.contains(new ObjectDefinition("o", "DiscoverableDefinitions", 9)));
        assertTrue(definitions.contains(new ObjectDefinition("o2", "DiscoverableDefinitions", 10)));
        
        // Furthermore, do a sanity check to make sure that the analysis picked up on the accesses
        AccessHistory oAccesses = accesses.get(
                new ObjectDefinition("o", "DiscoverableDefinitions", 9)).get(0);
        PrimitiveAccess fieldAccess = (PrimitiveAccess) oAccesses.getFieldAccesses("i").get(0);
        assertEquals(42, fieldAccess.getValue());

    }

    // In an earlier version of this code, we only made one shared access history for each
    // instance.  If the instance was returned by multiple accesses, or was assigned to
    // multiple values, then all versions of the instance in the access history tree would
    // whare the same access history object.  This can cause cycles (e.g., if a parent's child
    // is accessed), which can cause iterators over the access history tree to never terminate.
    @Test
    public void testNoCyclesInAcesssHistoryGraph() throws ClassNotFoundException {

        List<ObjectDefinition> objectDefinitions = new ArrayList<ObjectDefinition>();
        ObjectDefinition parentDefinition = new ObjectDefinition("parent", "CyclicAccess", 13);
        ObjectDefinition childDefinition = new ObjectDefinition("child", "CyclicAccess", 14);
        objectDefinitions.add(parentDefinition);
        objectDefinitions.add(childDefinition);

        Map<ObjectDefinition, List<AccessHistory>> accesses = analysis.run(
                "CyclicAccess", "tests/analysis_examples", objectDefinitions);

        // For this example, the access history should show a link from a parent to a child
        // and back to a parent.  But this is where the links should stop: there should not
        // be another link from the parent back to the child (a loop in the access history tree).
        AccessHistory parentAccesses = accesses.get(parentDefinition).get(0);
        AccessHistory childAccesses = (AccessHistory) parentAccesses.getFieldAccesses("child").get(0);
        parentAccesses = (AccessHistory) childAccesses.getFieldAccesses("parent").get(0);
        assertEquals(0, parentAccesses.getFieldAccesses("child").size());

    }

}
