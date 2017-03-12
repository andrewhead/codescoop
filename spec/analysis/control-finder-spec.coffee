{ parse } = require '../../lib/analysis/parse-tree'
{ Range } = require '../../lib/model/range-set'
{ File, Symbol } = require '../../lib/model/symbol-set'
{ JavaParser } = require '../../lib/grammar/Java/JavaParser'

JAVA_CODE = [
  "public class Example {"
  "  public static void main(String[] args) {"
  "    if (true) {"
  "      int i = 1;"
  "    }"
  "  }"
  "}"
].join "\n"

fdescribe 'control-finder', ->
  it 'walks upward from node to control node', ->
    parseTree = parse JAVA_CODE
    console.log parseTree
