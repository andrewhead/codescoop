import java.io.IOException;
import java.util.HashSet;
import java.util.Set;

import com.google.common.reflect.ClassPath;
import org.reflections.Reflections;
import org.reflections.scanners.SubTypesScanner;


// Discover what classes can be imported by an import statement.  In the past, this was implemented
// using "Reflections" (https://github.com/ronmamo/reflections).  However, we found that it
// couldn't find some classes provided by some wilcard imports (for example, SSLSocket from
// javax.net.ssl).  So we re-implemented wildcards using a beta feature from Guava.
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

        // Use Guava to import classes from wildcard imports, using a pattern from this reference;
        // http://stackoverflow.com/questions/520328/can-you-find-all-classes-in-a-package-using-reflection
        ClassLoader loader = Thread.currentThread().getContextClassLoader();
        if (importName.endsWith(".*")) {
            String packageName = importName.replaceAll("\\.\\*$", "");
            try {
                for (ClassPath.ClassInfo classInfo: ClassPath.from(loader).getTopLevelClasses()) {
                    if (classInfo.getName().startsWith(packageName)) {
                        Class<?> klazz = classInfo.load();
                        classNameSet.add(klazz.getCanonicalName());
                    }
                }
            } catch (IOException exception) {
            } catch (NoClassDefFoundError exception) {}
            
        }

        return classNameSet;

    }

}
