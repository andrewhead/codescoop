# CodeScoop

This is the code for the prototype system "CodeScoop", from the CHI paper, ["Interactive Extraction of Examples from Existing Code"](https://people.eecs.berkeley.edu/~andrewhead/pdf/example_extraction.pdf).

Want to try out the tool but don't want to set up the project dependencies? Try out the [online demo](https://codescoop.berkeley.edu/)!.

## Getting Started

### Download GitHub Atom text editor

CodeScoop is built as an add-on for the GitHub
Atom text editor.
Download and install Atom text editor from the 
download link on the Atom home page
[here](https://atom.io/).

### Download Java 1.7

Currently, the tool depends on Java 1.7 for running Soot
static analyses and for connecting to Java through the
`node-java` package.  You can download Java 1.7 from the 
Oracle website.

After installing the JDK, your `JAVA_HOME` environment variable
should point to Java 1.7 instead of another version of Java.
On OSX, you can do this by adding a line like this to your
`~/.bashrc` set the `JAVA_HOME` to 1.7.

```bash
export JAVA_HOME=`/usr/libexec/java_home -v 1.7`
```

If you're using OSX, you will also need to create a few symbolic
links so that Soot can find the class definitions it expects (see 
https://github.com/Sable/soot/issues/686 for context):

```bash
cd $JAVA_HOME
sudo mkdir Classes
cd Classes/
sudo ln -s ../jre/lib/rt.jar classes.jr
sudo ln -s ../jre/lib/rt.jar ui.jar
```

### Install the CodeScoop plugin in Atom

Clone this repository locally, and install its dependencies:

```bash
git clone https://github.com/andrewhead/codescoop.git codescoop

cd codescoop/
npm install      # install Node dependencies

cd java/libs/
./fetch_libs.sh  # install Java dependencies (e.g., Soot, etc.)
```

Then compile the analysis code written in Java:

```bash
cd java/        # run this from the main `codescoop` directory
./build.sh
```

Then, install CodeScoop as an Atom plugin:

```bash
apm link
```

### Additional Dependencies

CodeScoop depends on several third-party plugins.  Install them as follows:

#### "Script" plugin

"Script" lets you compile and run Java within Atom.  We made a fork
of the `script` package with the right text sizing and with a
tweaks to the Java classpath argument.  Clone the repository and
install the plugin:

```bash
git clone https://github.com/andrewhead/atom-script
cd atom-script
npm install
apm link
```

#### Event logger plugin

You don't need this to run CodeScoop, but you might need it if
you want to log the user interactions.  If so, install this plugin
with these commands:

```bash
git clone https://github.com/andrewhead/atom-event-logger
cd atom-event-logger
npm install
apm link
```

## Using CodeScoop

Once you have installed CodeScoop, you can test it out on
a few source programs from the repository.

Open up one of these files in Atom:

* `tests/scenarios/database-use/BookListing.java`: based on
    a code example from a formative study.  Uses a synthetic
    cursor-based database API.
* `tests/scenarios/jsoup/CraigslistMonitor.java`: uses Jsoup
    to fetch and parse web page content, uses a file reader
    API to read credentials from a file, and uses a
    javax.mail to send a digest of the web page contents to
    an email address.

Each of these files may have specific setup instructions.
If there are special setup instructions, they are specified
in the `README.md` file for that `.java` file.  For some of
programs (`CraigslistMonitor.java`), you should
disable stub analysis, as it takes a long time to run for
programs with lots of complex objects.  To disable stub
analysis, comment out the line in `examplify.coffee` that reads:

```coffeescript
      stubAnalysis: new StubAnalysis codeEditorFile
```

If you update the `examplify.coffee` file, make sure to
reload the plugin by refreshing Atom (`Cmd-Ctrl-Option-L`).

Now, it's time to create an example!  Once you have opened
the `.java` file you want to extract code from, select a line
or lines that constitute the pattern you want to share.  Right click
in the editor, and choose the item "Create example from
selection" in the context menu.

Depending on the Java file you're working with, CodeScoop will take a
few seconds (up to 30 seconds) to analyze the code
before you can interact with it.

## Contributing to CodeScoop

### Running the unit tests

#### Running the Java tests

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

### Changing the Java code

If you like to use `vi` to edit the Java code, consider
using the `editjava` script in the `java/` directory.  This
sets up the class path to include all of the dependencies
before starting `vi`, in case you have an integrated Linter
and want to make sure it notices all your dependencies.

If you edit any of the Java files, you will
need to recompile them to see the changes take effect:

```bash
cd java/    # call this from the main directory
./build.sh
```

If Atom was already open, you should probably reload the
CodeScoop plugin (`Cmd-Ctrl-Opt-L`).

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

#### Version mismatch problem

You may need to rebuild project dependencies if you see a version mismatch error in the Atom console.  You can do this with a command like:

```bash
npm rebuild --runtime=electron --target=1.3.4 --disturl=https://atom.io/download/atom-shell --abi=49
```

where `1.3.4` is your electron version and `49` is the abi it's expecting. For more context, see https://github.com/electron-userland/electron-builder/issues/453)

#### VM launch issues

If a Java VM fails to launch when using CodeScoop, you may have to update
your `/etc/hosts` file to redirect your machine's host name to
the localhost address of `127.0.0.1`  Here's an example of an
`/etc/hosts` file that works for one of the contributors to this project.

```
127.0.0.1	localhost
255.255.255.255	broadcasthost
::1             localhost.localdomain   localhost
::1             My-MacBook-Pro.local
127.0.0.1	My-MacBook-Pro.local
```
