###
The 'java' module should be imported from this file.
This way we can configure the classpath for the module only once
(If we configure it more than once, it complains.)
###
fs = require "fs"
path = require "path"

PACKAGE_PATH = __dirname + "/../.."

loadJson = (className, dataName, callback) =>
  filePath = path.join PACKAGE_PATH, "cache", className, dataName + ".json"
  fs.readFile filePath, (error, data) =>
    (callback error) if error
    callback undefined, (JSON.parse data)

module.exports =
  PACKAGE_PATH: PACKAGE_PATH
  loadJson: loadJson
