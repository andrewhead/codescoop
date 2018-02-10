# CodeScoop Online Demo

This is the version of CodeScoop that is has been re-written
to be deployed as a demo on a server.

The main change for the demo is that the results of analyses
that used to be run in Java code are now precomputed.  This
makes the CodeScoop plugin easier to port to another
machine.  It also means that the demo server can support
more simultaneous users, as running some of the Java analyses
could take a few seconds of time.

## Setup instructions

This plugin has been reworked to fit into
[atom-in-orbit](https://github.com/facebook-atom/atom-in-orbit),
a wrapper around GitHub Atom that lets Atom run in the
browser.  Follow the instructions to set up atom-in-orbit,
which includes downloading an old version of Atom.

### Tweaking GitHub Atom dependencies

We'll tweak a GitHub Atom build so that it depends on the
CodeScoop project.

First, a little cleanup.  You should have cloned [GitHub
Atom repository](https://github.com/atom/atom) and checked
out the version against which atom-in-orbit could be built.
There are some broken dependencies in this version.  Fix
these broken dependencies as follows.  In `package.json`,
remove the `packageDependencies` entries for
`autocomplete-plus`, `find-and-replace`, `settings-view`,
and `tree-view`.  Then, add these replacement entries to the
list of `dependencies`.

```json
    "find-and-replace": "atom/find-and-replace#v0.204.0",
    "tree-view": "atom/tree-view#v0.211.1",
    "autocomplete-plus": "atom/autocomplete-plus#v2.33.1",
    "settings-view": "atom/settings-view#v0.244.0",
```

Then, add entries to the `dependencies` for the CodeScoop
plugin:

```json
    "codescoop": "andrewhead/codescoop#online-demo",
    "atom-script": "andrewhead/atom-script"
```

Run `npm install` and `apm install` within the Atom
directory before trying to build atom-in-orbit.

### Updating dependencies for atom-in-orbit

Then change directory into your local directory for the
atom-in-orbit repository.

We need to make sure atom-in-orbit knows to include the
CodeScoop plugin too.  Go to the definition of
`atomPackages` in `scripts/build.js`, and make sure the
following entries are in the list of dependencies:

```javascript
    'codescoop',
    'atom-script',
    'language-java',
```

Then, follow the instructions from the repository for
building and launching the project.

### TODO: Downloading the test files

### Enabling the demos

Download the following JARs to a directory on your machine,
and add each of the JARs to your Java classpath:

* [Database API](https://github.com/andrewhead/codescoop/releases/download/jars/database.jar)
* [Javax Mail Library](https://github.com/andrewhead/codescoop/releases/download/jars/javax.mail-1.4.7.jar)
* [Jsoup Library](https://github.com/andrewhead/codescoop/releases/download/jars/jsoup-jdk-1.4.jar)

#### Scraping / Emailing Demo

Add an `/etc/smtp.conf`  to the machine so emails can be
sent out when someone tests the emailing program.  If you
are deploying this as a demo, only put credentials for a
throwaway account in this file!  The username and password
will be visible in the demo.  The first line should be a
GMail username, and the second line should be the password
for that account.

## Using the tool

There are a couple files that you can make examples from:

* `QueryDatabase.java`: based on a code example from a
  formative study.  Uses a fake cursor-based database API.
* `ScrapeAndEmail.java`: uses Jsoup to fetch and parse web
  page content, uses a file reader API to read credentials
  from a file, and uses a javax.mail to send a digest of
  the web page contents to an email address.

Object "stubs" is only enabled for `QueryDatabase.java`
