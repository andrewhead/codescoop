fs = require 'fs'

PACKAGE_PATH = atom.packages.resolvePackagePath 'examplify'

# Prepare the gateway to Java code for running static analysis
JAVA_CLASSPATH = []
JAVA_LIBS_DIR = PACKAGE_PATH + '/java/libs'
javaLibs = fs.readdirSync JAVA_LIBS_DIR
JAVA_CLASSPATH.push (PACKAGE_PATH + '/java')
JAVA_CLASSPATH.push()
javaLibs.forEach (libName) =>
  if (libName.endsWith '.jar')
    JAVA_CLASSPATH.push (JAVA_LIBS_DIR + '/' + libName)

# Sorry, you'll need to modify this for the Java home on your computer.
# I'm hard-coding it so I can do this fast locally
JAVA_HOME = "/Library/Java/JavaVirtualMachines/jdk1.7.0_67.jdk/Contents/Home"
jreLibs = fs.readdirSync (JAVA_HOME + '/jre/lib')
jreLibs.forEach (libName) =>
  if (libName.endsWith '.jar')
    JAVA_CLASSPATH.push (JAVA_HOME + '/jre/lib/' + libName)
JAVA_CLASSPATH.push (JAVA_HOME + '/lib/tools.jar')

module.exports =
  PACKAGE_PATH: PACKAGE_PATH
  JAVA_CLASSPATH: JAVA_CLASSPATH
