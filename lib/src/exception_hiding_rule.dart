import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class ExceptionHidingRule extends DartLintRule {
  const ExceptionHidingRule() : super(code: _code);

  static const _code = LintCode(
    name: 'exception_hiding',
    problemMessage:
        'Exception hiding detected: Caught exception is logged but not rethrown. '
        'This violates exception hiding prevention - let exceptions bubble up to reveal problems.',
    correctionMessage:
        'Remove the try-catch block or rethrow the exception after logging. '
        'Only catch exceptions when you can meaningfully fix the problem.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addTryStatement((node) {
      _checkTryStatement(node, reporter);
    });
  }

  void _checkTryStatement(TryStatement node, ErrorReporter reporter) {
    for (final catchClause in node.catchClauses) {
      if (_isExceptionHiding(catchClause)) {
        reporter.atNode(catchClause, code);
      }
    }
  }

  bool _isExceptionHiding(CatchClause catchClause) {
    final block = catchClause.body;
    final statements = block.statements;

    // Empty catch blocks are hiding
    if (statements.isEmpty) {
      return true;
    }

    // Check if any statement is rethrow or throw
    for (final statement in statements) {
      if (statement is ExpressionStatement) {
        final expression = statement.expression;
        if (expression is RethrowExpression || expression is ThrowExpression) {
          // Found legitimate exception handling - not hiding
          return false;
        }
      }
    }

    // No rethrow or throw found - this is hiding
    return true;
  }

}


