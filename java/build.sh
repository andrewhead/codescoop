#! /bin/bash

source includes.sh

# Compile all analysis classes
javac -g -cp $JUNIT_JARS:$SOOT_JARS:$JDI_JARS:$REFLECTIONS_JARS:. *.java

# Compile all unit tests
javac -g -cp $JUNIT_JARS:$SOOT_JARS:$JDI_JARS:$REFLECTIONS_JARS:. tests/*.java

# Compile classes for all of the files we're going to run test analysis on
# Use `-g` so we get symbol information, for extracting variable names during analysis.

# This includes short examples that are used in the unit tests...
javac -g tests/analysis_examples/*.java

# And "scenario" files used as starting points for example creation
javac -g -cp $SOOT_JARS:$JDI_JARS tests/scenarios/examplify/*.java
javac -g -cp $CHAT_SCENARIO_JARS tests/scenarios/chat/Server.java
javac -g -cp $DATABASE_SCENARIO_JARS tests/scenarios/database-use/BookListing.java
javac -g -cp $DATABASE_SCENARIO_JARS tests/scenarios/database-use/MySpaghettiCode.java
javac -g -cp $POLYGLOT_SCENARIO_JARS tests/scenarios/polyglot-simple/Main.java
javac -g -cp $CHAT_SCENARIO_JARS tests/scenarios/chat/Server.java
javac -g -cp $JSOUP_SCENARIO_JARS tests/scenarios/jsoup/CraigslistMonitor.java
javac -g tests/scenarios/tutorial/RandomExponents.java
javac -g tests/scenarios/tutorial/SillyDictionaryBuilder.java
javac -g tests/scenarios/InstallCertFolder/InstallCert.java
