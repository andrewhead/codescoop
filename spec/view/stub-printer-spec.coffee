{ StubPrinter } = require "../../lib/view/stub-printer"
{ StubSpec } = require "../../lib/model/stub"


describe "StubPrinter", ->

  stubPrinter = undefined
  beforeEach =>
    stubPrinter = new StubPrinter()

  it "prints out an empty class", ->
    stubSpec = new StubSpec "Stub"
    string = stubPrinter.printToString stubSpec
    (expect string).toEqual [
      "private class Stub {"
      "}"
      ""
    ].join "\n"

  it "prints out static classes if the static option is set", ->
    stubSpec = new StubSpec "Stub"
    string = stubPrinter.printToString stubSpec, { static: true }
    (expect string).toEqual [
      "private static class Stub {"
      "}"
      ""
    ].join "\n"

  it "prints fields with the first specified value", ->
    stubSpec = new StubSpec "Stub",
      fieldAccesses:
        i:
          type: "int"
          values: [42, 43]
    string = stubPrinter.printToString stubSpec
    (expect string).toEqual [
      "private class Stub {"
      "    "
      "    public int i = 42;"
      "    "
      "}"
      ""
    ].join "\n"

  it "prints a method with one returned value", ->
    stubSpec = new StubSpec "Stub",
      methodCalls: [
          signature:
            name: "method"
            returnType: "int"
            argumentTypes: ["int", "String"]
          returnValues: [42]
      ]
    string = stubPrinter.printToString stubSpec
    (expect string).toEqual [
      "private class Stub {"
      "    "
      "    public int method(int arg1, String arg2) {"
      "        return 42;"
      "    }"
      "    "
      "}"
      ""
    ].join "\n"

  it "prints a program that chooses values if there are multiple returns", ->
    stubSpec = new StubSpec "Stub",
      methodCalls: [
          signature:
            name: "method"
            returnType: "int"
            argumentTypes: []
          returnValues: [42, 43, 44]
      ]
    string = stubPrinter.printToString stubSpec
    (expect string).toEqual [
      "private class Stub {"
      "    "
      "    private int methodCallCount = 0;"
      "    "
      "    public int method() {"
      "        if (methodCallCount == 0) {"
      "            return 42;"
      "        } else if (methodCallCount == 1) {"
      "            return 43;"
      "        } else {"
      "            return 44;"
      "        }"
      "        methodCallCount += 1;"
      "    }"
      "    "
      "}"
      ""
    ].join "\n"

  it "skips methods and fields that don't have any return values or accesses", ->
    stubSpec = new StubSpec "Stub",
      fieldAccesses:
        i:
          type: "int"
          values: []
      methodCalls: [
          signature:
            name: "method"
            returnType: "int"
            argumentTypes: []
          returnValues: []
      ]
    string = stubPrinter.printToString stubSpec
    (expect string).toEqual [
      "private class Stub {"
      "}"
      ""
    ].join "\n"

  it "creates stubs accessed from other stubs", ->
    stubSpec = new StubSpec "Stub",
      fieldAccesses:
        object:
          type: "instance"
          values: [
            new StubSpec undefined,
              fieldAccesses:
                i:
                  type: "int"
                  values: [42]
          ]
      methodCalls: [
          signature:
            name: "method"
            returnType: "instance"
            argumentTypes: []
          returnValues: [
            new StubSpec undefined,
              fieldAccesses:
                i:
                  type: "int"
                  values: [43]
          ]
      ]
    string = stubPrinter.printToString stubSpec
    (expect string).toEqual [
      "private class Stub {"
      "    "
      "    public AnonymousClass1 object = new AnonymousClass1();"
      "    "
      "    public AnonymousClass2 method() {"
      "        return new AnonymousClass2();"
      "    }"
      "    "
      "}"
      ""
      "private class AnonymousClass1 {"
      "    "
      "    public int i = 42;"
      "    "
      "}"
      ""
      "private class AnonymousClass2 {"
      "    "
      "    public int i = 43;"
      "    "
      "}"
      ""
    ].join "\n"

  it "can print an object field with a null value", ->
    stubSpec = new StubSpec "Stub",
      fieldAccesses:
        object:
          type: "instance"
          values: [null]
    string = stubPrinter.printToString stubSpec
    (expect string).toEqual [
      "private class Stub {"
      "    "
      "    public Object object = null;"
      "    "
      "}"
      ""
    ].join "\n"

  it "prints string literals within quotes", ->
    stubSpec = new StubSpec "Stub",
      fieldAccesses:
        s:
          type: "String"
          values: ["Hello world"]
    string = stubPrinter.printToString stubSpec
    (expect string).toEqual [
      "private class Stub {"
      "    "
      "    public String s = \"Hello world\";"
      "    "
      "}"
      ""
    ].join "\n"

  it "escapes newlines and quotes in string literals", ->
    stubSpec = new StubSpec "Stub",
      fieldAccesses:
        s:
          type: "String"
          values: ["\"\n\""]
    string = stubPrinter.printToString stubSpec
    (expect string).toEqual [
      "private class Stub {"
      "    "
      "    public String s = \"\\\"\\n\\\"\";"
      "    "
      "}"
      ""
    ].join "\n"

  it "creates sub-types when a method returns multiple object instances", ->
    stubSpec = new StubSpec "Stub",
      methodCalls: [
          signature:
            name: "method"
            returnType: "instance"
            argumentTypes: []
          returnValues: [
            new StubSpec undefined,
              fieldAccesses:
                i:
                  type: "int"
                  values: [42]
            new StubSpec undefined,
              fieldAccesses:
                i:
                  type: "int"
                  values: [43]
          ]
      ]
    string = stubPrinter.printToString stubSpec
    (expect string).toEqual [
      "private class Stub {"
      "    "
      "    private int methodCallCount = 0;"
      "    "
      "    public AnonymousClass1 method() {"
      "        if (methodCallCount == 0) {"
      "            return new AnonymousClass1_1();"
      "        } else {"
      "            return new AnonymousClass1_2();"
      "        }"
      "        methodCallCount += 1;"
      "    }"
      "    "
      "}"
      ""
      "private class AnonymousClass1 {"
      "}"
      ""
      "private class AnonymousClass1_1 extends AnonymousClass1 {"
      "    "
      "    public int i = 42;"
      "    "
      "}"
      ""
      "private class AnonymousClass1_2 extends AnonymousClass1 {"
      "    "
      "    public int i = 43;"
      "    "
      "}"
      ""
    ].join "\n"

  it "doesn't create more stubs for null return values", ->
    stubSpec = new StubSpec "Stub",
      methodCalls: [
          signature:
            name: "method"
            returnType: "instance"
            argumentTypes: []
          returnValues: [
            new StubSpec undefined,
              fieldAccesses:
                i:
                  type: "int"
                  values: [42]
            null
          ]
      ]
    string = stubPrinter.printToString stubSpec
    (expect string).toEqual [
      "private class Stub {"
      "    "
      "    private int methodCallCount = 0;"
      "    "
      "    public AnonymousClass1 method() {"
      "        if (methodCallCount == 0) {"
      "            return new AnonymousClass1();"
      "        } else {"
      "            return null;"
      "        }"
      "        methodCallCount += 1;"
      "    }"
      "    "
      "}"
      ""
      "private class AnonymousClass1 {"
      "    "
      "    public int i = 42;"
      "    "
      "}"
      ""
    ].join "\n"

  it "comes up with distinct counters for overloaded methods", ->
    stubSpec = new StubSpec "Stub",
      methodCalls: [
          signature:
            name: "method"
            returnType: "int"
            argumentTypes: []
          returnValues: [1]
        ,
          signature:
            name: "method"
            returnType: "int"
            argumentTypes: ["int"]
          returnValues: [1, 2]
      ]
    string = stubPrinter.printToString stubSpec
    (expect string).toEqual [
      "private class Stub {"
      "    "
      "    private int method2CallCount = 0;"
      "    "
      "    public int method() {"
      "        return 1;"
      "    }"
      "    "
      "    public int method(int arg1) {"
      "        if (method2CallCount == 0) {"
      "            return 1;"
      "        } else {"
      "            return 2;"
      "        }"
      "        method2CallCount += 1;"
      "    }"
      "    "
      "}"
      ""
    ].join "\n"
