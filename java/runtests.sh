#! /bin/bash

# Make list of jars that are needed for compiling and running tests
JUNIT_JARS=./libs/junit-4.12.jar:./libs/hamcrest-core-1.3.jar
SOOT_JARS=`ls -d -1 ./libs/*.jar | tr '\n' ':'`
JAVA_HOME_JARS=`ls -d -1 $JAVA_HOME/jre/lib/*.jar | tr '\n' ':'`
JDI_JARS=$JAVA_HOME/lib/tools.jar

# Discover test classes
TESTS_DIR=tests
TEST_CLASSES=`(cd $TESTS_DIR && ls *Test.java) | sed -e 's/\.java$//'`

# Compile all classes, and all tests
# Make sure to compile with -g flags so that our test files have debug symbols.
# Otherwise, our trace analysis programs will fail
javac -cp $JUNIT_JARS:$SOOT_JARS:$JDI_JARS:. *.java
javac -g -cp $JUNIT_JARS:$SOOT_JARS:$JDI_JARS:. tests/*.java

# Discover and run tests
# XXX: I'm not sure why, but if I use the -cp argument instead of the $CLASSPATH variable, it's
# impossible for the VariableTracer test to find the Example class
TEST_CLASSPATH=$JUNIT_JARS:$SOOT_JARS:$JAVA_HOME_JARS:$JDI_JARS:$TESTS_DIR/
CLASSPATH=$TEST_CLASSPATH java org.junit.runner.JUnitCore $TEST_CLASSES
