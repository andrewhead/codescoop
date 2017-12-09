{ fork } = require "child_process"
path = require "path"
_ = require "lodash"


# A nest map that maps a filename, line number, and variable name to the values
# that that variable took on on that line.
module.exports.ValueMap = class ValueMap


# While this currently relies on a Map loaded from Java using the node-java
# connector, it's reasonable to expect that this could also read in a
# pre-written local file instead.
module.exports.ValueAnalysis = class ValueAnalysis

  constructor: (file) ->
    @file = file

  run: (callback, err) ->

    # Run the value analysis in a completely different process.  This lets
    # us avoid starting a Java VM in the same process (which, for
    # this analysis, starts _2_ VMs!)  Running this analysis without forking
    # causes the "script" package to fail to launch.
    program = __dirname + "/value-analysis-worker.js"
    options = {
      stdio: [ "pipe", "pipe", "pipe", "ipc" ]
      execArgv: [ program, @file.getName(), @file.getPath() ]
    };
    child = fork program, [], options

    # If there was an error launching the worker, this will tell us.
    child.stderr.on 'data', (data) =>
      console.error "Error running value map worker:", String(data)

    # Have the worker
    child.on 'message', (result) =>
      if result.status == "error"
        err result.error
        return
      valueMap = new ValueMap()
      valueMap = _.merge valueMap, result.valueMap
      callback valueMap
