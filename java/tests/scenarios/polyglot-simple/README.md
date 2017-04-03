# Polyglot scenario

To create this scenario, we did the following: We removed
the `Main.java` file from the `polyglot/main` directory.  We
then made a few changes to the file:

* We removed its inclusion in the package `polyglot.main` so
    it could stand alone in the root of the directory and
    Examplify didn't have to infer its package name from the
    source code
* We imported all of the members 
* We recompiled Polyglot 1.3.5, making the `exitCode` field
    on the `UsageError.java` class public so that it could
    be accessed from outside of the class
* We hard-coded the arguments passed in to the `Main` class
    to be [`-ext`, `pao`, `Hello.pao`]

The test scenario was pulled from the original Polyglot
source.  This is the `pao` extension to the Java language,
and the main compiles it down to java.

To compile and run:

```bash
javac -cp deps/pao.jar:deps/polyglot.jar:deps/java_cup.jar Main.java
java -cp deps/pao.jar:deps/polyglot.jar:deps/java_cup.jar:. Main
```

To make this scenario run, the deps have also been copied
into the root `deps` folder of this project.
