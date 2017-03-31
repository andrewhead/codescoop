{ TypeDefUseAnalysis } = require "../../lib/analysis/type-def-use"
{ TypeUseFinder, TypeDefFinder } = require "../../lib/analysis/type-def-use"
{ File, Symbol } = require "../../lib/model/symbol-set"
{ parse } = require "../../lib/analysis/parse-tree"
{ Range } = require "../../lib/model/range-set"


describe "TypeDefUseAnalysis", ->

  it "calls a callback with the defs and uses found once finished", ->
    testFile = new File "path", "filename"
    code = [
      "public class Book {"
      "  Book otherBook;"
      "}"
    ].join "\n"
    parseTree = parse code
    analysis = new TypeDefUseAnalysis testFile, parseTree
    analysis.run (result) =>
      uses = result.typeUses
      defs = result.typeDefs
      (expect uses.length).toBe 1
      (expect uses[0].getRange()).toEqual new Range [1, 2], [1, 6]
      (expect defs.length).toBe 1
      (expect defs[0].getRange()).toEqual new Range [0, 13], [0, 17]


describe "TypeUseFinder", ->

  testFile = new File "path", "filename"
  typeUseFinder = new TypeUseFinder testFile

  _checkForOneTypeSymbol = (parseTree, symbolName, range) =>
    typeUses = typeUseFinder.findTypeUses parseTree
    (expect typeUses.length).toBe 1
    (expect typeUses[0]).toEqual \
      new Symbol testFile, symbolName, range, "Class"

  it "finds classes in variable declarations within methods", ->
    parseTree = parse [
      "public class Book {"
      "  public void method() {"
      "    Book anotherBook;"
      "  }"
      "}"
    ].join "\n"
    _checkForOneTypeSymbol parseTree, "Book", new Range [2, 4], [2, 8]

  it "finds classes in object initializations", ->
    parseTree = parse [
      "public class Book {"
      "  public void method() {"
      "    new Book();"
      "  }"
      "}"
    ].join "\n"
    _checkForOneTypeSymbol parseTree, "Book", new Range [2, 8], [2, 12]

  it "finds classes in variable declarations in for loop control", ->
    parseTree = parse [
      "public class Book {"
      "  public void method() {"
      "    for (Book book: this.getBooks()) {}"
      "  }"
      "}"
    ].join "\n"
    _checkForOneTypeSymbol parseTree, "Book", new Range [2, 9], [2, 13]

  it "finds classes in variable declarations in for loop enhanced control", ->
    parseTree = parse [
      "public class Book {"
      "  public void method() {"
      "    for (Book book = null;;) {}"
      "  }"
      "}"
    ].join "\n"
    _checkForOneTypeSymbol parseTree, "Book", new Range [2, 9], [2, 13]

  it "finds classes in declarations of class fields", ->
    parseTree = parse [
      "public class Book {"
      "  private Book anotherBook;"
      "}"
    ].join "\n"
    _checkForOneTypeSymbol parseTree, "Book", new Range [1, 10], [1, 14]

  it "finds classes in method parameter lists", ->
    parseTree = parse [
      "public class Book {"
      "  public void compareTo(Book book) {}"
      "}"
    ].join "\n"
    _checkForOneTypeSymbol parseTree, "Book", new Range [1, 24], [1, 28]

  it "finds classes in method return values", ->
    parseTree = parse [
      "public class Book {"
      "  public Book findBook() { return null; }"
      "}"
    ].join "\n"
    _checkForOneTypeSymbol parseTree, "Book", new Range [1, 9], [1, 13]

  it "finds classes in cast operations", ->
    parseTree = parse [
      "public class Book {"
      "  public void method() {"
      "    (Book) null;"
      "  }"
      "}"
    ].join "\n"
    _checkForOneTypeSymbol parseTree, "Book", new Range [2, 5], [2, 9]

  it "finds classes in \"extends\" clauses", ->
    parseTree = parse [
      "public class SuperBook extends Book {}"
    ].join "\n"
    _checkForOneTypeSymbol parseTree, "Book", new Range [0, 31], [0, 35]

  it "finds classes in \"implements\" clauses", ->
    parseTree = parse [
      "public class Book implements IBook {}"
    ].join "\n"
    _checkForOneTypeSymbol parseTree, "IBook", new Range [0, 29], [0, 34]

  it "finds classes in `throws` clauses", ->
    parseTree = parse [
      "public class Book {"
      "  public void method() throws IOException {}"
      "}"
    ].join "\n"
    _checkForOneTypeSymbol parseTree, "IOException", new Range [1, 30], [1, 41]

  it "doesn't mark Strings, objects, or primitives as a class use", ->
    parseTree = parse [
      "public class Book {"
      "  String s;"
      "  Object o;"
      "  int i;"
      "}"
    ].join "\n"
    typeUses = typeUseFinder.findTypeUses parseTree
    (expect typeUses.length).toBe 0


# At some point, it might be useful for TypeDefFinder to find classes
# that are loaded dynamically.  We expect this will happen infrequently enough
# that I'm not going to handle it here.
describe "TypeDefFinder", ->

  testFile = new File "path", "filename"
  typeDefFinder = new TypeDefFinder testFile

  _checkForOneTypeSymbol = (parseTree, symbolName, range) =>
    typeDefs = typeDefFinder.findTypeDefs parseTree
    (expect typeDefs.length).toBe 1
    (expect typeDefs[0]).toEqual \
      new Symbol testFile, symbolName, range, "Class"

  it "finds class definitions in class declarations", ->
    parseTree = parse "public class Book {}"
    _checkForOneTypeSymbol parseTree, "Book", new Range [0, 13], [0, 17]

  it "finds class definitions in inner class declarations", ->
    parseTree = parse [
      "public class Book {"
      "  private class InnerBook {}"
      "}"
    ].join "\n"
    defs = typeDefFinder.findTypeDefs parseTree
    symbolInnerBook = (defs.filter (d) => d.getName() is "InnerBook")[0]
    (expect symbolInnerBook.getRange()).toEqual new Range [1, 16], [1, 25]

  it "finds class definitions in interface declarations", ->
    parseTree = parse "public interface IBook {}"
    _checkForOneTypeSymbol parseTree, "IBook", new Range [0, 17], [0, 22]

  it "finds class definitions in enum declarations", ->
    parseTree = parse "public enum BookType {}"
    _checkForOneTypeSymbol parseTree, "BookType", new Range [0, 12], [0, 20]
