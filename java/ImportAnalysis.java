import java.util.HashSet;
import java.util.Set;

import org.reflections.Reflections;
import org.reflections.scanners.SubTypesScanner;


public class ImportAnalysis {

    // This function will probably crash if an import statement is importing static members,
    // or if it's importing methods from a package.
    public Set<String> getClassNames(String importName) {

        Set<String> classNameSet = new HashSet<String>();

        // Sometimes, import statements yield a single class.  We try to load the class at the
        // import's path, to see if this import imports just one class.
        Class<? extends Object> importedClass = null;
        try {
            importedClass = Class.forName(importName);
        } catch (ClassNotFoundException exception) {}
        if (importedClass != null) {
            classNameSet.add(importName);
            return classNameSet;
        }

        // If it doesn't return just one class, it might be a wildcard import.
        // We fetch the fully-qualified names of all classes from the package specified
        // in the import statement using "Reflections"
        // REUSE: This snippet is based on the tip from this Stack Overflow post:
        // http://stackoverflow.com/questions/520328/can-you-find-all-classes-in-a-package-using-reflection
        Reflections reflections = new Reflections(importName, new SubTypesScanner(false));
        Set<Class<? extends Object>> classSet = reflections.getSubTypesOf(Object.class);

        // Save the string names for each of the classes
        for (Class<? extends Object> klazz: classSet) {
            classNameSet.add(klazz.getCanonicalName());
        }
        return classNameSet;

    }

}
