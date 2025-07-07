# Exception Hiding Lint

A custom Dart lint package that detects exception hiding patterns in your code.

## Why I built this

I built this lint because I couldn't stop my AI agent of the week from using
`try-catch` blocks to paper over errors it didn't know how to fix, e.g.

```dart
try {
  final result = jsonDecode(data);
  return result;
} catch (e) {
  _logger.warning('JSON parsing failed: $e');
  return {}; // Creates default value instead of letting exception bubble up
}
```

Of course, I've used `YOUR-AGENT-HERE.md` files and memory and etc. rules files
depending on what agent I happen to be using, but no matter how many CAPS and
!!! I use, I still can't consistently talk it  out of hiding errors like this.
It feels like the AI is a child trying to hide it's mess so it doesn't get into
trouble. Which may not be far from the truth; I have been known to use course
language when providing feedback to the AI...

Anyway, if you use this and then do things like retry logic, you can disable the
lint on a case-by-case basis using standard lint `ignore` comments:

```dart
Future<String> retryLogic() async {
  int attempt = 0;
  while (attempt < 3) {
    try {
      return await unstableNetworkCall();
    // ignore: exception_hiding
    } on Exception catch (_) {
      attempt++;
      if (attempt >= 3) rethrow;
      await Future.delayed(Duration(seconds: attempt));
    }
  }
  throw Exception('Max retries exceeded');
}
```

I wonder how long it'll take the AI to learn to learn to ignore these kinds of
exception-hiding `catch` blocks itself...

## What it detects

This linter identifies problematic try-catch blocks that hide exceptions instead
of letting them bubble up. The rule is simple: **every catch block must either
`rethrow` or `throw`** - anything else is considered exception hiding.

### ❌ Patterns that get flagged:

1. **Empty catch blocks** - Silently ignore exceptions without any handling
2. **Logging without rethrow** - Catches exceptions, logs them, but continues
   execution without propagating the error
3. **Any catch block without rethrow/throw** - Any catch block that doesn't end
   with `rethrow` or `throw` is flagged

## Exception Hiding Prevention Principle

> "Never hide exceptions with try-catch blocks unless there's a specific fix we
> can apply in our code - exceptions are either problems we need to fix or
> problems the user needs to fix, but hiding them makes that impossible."

## Examples

### ❌ BAD - Empty Catch Block

```dart
try {
  processImportantData();
} catch (e) {
  // Empty catch - hides all problems
}
```

### ❌ BAD - Logging Without Rethrow

```dart
try {
  final result = jsonDecode(data);
  return result;
} catch (e) {
  _logger.warning('JSON parsing failed: $e');
  return {}; // Creates default value instead of letting exception bubble up
}
```

### ❌ BAD - Print and Continue

```dart
try {
  return fetchUserName();
} catch (e) {
  print('Error: $e');
  return 'Unknown User'; // Hides the actual error
}
```

### ✅ GOOD - Rethrow After Logging

```dart
try {
  final result = jsonDecode(data);
  return result;
} catch (e) {
  _logger.warning('JSON parsing failed: $e');
  rethrow; // Let the exception bubble up after logging
}
```

### ✅ GOOD - Exception Transformation

```dart
try {
  final result = await lowLevelOperation();
  return result;
} catch (e) {
  throw PackageSpecificException(e.toString());
}
```

### ✅ GOOD - Cleanup with Rethrow

```dart
try {
  await performOperation();
} catch (e) {
  await cleanup();
  rethrow; // Always rethrow after cleanup
}
```

## Installation

***NOTE: I haven't published this on pub.dev yet, since it seems so silly that
someone is going to tell me the way to get AI to do this. In the meantime, you
can clone this repo and use it from a path; it's a dev dependency, so it
shouldn't try you during pub.dev publication.***

Add to your `analysis_options.yaml`:

```yaml
analyzer:
  plugins:
    - custom_lint

custom_lint:
  rules:
    - exception_hiding
```

Add to your `dev_dependencies` in `pubspec.yaml`:

```yaml
dev_dependencies:
  exception_hiding_lint:
    path: ../exception_hiding_lint
```

## Usage

Just let the linter run in your IDE of choice or run `dart analyze` as normal.
