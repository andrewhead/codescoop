// Generated from Java.g4 by ANTLR 4.5
// jshint ignore: start
var antlr4 = require('antlr4/index');

// This class defines a complete generic visitor for a parse tree produced by JavaParser.

function JavaVisitor() {
	antlr4.tree.ParseTreeVisitor.call(this);
	return this;
}

JavaVisitor.prototype = Object.create(antlr4.tree.ParseTreeVisitor.prototype);
JavaVisitor.prototype.constructor = JavaVisitor;

// Visit a parse tree produced by JavaParser#compilationUnit.
JavaVisitor.prototype.visitCompilationUnit = function(ctx) {
};


// Visit a parse tree produced by JavaParser#packageDeclaration.
JavaVisitor.prototype.visitPackageDeclaration = function(ctx) {
};


// Visit a parse tree produced by JavaParser#importDeclaration.
JavaVisitor.prototype.visitImportDeclaration = function(ctx) {
};


// Visit a parse tree produced by JavaParser#typeDeclaration.
JavaVisitor.prototype.visitTypeDeclaration = function(ctx) {
};


// Visit a parse tree produced by JavaParser#modifier.
JavaVisitor.prototype.visitModifier = function(ctx) {
};


// Visit a parse tree produced by JavaParser#classOrInterfaceModifier.
JavaVisitor.prototype.visitClassOrInterfaceModifier = function(ctx) {
};


// Visit a parse tree produced by JavaParser#variableModifier.
JavaVisitor.prototype.visitVariableModifier = function(ctx) {
};


// Visit a parse tree produced by JavaParser#classDeclaration.
JavaVisitor.prototype.visitClassDeclaration = function(ctx) {
};


// Visit a parse tree produced by JavaParser#typeParameters.
JavaVisitor.prototype.visitTypeParameters = function(ctx) {
};


// Visit a parse tree produced by JavaParser#typeParameter.
JavaVisitor.prototype.visitTypeParameter = function(ctx) {
};


// Visit a parse tree produced by JavaParser#typeBound.
JavaVisitor.prototype.visitTypeBound = function(ctx) {
};


// Visit a parse tree produced by JavaParser#enumDeclaration.
JavaVisitor.prototype.visitEnumDeclaration = function(ctx) {
};


// Visit a parse tree produced by JavaParser#enumConstants.
JavaVisitor.prototype.visitEnumConstants = function(ctx) {
};


// Visit a parse tree produced by JavaParser#enumConstant.
JavaVisitor.prototype.visitEnumConstant = function(ctx) {
};


// Visit a parse tree produced by JavaParser#enumBodyDeclarations.
JavaVisitor.prototype.visitEnumBodyDeclarations = function(ctx) {
};


// Visit a parse tree produced by JavaParser#interfaceDeclaration.
JavaVisitor.prototype.visitInterfaceDeclaration = function(ctx) {
};


// Visit a parse tree produced by JavaParser#typeList.
JavaVisitor.prototype.visitTypeList = function(ctx) {
};


// Visit a parse tree produced by JavaParser#classBody.
JavaVisitor.prototype.visitClassBody = function(ctx) {
};


// Visit a parse tree produced by JavaParser#interfaceBody.
JavaVisitor.prototype.visitInterfaceBody = function(ctx) {
};


// Visit a parse tree produced by JavaParser#classBodyDeclaration.
JavaVisitor.prototype.visitClassBodyDeclaration = function(ctx) {
};


// Visit a parse tree produced by JavaParser#memberDeclaration.
JavaVisitor.prototype.visitMemberDeclaration = function(ctx) {
};


// Visit a parse tree produced by JavaParser#methodDeclaration.
JavaVisitor.prototype.visitMethodDeclaration = function(ctx) {
};


// Visit a parse tree produced by JavaParser#genericMethodDeclaration.
JavaVisitor.prototype.visitGenericMethodDeclaration = function(ctx) {
};


