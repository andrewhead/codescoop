#! /bin/bash

source includes.sh
source build.sh

# Discover and run tests
java -cp $JUNIT_JARS:$SOOT_JARS:$JAVA_HOME_JARS:$JDI_JARS:$REFLECTIONS_JARS:tests/:tests/analysis_examples/:. \
  org.junit.runner.JUnitCore $TEST_CLASSES
