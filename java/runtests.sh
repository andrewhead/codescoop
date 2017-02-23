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
javac -cp $JUNIT_JARS:$SOOT_JARS:$JDI_JARS:. *.java
javac -cp $JUNIT_JARS:$SOOT_JARS:$JDI_JARS:. tests/*.java

# Compile classes for all of the files we're going to run test analysis on
# Use `-g` so we get symbol information, for extracting variable names during analysis.
javac -g tests/analysis_examples/*.java

# Discover and run tests
java -cp $JUNIT_JARS:$SOOT_JARS:$JAVA_HOME_JARS:$JDI_JARS:tests/:. org.junit.runner.JUnitCore $TEST_CLASSES