// Visit a parse tree produced by JavaParser#constructorDeclaration.
JavaVisitor.prototype.visitConstructorDeclaration = function(ctx) {
};


// Visit a parse tree produced by JavaParser#genericConstructorDeclaration.
JavaVisitor.prototype.visitGenericConstructorDeclaration = function(ctx) {
};


// Visit a parse tree produced by JavaParser#fieldDeclaration.
JavaVisitor.prototype.visitFieldDeclaration = function(ctx) {
};


// Visit a parse tree produced by JavaParser#interfaceBodyDeclaration.
JavaVisitor.prototype.visitInterfaceBodyDeclaration = function(ctx) {
};


// Visit a parse tree produced by JavaParser#interfaceMemberDeclaration.
JavaVisitor.prototype.visitInterfaceMemberDeclaration = function(ctx) {
};


// Visit a parse tree produced by JavaParser#constDeclaration.
JavaVisitor.prototype.visitConstDeclaration = function(ctx) {
};


// Visit a parse tree produced by JavaParser#constantDeclarator.
JavaVisitor.prototype.visitConstantDeclarator = function(ctx) {
};


// Visit a parse tree produced by JavaParser#interfaceMethodDeclaration.
JavaVisitor.prototype.visitInterfaceMethodDeclaration = function(ctx) {
};


// Visit a parse tree produced by JavaParser#genericInterfaceMethodDeclaration.
JavaVisitor.prototype.visitGenericInterfaceMethodDeclaration = function(ctx) {
};


// Visit a parse tree produced by JavaParser#variableDeclarators.
JavaVisitor.prototype.visitVariableDeclarators = function(ctx) {
};


// Visit a parse tree produced by JavaParser#variableDeclarator.
JavaVisitor.prototype.visitVariableDeclarator = function(ctx) {
};


// Visit a parse tree produced by JavaParser#variableDeclaratorId.
JavaVisitor.prototype.visitVariableDeclaratorId = function(ctx) {
};


// Visit a parse tree produced by JavaParser#variableInitializer.
JavaVisitor.prototype.visitVariableInitializer = function(ctx) {
};


// Visit a parse tree produced by JavaParser#arrayInitializer.
JavaVisitor.prototype.visitArrayInitializer = function(ctx) {
};


// Visit a parse tree produced by JavaParser#enumConstantName.
JavaVisitor.prototype.visitEnumConstantName = function(ctx) {
};


// Visit a parse tree produced by JavaParser#typeType.
JavaVisitor.prototype.visitTypeType = function(ctx) {
};


// Visit a parse tree produced by JavaParser#classOrInterfaceType.
JavaVisitor.prototype.visitClassOrInterfaceType = function(ctx) {
};


// Visit a parse tree produced by JavaParser#primitiveType.
JavaVisitor.prototype.visitPrimitiveType = function(ctx) {
};


// Visit a parse tree produced by JavaParser#typeArguments.
JavaVisitor.prototype.visitTypeArguments = function(ctx) {
};


// Visit a parse tree produced by JavaParser#typeArgument.
JavaVisitor.prototype.visitTypeArgument = function(ctx) {
};


// Visit a parse tree produced by JavaParser#qualifiedNameList.
JavaVisitor.prototype.visitQualifiedNameList = function(ctx) {
};


// Visit a parse tree produced by JavaParser#formalParameters.
JavaVisitor.prototype.visitFormalParameters = function(ctx) {
};


// Visit a parse tree produced by JavaParser#formalParameterList.
JavaVisitor.prototype.visitFormalParameterList = function(ctx) {
};


// Visit a parse tree produced by JavaParser#formalParameter.
JavaVisitor.prototype.visitFormalParameter = function(ctx) {
};


// Visit a parse tree produced by JavaParser#lastFormalParameter.
JavaVisitor.prototype.visitLastFormalParameter = function(ctx) {
};


// Visit a parse tree produced by JavaParser#methodBody.
JavaVisitor.prototype.visitMethodBody = function(ctx) {
};


