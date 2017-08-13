# Examplify

Make useful example code from your existing code.

## Using Examplify

Select a line or lines of text that you want to create an
example out of.  Right click in the editor, and choose the
item "Create example from selection" in the context menu.

You may have to wait up to 30 seconds for the Java analysis
to complete before you can start finishing the examples.
Performance improvements to come soon?

Currently, there are a few files that you can make examples
out of.

* `tests/scenarios/database-use/BookListing.java`: based on
    a code example from a formative study.  Uses a fake
    cursor-based database access API.
* `tests/scenarios/jsoup/CraigslistMonitor.java`: uses Jsoup
    to fetch and parse web page content, uses a file reader
    API to read credentials from a file, and uses a
    javax.mail to send a digest of the web page contents to
    an email address.

**For some of these (`CraigslistMonitor.java`), you should
disable stub analysis**, as it takes prohibitively long to
run (way longer than a few minutes).  To disable stub
analysis, comment out this line in `examplify.coffee`.  The
line to comment looks like:

```coffeescript
      stubAnalysis: new StubAnalysis codeEditorFile
```

and after you comment it, it should look like:

```coffeescript
      # stubAnalysis: new StubAnalysis codeEditorFile
```

Remember that you should reload Atom (`Cmd-Ctrl-Option-L`)
after making changes to the `examplify.coffee` file for stub
analysis to be disabled.

## Annoying, brittle installation requirements

### Platform requirements

The only workable configuration I have found for satisfying
Soot and the Node `java` packages is to have JDK version 1.7
as the primary Java VM.

With our version of Java 1.7, we needed to add a few symbolic
links so that Soot gets the class definitions it expects:

```bash
cd $JAVA_HOME
sudo mkdir Classes
cd Classes/
sudo ln -s ../jre/lib/rt.jar classes.jr
sudo ln -s ../jre/lib/rt.jar ui.jar
```

See https://github.com/Sable/soot/issues/686 for details on the
hack we are following.

### Installation instructions

Start out by installing all of the Node dependencies for the
package by running

```bash
npm install
```
in the `examplify` folder.

This project requires Soot, a static analysis tool, to run.
The classes for Soot are stored in a pretty large JAR.  It's
not included in the repository, so for right now, you can
run this helper script to fetch the dependencies.

```bash
cd java/libs
./fetch_libs.sh
```

You will also need to compile all of the Java analyses once
before the plugin can run correctly.  To do this, you can
run the `runtests.sh` script (see below).

Install into Atom our local Examplify package by running
```bash
apm link
```
in examplify folder.

## Developing

### Java tests

To make sure that the static analysis code is working properly:

```bash
cd java/
./runtests.sh
```

### Coffeescript tests

`Cmd-Shift-p` in Atom, type `specs` into window, and choose `run package specs`

### Running Soot

After following the dependency instructions above, you should
be able to run [Soot](https://github.com/Sable/soot) to
generate intermediate representation.  To run soot, use the
following commands:

```bash
CLASSPATH=$JAVA_HOME/jre/lib/rt.jar:libs/*:. java soot.Main Example -src-prec java -f J
```

Substitute `Example` with the name of your `.java` file
(though omit the `.java` extension).  This file will need to
be placed in the same directory as the one that you are
running the command.  The options do the following:
* `-src-prec java`: runs Soot on a `.java` file instead of a
    `.class` file
* `-f J`: produces a Jimple IR file (instead of a class)

### Style Guide

When possible, I use this style guide for Coffeescript:
https://github.com/polarmobile/coffeescript-style-guide

#### Equality checks

When implementing equality checks, call the method `equals`.
The method should take in another object as a parameter and
return a Boolean of whether the two objects are equal.

#### Accessors

Members of an object should only be accessed by other
objects through accessors (`get` methods).

#### Enums

When defining enums, define each field as an object.  This
make comparisons with an equals sign use values that are
exclusive to each class, instead of comparing just on the
fields of the object.

### Troubleshooting

#### Refresh atom

Ctrl-Option-Command-l (lowercase L)

#### When running specs on examplify in Atom

* If all else fails you need to install your packages and then run `npm rebuild --runtime=electron --target=1.3.4 --disturl=https://atom.io/download/atom-shell --abi=49` where 1.3.4 is your electron version and 49 is the abi it's expecting. (Source: https://github.com/electron-userland/electron-builder/issues/453)

#### Compiling example code

* InstallCert: Compile code with debug flags, e.g., `javac -g tests/scenarios/InstallCertFolder/InstallCert.java`
* Chat Client: Don't forget to specify the classpath when compiling with debug flags, e.g., `CLASSPATH=tests/scenarios/Basic-Java-Instant-Messenger/IMClient/src/ javac -g tests/scenarios/Basic-Java-Instant-Messenger/IMClient/src/ClientTest.java`
* Polyglot: `./runclass.sh PrimitiveValueAnalysis libs/polyglot.jar:libs/java_cup.jar:libs/pao.jar:tests/scenarios/polyglot-simple/ Main` and `./runclass.sh PrimitiveValueAnalysis tests/scenarios/polyglot-simple/ Main`

#### Dealing with bad VM launch

Try some `/etc/hosts` entries like this:
```
##
# Host Database
#
# localhost is used to configure the loopback interface
# when the system is booting.  Do not change this entry.
##
127.0.0.1	localhost
255.255.255.255	broadcasthost
::1             localhost.localdomain   localhost
::1             Elenas-MacBook-Pro.local
127.0.0.1	Elenas-MacBook-Pro.local
```
