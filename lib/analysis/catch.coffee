{ CatchTable } = require "../model/catch-table"
{ toControlStructure, TryCatchControlStructure, extractCtxRange, getControlStructureRanges } = require "../analysis/parse-tree"
{ isExceptionInList } = require "../event/missing-throws"
{ JavaParser } = require "../../lib/grammar/Java/JavaParser"


module.exports.CatchAnalysis = class CatchAnalysis

  constructor: (model) ->
    @model = model

  run: (callback, err) ->

    catchTable = new CatchTable()

    throwsTable = @model.getThrowsTable()
    parseTree = @model.getParseTree()

    for throwsRange in throwsTable.getRangesWithThrows()

      exceptions = throwsTable.getExceptions throwsRange
      statementCtx = parseTree.getCtxForRange throwsRange
      parentCtx = statementCtx

      # Starting at this range, look to see if a try-catch block has been
      # included that already handles the exception.
      while parentCtx?

        # Check to see if this node is actually a try-catch block
        tryCatch = toControlStructure parentCtx
        if tryCatch instanceof TryCatchControlStructure

          # Get the ranges associated with this try-catch block
          tryCatchRanges = getControlStructureRanges tryCatch

          # Traverse down to the exception names...
          catchClauseCtx = tryCatch.getCtx().children[2]
          for catchClauseChildCtx in catchClauseCtx.children

            if catchClauseChildCtx.ruleIndex == JavaParser.RULE_catchType
              catchTypeCtx = catchClauseChildCtx
              exceptionsCaught = []
              # Save all of the names of the exceptions thrown
              for catchTypeChildCtx in catchTypeCtx.children
                if (catchTypeChildCtx.ruleIndex == JavaParser.RULE_qualifiedName)
                  exceptionsCaught.push catchTypeChildCtx.getText()

              # Consider this handled if the method is in the 'try'
              # block and the catch lists that exception.
              catchTypeRange = extractCtxRange catchTypeCtx
              for exception in exceptions
                if (((throwsRange.compare catchTypeRange) < 0) and
                    (isExceptionInList exception, exceptionsCaught))
                  catchTable.addCatch throwsRange, tryCatchRanges[1]

        parentCtx = parentCtx.parentCtx

    callback catchTable