// Visit a parse tree produced by JavaParser#constructorBody.
JavaVisitor.prototype.visitConstructorBody = function(ctx) {
};


// Visit a parse tree produced by JavaParser#qualifiedName.
JavaVisitor.prototype.visitQualifiedName = function(ctx) {
};


// Visit a parse tree produced by JavaParser#literal.
JavaVisitor.prototype.visitLiteral = function(ctx) {
};


// Visit a parse tree produced by JavaParser#annotation.
JavaVisitor.prototype.visitAnnotation = function(ctx) {
};


// Visit a parse tree produced by JavaParser#annotationName.
JavaVisitor.prototype.visitAnnotationName = function(ctx) {
};


// Visit a parse tree produced by JavaParser#elementValuePairs.
JavaVisitor.prototype.visitElementValuePairs = function(ctx) {
};


// Visit a parse tree produced by JavaParser#elementValuePair.
JavaVisitor.prototype.visitElementValuePair = function(ctx) {
};


// Visit a parse tree produced by JavaParser#elementValue.
JavaVisitor.prototype.visitElementValue = function(ctx) {
};


// Visit a parse tree produced by JavaParser#elementValueArrayInitializer.
JavaVisitor.prototype.visitElementValueArrayInitializer = function(ctx) {
};


// Visit a parse tree produced by JavaParser#annotationTypeDeclaration.
JavaVisitor.prototype.visitAnnotationTypeDeclaration = function(ctx) {
};


// Visit a parse tree produced by JavaParser#annotationTypeBody.
JavaVisitor.prototype.visitAnnotationTypeBody = function(ctx) {
};


// Visit a parse tree produced by JavaParser#annotationTypeElementDeclaration.
JavaVisitor.prototype.visitAnnotationTypeElementDeclaration = function(ctx) {
};


// Visit a parse tree produced by JavaParser#annotationTypeElementRest.
JavaVisitor.prototype.visitAnnotationTypeElementRest = function(ctx) {
};


// Visit a parse tree produced by JavaParser#annotationMethodOrConstantRest.
JavaVisitor.prototype.visitAnnotationMethodOrConstantRest = function(ctx) {
};


// Visit a parse tree produced by JavaParser#annotationMethodRest.
JavaVisitor.prototype.visitAnnotationMethodRest = function(ctx) {
};


// Visit a parse tree produced by JavaParser#annotationConstantRest.
JavaVisitor.prototype.visitAnnotationConstantRest = function(ctx) {
};


// Visit a parse tree produced by JavaParser#defaultValue.
JavaVisitor.prototype.visitDefaultValue = function(ctx) {
};


// Visit a parse tree produced by JavaParser#block.
JavaVisitor.prototype.visitBlock = function(ctx) {
};


// Visit a parse tree produced by JavaParser#blockStatement.
JavaVisitor.prototype.visitBlockStatement = function(ctx) {
};


// Visit a parse tree produced by JavaParser#localVariableDeclarationStatement.
JavaVisitor.prototype.visitLocalVariableDeclarationStatement = function(ctx) {
};


// Visit a parse tree produced by JavaParser#localVariableDeclaration.
JavaVisitor.prototype.visitLocalVariableDeclaration = function(ctx) {
};


// Visit a parse tree produced by JavaParser#statement.
JavaVisitor.prototype.visitStatement = function(ctx) {
};


// Visit a parse tree produced by JavaParser#catchClause.
JavaVisitor.prototype.visitCatchClause = function(ctx) {
};


// Visit a parse tree produced by JavaParser#catchType.
JavaVisitor.prototype.visitCatchType = function(ctx) {
};


// Visit a parse tree produced by JavaParser#finallyBlock.
JavaVisitor.prototype.visitFinallyBlock = function(ctx) {
};


// Visit a parse tree produced by JavaParser#resourceSpecification.
JavaVisitor.prototype.visitResourceSpecification = function(ctx) {
};


