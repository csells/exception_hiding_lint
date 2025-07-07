# Exception Hiding Lint Rule - Design Document

## Executive Summary

The Exception Hiding Lint Rule is a custom Dart static analysis tool that enforces a critical software engineering principle: **exceptions should not be hidden in catch blocks**. This rule detects and prevents "exception hiding" patterns where code catches exceptions but fails to rethrow or throw, masking underlying problems from developers and users.

The implementation is intentionally simple and strict: **every catch block must contain either `rethrow` or `throw`** - anything else is considered exception hiding and will be flagged.

**Key Benefits:**
- **Problem Visibility**: Ensures underlying issues are exposed rather than hidden
- **Debugging Efficiency**: Reduces time spent tracking down masked problems
- **Code Quality**: Enforces explicit exception propagation
- **Team Alignment**: Codifies exception handling philosophy across the codebase

## Exception Hiding Prevention Philosophy

### Core Principle

> "Never hide exceptions with try-catch blocks - exceptions are either problems we need to fix or problems the user needs to fix, but hiding them makes that impossible."

### Rationale

**Exception hiding** occurs when code catches exceptions but continues execution without properly propagating the error. This creates several issues:

1. **Hidden Failures**: Problems occur silently, making debugging nearly impossible
2. **Inconsistent State**: Applications continue running with corrupted or incomplete data
3. **User Confusion**: Features appear to work but produce incorrect results
4. **Technical Debt**: Problems accumulate without visibility into their frequency or impact

### The Simple Rule

The lint rule enforces one simple principle:
- **Every catch block must contain either `rethrow` or `throw`**
- Any catch block without these statements is flagged as exception hiding

## Architecture & Implementation

### Technical Foundation

The lint rule is built using Dart's `custom_lint_builder` framework, which provides:

- **AST Access**: Direct access to the Abstract Syntax Tree of Dart code
- **Integration**: Seamless integration with `dart analyze` and IDE tooling
- **Performance**: Efficient analysis during compilation without runtime overhead
- **Extensibility**: Plugin architecture for custom rules

### Plugin Structure

```dart
// Main plugin entry point
class _ExceptionHidingLint extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        ExceptionHidingRule(),
      ];
}
```

### Rule Implementation

The core rule implementation is remarkably simple:

```dart
class ExceptionHidingRule extends DartLintRule {
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
  void run(CustomLintResolver resolver, ErrorReporter reporter, CustomLintContext context) {
    context.registry.addTryStatement((node) => _checkTryStatement(node, reporter));
  }

  bool _isExceptionHiding(CatchClause catchClause) {
    final statements = catchClause.body.statements;
    
    // Empty catch blocks are hiding
    if (statements.isEmpty) return true;
    
    // Check if any statement is rethrow or throw
    for (final statement in statements) {
      if (statement is ExpressionStatement) {
        final expression = statement.expression;
        if (expression is RethrowExpression || expression is ThrowExpression) {
          return false; // Found legitimate exception handling
        }
      }
    }
    
    // No rethrow or throw found - this is hiding
    return true;
  }
}
```

## Detection Logic

The detection logic is straightforward:

1. **Empty Catch Blocks**: Any catch block with no statements is immediately flagged
2. **Statement Analysis**: For non-empty catch blocks, examine each statement
3. **Look for Propagation**: Check if any statement is `rethrow` or `throw`
4. **Flag if Missing**: If no exception propagation is found, flag as hiding

## Pattern Recognition Examples

### ❌ Detected Violations

#### 1. Empty Catch Block
```dart
try {
  criticalSystemOperation();
} catch (e) {
  // Hiding - completely ignores all exceptions
}
```

#### 2. Log-and-Continue Pattern
```dart
try {
  final result = await complexOperation();
  return processResult(result);
} catch (e) {
  logger.warning('Operation failed: $e');
  return null; // Hiding - continues with null instead of failing
}
```

#### 3. Silent Default Creation
```dart
try {
  return jsonDecode(input);
} catch (e) {
  return {}; // Hiding - creates empty map on parse failure
}
```

#### 4. Print Without Rethrow
```dart
try {
  return fetchUserName();
} catch (e) {
  print('Error: $e');
  return 'Unknown User'; // Hiding - returns fallback value
}
```

