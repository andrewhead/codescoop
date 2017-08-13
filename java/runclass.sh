#! /bin/bash

# Make list of jars that are needed for compiling and running tests
JUNIT_JARS=./libs/junit-4.12.jar:./libs/hamcrest-core-1.3.jar
REFLECTIONS_JARS=./libs/reflections-0.9.11.jar:./libs/guava-20.0.jar:./libs/javassist-3.21.0-GA.jar
SOOT_JARS=`ls -d -1 ./libs/*.jar | tr '\n' ':'`
JAVA_HOME_JARS=`ls -d -1 $JAVA_HOME/jre/lib/*.jar | tr '\n' ':'`
JDI_JARS=$JAVA_HOME/lib/tools.jar
DATABASE_SCENARIO_JARS=./libs/database.jar
POLYGLOT_SCENARIO_JARS=./libs/polyglot.jar:./libs/java_cup.jar:./libs/pao.jar
CHAT_SCENARIO_JARS=./libs/chat-client.jar
JSOUP_SCENARIO_JARS=./libs/jsoup-jdk-1.4.jar:./libs/javax.mail-1.4.7.jar
ALL_JARS=$JUNIT_JARS:$REFLECTIONS_JARS:$SOOT_JARS:$JAVA_HOME_JARS:$JDI_JARS:$DATABASE_SCENARIO_JARS:$POLYGLOT_SCENARIO_JARS:$JSOUP_SCENARIO_JARS

# Discover test classes
TESTS_DIR=tests
TEST_CLASSES=`(cd $TESTS_DIR && ls *Test.java) | sed -e 's/\.java$//'`

# Compile all classes, and all tests
javac -g -cp $JUNIT_JARS:$SOOT_JARS:$JDI_JARS:$REFLECTIONS_JARS:. *.java
javac -g -cp $JUNIT_JARS:$SOOT_JARS:$JDI_JARS:$REFLECTIONS_JARS:. tests/*.java

# Compile classes for all of the files we're going to run test analysis on
# Use `-g` so we get symbol information, for extracting variable names during analysis.
javac -g tests/analysis_examples/*.java
javac -g -cp $SOOT_JARS:$JDI_JARS tests/scenarios/examplify/*.java
javac -g -cp $CHAT_SCENARIO_JARS tests/scenarios/chat/Server.java
javac -g -cp $DATABASE_SCENARIO_JARS tests/scenarios/database-use/BookListing.java
javac -g -cp $POLYGLOT_SCENARIO_JARS tests/scenarios/polyglot-simple/Main.java
javac -g -cp $CHAT_SCENARIO_JARS tests/scenarios/chat/Server.java
javac -g -cp $JSOUP_SCENARIO_JARS tests/scenarios/jsoup/CraigslistMonitor.java
javac -g tests/scenarios/InstallCertFolder/InstallCert.java

# Run the command
java -cp $ALL_JARS $@
