# Examplify

## Installation

### Java 1.7

The only workable configuration I have found for satisfying
Soot and the Node `java` packages is to have JDK version 1.7
as the primary Java VM.  Check out installation instructions
specific to your OS for getting this version.

Your `JAVA_HOME` environment variable should be set to point
to Java 1.7.  On OSX, you can add a line like this to your
`~/.bashrc` set the `JAVA_HOME` to 1.7.

```bash
export JAVA_HOME=`/usr/libexec/java_home -v 1.7`
```

On OSX, you need to add a few symbolic links so that Soot
gets the class definitions it expects:

```bash
cd $JAVA_HOME
sudo mkdir Classes
cd Classes/
sudo ln -s ../jre/lib/rt.jar classes.jr
sudo ln -s ../jre/lib/rt.jar ui.jar
```

See https://github.com/Sable/soot/issues/686 for details on the
hack we are following.

### Adding the Examplify plugin to Atom

First, download and install the GitHub Atom text editor.
There should be a download link on the Atom home page
[here](https://atom.io/).

Then clone this repository.  `cd` into the repository's main
directory, and install all of the Node dependencies for the
package by running

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

You will also need to compile all of the Java analyses once
before the plugin can run correctly.  To do this, you can
run the `build.sh` script:

```bash
cd java/  # run this from the main directory
./build.sh
```

Last, install the Examplify plugin into Atom by running this
command in the main folder:

```bash
apm link
```

### Adding the Script package to Atom

This lets you compile and run Java from Atom.  We made a fork
of the `script` package with the right text sizing and with a
tweaks to the Java classpath argument.

To clone the repository and install the package, do this:

```bash
git clone https://github.com/andrewhead/atom-script
cd atom-script
npm install
apm link
```

### Adding the Atom clock to Atom

This is important for being able to trace study video back
to log data.  Install the `atom-clock` package in Atom
(go to Preferences->Install->type in query "atom-clock").  In
the preferences for the package, set the format to 
`MMMM Do, dddd, h:mm:ss a`.

## Using Examplify

This step assumes that you have already followed all of the
installation instructions.

If this is your first time using Examplify, or if you have
changed the contents of the source code files that you want
to create examples from, you should rebuild the Java code
and source code files.

```bash
cd java/
./build.sh
```

If Atom was already open, you should probably reload the
Examplify plugin (`Cmd-Ctrl-Opt-L`).

Then, open the file you want to create an example from in
Atom.  Select a line or lines of text that you want to
create an example out of.  Right click in the editor, and
choose the item "Create example from selection" in the
context menu.

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

Each of these files may have specific setup instructions.
For example, for `CraigslistMonitor.java`, you need to add a
`/etc/smtp.conf` file to your machine.  If there are special
setup instructions, they are specified in the `README.md`
file in the directory with the `.java` file.

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
with the following caveats/substitutions:
1. Substitute `Example` with the name of your `.java` file
(though omit the `.java` extension).  
2. This file will need to be placed in the same directory as the one that you
are running the command.  

Explanation of those less readable options:
* `-src-prec java`: runs Soot on a `.java` file instead of a
    `.class` file
* `-f J`: produces a Jimple IR file (instead of a class)

### Editing Java code

If you like to use `vi` to edit the Java code, consider
using the `editjava` script in the `java/` directory.  This
sets up the class path to include all of the dependencies
before starting `vi`, in case you have an integrated Linter
and want to make sure it notices all your dependencies.

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
* BookListing: `Elenas-MacBook-Pro:java elenaglassman$ ./runclass.sh PrimitiveValueAnalysis tests/scenarios/database-use/ BookListing`

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