// Visit a parse tree produced by JavaParser#resources.
JavaVisitor.prototype.visitResources = function(ctx) {
};


// Visit a parse tree produced by JavaParser#resource.
JavaVisitor.prototype.visitResource = function(ctx) {
};


// Visit a parse tree produced by JavaParser#switchBlockStatementGroup.
JavaVisitor.prototype.visitSwitchBlockStatementGroup = function(ctx) {
};


// Visit a parse tree produced by JavaParser#switchLabel.
JavaVisitor.prototype.visitSwitchLabel = function(ctx) {
};


// Visit a parse tree produced by JavaParser#forControl.
JavaVisitor.prototype.visitForControl = function(ctx) {
};


// Visit a parse tree produced by JavaParser#forInit.
JavaVisitor.prototype.visitForInit = function(ctx) {
};


// Visit a parse tree produced by JavaParser#enhancedForControl.
JavaVisitor.prototype.visitEnhancedForControl = function(ctx) {
};


// Visit a parse tree produced by JavaParser#forUpdate.
JavaVisitor.prototype.visitForUpdate = function(ctx) {
};


// Visit a parse tree produced by JavaParser#parExpression.
JavaVisitor.prototype.visitParExpression = function(ctx) {
};


// Visit a parse tree produced by JavaParser#expressionList.
JavaVisitor.prototype.visitExpressionList = function(ctx) {
};


// Visit a parse tree produced by JavaParser#statementExpression.
JavaVisitor.prototype.visitStatementExpression = function(ctx) {
};


// Visit a parse tree produced by JavaParser#constantExpression.
JavaVisitor.prototype.visitConstantExpression = function(ctx) {
};


// Visit a parse tree produced by JavaParser#expression.
JavaVisitor.prototype.visitExpression = function(ctx) {
};


// Visit a parse tree produced by JavaParser#primary.
JavaVisitor.prototype.visitPrimary = function(ctx) {
};


// Visit a parse tree produced by JavaParser#creator.
JavaVisitor.prototype.visitCreator = function(ctx) {
};


// Visit a parse tree produced by JavaParser#createdName.
JavaVisitor.prototype.visitCreatedName = function(ctx) {
};


// Visit a parse tree produced by JavaParser#innerCreator.
JavaVisitor.prototype.visitInnerCreator = function(ctx) {
};


// Visit a parse tree produced by JavaParser#arrayCreatorRest.
JavaVisitor.prototype.visitArrayCreatorRest = function(ctx) {
};


// Visit a parse tree produced by JavaParser#classCreatorRest.
JavaVisitor.prototype.visitClassCreatorRest = function(ctx) {
};


// Visit a parse tree produced by JavaParser#explicitGenericInvocation.
JavaVisitor.prototype.visitExplicitGenericInvocation = function(ctx) {
};


// Visit a parse tree produced by JavaParser#nonWildcardTypeArguments.
JavaVisitor.prototype.visitNonWildcardTypeArguments = function(ctx) {
};


// Visit a parse tree produced by JavaParser#typeArgumentsOrDiamond.
JavaVisitor.prototype.visitTypeArgumentsOrDiamond = function(ctx) {
};


// Visit a parse tree produced by JavaParser#nonWildcardTypeArgumentsOrDiamond.
JavaVisitor.prototype.visitNonWildcardTypeArgumentsOrDiamond = function(ctx) {
};


// Visit a parse tree produced by JavaParser#superSuffix.
JavaVisitor.prototype.visitSuperSuffix = function(ctx) {
};


// Visit a parse tree produced by JavaParser#explicitGenericInvocationSuffix.
JavaVisitor.prototype.visitExplicitGenericInvocationSuffix = function(ctx) {
};


// Visit a parse tree produced by JavaParser#arguments.
JavaVisitor.prototype.visitArguments = function(ctx) {
};



exports.JavaVisitor = JavaVisitor;