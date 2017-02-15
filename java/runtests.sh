#! /bin/bash

# Make list of jars that are needed for compiling and running tests
JUNIT_JARS=./libs/junit-4.12.jar:./libs/hamcrest-core-1.3.jar
SOOT_JARS=`ls -d -1 ./libs/*.jar | tr '\n' ':'`
JAVA_HOME_JARS=`ls -d -1 $JAVA_HOME/jre/lib/*.jar | tr '\n' ':'`

# Discover test classes
TESTS_DIR=tests
TEST_CLASSES=`(cd $TESTS_DIR && ls *Test.java) | sed -e 's/\.java$//'`

# Compile all tests
javac -cp $JUNIT_JARS:$SOOT_JARS:. tests/*.java

# Discover and run tests
java -cp $JUNIT_JARS:$SOOT_JARS:$JAVA_HOME_JARS:$TESTS_DIR/:.\
  org.junit.runner.JUnitCore $TEST_CLASSES
