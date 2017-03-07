# Examplify

Make useful example code from your existing code.

## Annoying, brittle installation requirements

### Platform requirements

The only workable configuration I have found for satisfying
Soot and the Node `java` packages is to have JDK version 1.7
as the primary Java VM.

### Installation instructions

Start out by installing all of the Node dependencies for the
package

```bash
npm install
```

This project requires Soot, a static analysis tool, to run.
The classes for Soot are stored in a pretty large JAR.  It's
not included in the repository, so for right now, you can
run this helper script to fetch the dependencies.

```bash
cd java/libs
./fetch_libs.sh
```

Then you should also compile the dataflow code:

```bash
# Assuming you're starting back in the main directory
SOOT_JARS=`ls -d -1 $PWD/java/libs/*.jar | tr '\n' ':'`
JAVA_HOME=`/usr/libexec/java_home -v 1.7`
JAVA_HOME_LIBS=`ls -d -1 $JAVA_HOME/jre/lib/*.jar | tr '\n' ':'`
cd java/
javac -cp $SOOT_JARS:$JAVA_HOME_LIBS:. DataflowAnalysis.java
```

## Developing

### Java tests

To make sure that the static analysis code is working properly:

```bash
cd java/
./runtests.sh
```

### Running Soot

After following the dependency instructions above, you should
be able to run [Soot](https://github.com/Sable/soot) to
generate intermediate representation.  To run soot, use the
following commands:

```bash
CLASSPATH=$JAVA_HOME/jre/lib/rt.jar:libs/*:. java soot.Main -cp $CLASSPATH Example -src-prec java -f J
```

Substitute `Example` with the name of your `.java` file
(though omit the `.java` extension).  This file will need to
be placed in the same directory as the one that you are
running the command.  The options do the following:
* `-src-prec java`: runs Soot on a `.java` file instead of a
    `.class` file
* `-f J`: produces a Jimple IR file (instead of a class)
* `-cp $CLASSPATH`: makes the libraries on the classpath
    available to Soot (needed to run Soot)

### Style Guide

When possible, I use this style guide for Coffeescript:
https://github.com/polarmobile/coffeescript-style-guide

When defining enums, define each field as an object.  This
make comparisons with an equals sign use values that are
exclusive to each class, instead of comparing just on the
fields of the object.

<!--
![A screenshot of your package](https://f.cloud.github.com/assets/69169/2290250/c35d867a-a017-11e3-86be-cd7c5bf3ff9b.gif)
-->