### ✅ Allowed Patterns

#### 1. Rethrow
```dart
try {
  return performOperation();
} catch (e) {
  logger.error('Operation failed: $e');
  await cleanup();
  rethrow; // ✅ Exception propagates up
}
```

#### 2. Exception Transformation  
```dart
try {
  return lowLevelOperation();
} catch (e) {
  throw DomainSpecificException('High-level operation failed', e); // ✅ New exception thrown
}
```

#### 3. Conditional Throw
```dart
try {
  return riskyOperation();
} catch (e) {
  if (shouldRetry) {
    scheduleRetry();
  }
  throw OperationFailedException(e); // ✅ Always throws
}
```

## Integration Strategy

### Installation & Configuration

#### 1. Package Dependencies

Add to `pubspec.yaml`:
```yaml
dev_dependencies:
  custom_lint: ^0.7.5
  exception_hiding_lint:
    path: ../exception_hiding_lint
```

#### 2. Analysis Configuration

Add to `analysis_options.yaml`:
```yaml
analyzer:
  plugins:
    - custom_lint

custom_lint:
  rules:
    - exception_hiding
```

#### 3. IDE Integration

The rule integrates seamlessly with:
- **VS Code**: Real-time highlighting via Dart extension
- **IntelliJ IDEA**: Inline warnings and quick fixes
- **Command Line**: Integration with `dart analyze`

### Usage Workflow

#### 1. Development Phase
```bash
# Real-time analysis during development
dart analyze --watch
```

#### 2. CI/CD Integration
```bash
# Automated checking in build pipeline
dart run custom_lint
if [ $? -ne 0 ]; then
  echo "Exception hiding violations detected"
  exit 1
fi
```

#### 3. Pre-commit Hooks
```bash
# Git pre-commit hook
#!/bin/sh
dart run custom_lint
exit $?
```

## Testing Strategy

The rule includes comprehensive test coverage to ensure correct behavior:

### Test Categories

1. **Basic Detection**
   - Empty catch blocks
   - Logging without rethrow
   - Print statements without propagation

2. **Allowed Patterns**
   - Rethrow after logging
   - Exception transformation
   - Cleanup with rethrow

3. **Edge Cases**
   - Multiple catch clauses
   - Nested try-catch blocks
   - Complex control flow

### Test Implementation

Tests use the actual rule implementation to verify behavior:

```dart
bool _analyzeCode(String code) {
  final parseResult = parseString(content: code, featureSet: FeatureSet.latestLanguageVersion());
  final rule = const ExceptionHidingRule();
  bool foundViolations = false;
  
  final visitor = _TryStatementFinder((tryStatement) {
    for (final catchClause in tryStatement.catchClauses) {
      if (rule._isExceptionHiding(catchClause)) {
        foundViolations = true;
        break;
      }
    }
  });
  
  parseResult.unit.accept(visitor);
  return foundViolations;
}
```

## Performance Considerations

The rule is designed for minimal performance impact:

1. **Selective Analysis**: Only analyzes `TryStatement` nodes, not entire AST
2. **Early Exit**: Returns as soon as `rethrow` or `throw` is found
3. **Simple Logic**: No complex pattern matching or deep analysis required
4. **Stateless**: No state maintained between analyses

## Future Considerations

While the current implementation is intentionally simple, potential enhancements could include:

1. **Configuration Options**: Allow teams to configure exceptions for specific patterns
2. **Quick Fixes**: Automated suggestions to add `rethrow` statements
3. **Metrics**: Track exception hiding patterns across codebases
4. **Integration**: Better integration with popular logging frameworks

However, the simplicity of the current rule is its strength - it enforces a clear, unambiguous principle that improves code quality.

## Conclusion

The Exception Hiding Lint Rule provides a simple but powerful tool for maintaining code quality. By enforcing that all catch blocks must either `rethrow` or `throw`, it ensures that exceptions bubble up to reveal problems rather than being silently hidden.

The rule's simplicity makes it easy to understand, implement, and follow, while its strict enforcement helps teams maintain consistent exception handling practices across their codebases.

---

*This design document reflects the current implementation of the Exception Hiding Lint Rule. The rule is intentionally simple and opinionated to enforce clear exception handling practices.*