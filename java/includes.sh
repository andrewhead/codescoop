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
