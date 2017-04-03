#! /bin/bash

WGET="wget -nc"

# Soot software and dependencies
$WGET http://www.sable.mcgill.ca/software/sootclasses-2.5.0.jar
$WGET http://www.sable.mcgill.ca/software/jasminclasses-2.5.0.jar
# $WGET http://www.sable.mcgill.ca/software/polyglotclasses-1.3.5.jar  # hard-coded into this repository

# JUnit (for unit tests)
$WGET https://github.com/junit-team/junit4/releases/download/r4.12/junit-4.12.jar
$WGET http://search.maven.org/remotecontent?filepath=org/hamcrest/hamcrest-core/1.3/hamcrest-core-1.3.jar -O hamcrest-core-1.3.jar

# Reflections (for imports analysis)
$WGET https://search.maven.org/remotecontent?filepath=org/reflections/reflections/0.9.11/reflections-0.9.11.jar -O reflections-0.9.11.jar
$WGET https://search.maven.org/remotecontent?filepath=com/google/guava/guava/20.0/guava-20.0.jar -O guava-20.0.jar
$WGET https://search.maven.org/remotecontent?filepath=org/javassist/javassist/3.21.0-GA/javassist-3.21.0-GA.jar -O javassist-3.21.0-GA.jar
