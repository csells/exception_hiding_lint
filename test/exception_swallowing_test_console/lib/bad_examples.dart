// ❌ BAD EXAMPLES - These SHOULD trigger the lint rule

import 'dart:convert';

/// ❌ BAD: Empty catch block - completely swallows exceptions
void emptyCatch() {
  try {
    criticalOperation();
  } on Exception catch (_) {
    // Empty catch - this should be flagged!
  }
}

/// ❌ BAD: Log and continue without rethrow
void logAndContinue() {
  try {
    importantDataProcessing();
  } on Exception catch (e) {
    print('Error occurred: $e');
    // No rethrow - this swallows the exception!
  }
}

/// ❌ BAD: Creates default values on failure
Map<String, dynamic> defaultValueCreation() {
  try {
    return parseImportantData();
  } on Exception catch (_) {
    return {}; // Creates empty map instead of failing - swallowing!
  }
}

/// ❌ BAD: Logger usage without rethrow
void loggerWithoutRethrow() {
  final logger = createLogger();
  try {
    performCriticalTask();
  } on Exception catch (e) {
    logger.severe('Task failed: $e');
    // No rethrow - exception is swallowed!
  }
}

/// ❌ BAD: Silent fallback value creation
String silentFallback() {
  try {
    return fetchUserName();
  } on Exception catch (_) {
    return 'Unknown User'; // Silent fallback - user never knows fetch failed!
  }
}

/// ❌ BAD: Assignment to default on exception
void assignmentDefault() {
  String result;
  try {
    result = complexCalculation();
  } on Exception catch (_) {
    result = 'default'; // Assigns default value - swallowing!
  }
  print('Result: $result');
}

/// ❌ BAD: Multiple statements but still swallowing
void multipleStatementsSwallowing() {
  try {
    networkOperation();
  } on Exception catch (e) {
    print('Network failed: $e');
    final errorTime = DateTime.now();
    print('Error occurred at: $errorTime');
    // Multiple statements but still no rethrow - swallowing!
  }
}

/// ❌ BAD: Creating result structure that looks like tool handling but isn't
Map<String, dynamic> fakeToolHandling() {
  try {
    return processUserInput();
  } on Exception catch (e) {
    // This looks like tool error handling but it's just creating default result
    return {'result': 'failed', 'message': e.toString()};
  }
}

/// ❌ BAD: toString() fallback pattern
String toStringFallback() {
  try {
    return jsonEncode(getDataStructure());
  } on Exception catch (e) {
    return e.toString(); // Fallback to string representation - swallowing!
  }
}

/// ❌ BAD: List fallback pattern
List<String> listFallback() {
  try {
    return fetchItemList();
  } on Exception catch (_) {
    return []; // Empty list fallback - swallowing!
  }
}

/// ❌ BAD: Tool result creation pattern
void createToolResult() {
  try {
    final result = executeToolCommand();
    print('Tool succeeded: $result');
  } on Exception catch (e) {
    // This pattern is recognized as legitimate tool error handling
    final toolResult = {
      'tool_call_id': 'call_123',
      'result': json.encode({'error': e.toString()}),
    };
    print('Tool failed: $toolResult');
  }
}

/// ❌ BAD: Langchain example
void langchainExample() {
  final toolResultMessages = <String>[];
  try {
    print('Langchain example');
  } on Exception catch (error) {
    // Create an error result message
    toolResultMessages.add(
      ChatMessage(
        role: MessageRole.user,
        parts: [
          ToolPart.result(
            id: '1',
            name: 'test',
            result: {'error': error.toString()},
          ),
        ],
      ).toString(),
    );
  }
}

/// ❌ BAD: Tool error handling - should rethrow or throw instead
Map<String, dynamic> toolErrorHandling() {
  try {
    return performToolOperation();
  } on Exception catch (e) {
    // This violates exception transparency - should rethrow or throw
    return {'error': e.toString()};
  }
}

/// ❌ BAD: Retry logic - should rethrow or throw instead
Future<String> retryLogic() async {
  int attempt = 0;
  while (attempt < 3) {
    try {
      return await unstableNetworkCall();
    } on Exception catch (_) {
      attempt++;
      if (attempt >= 3) rethrow;
      await Future.delayed(Duration(seconds: attempt));
      // This violates exception transparency - should rethrow or throw
    }
  }
  throw Exception('Max retries exceeded');
}

// Helper functions for examples
void criticalOperation() => throw Exception('Critical failure');
void importantDataProcessing() => throw Exception('Data processing failed');
Map<String, dynamic> parseImportantData() => throw Exception('Parse error');
Logger createLogger() => Logger();
void performCriticalTask() => throw Exception('Task failed');
String fetchUserName() => throw Exception('Network error');
String complexCalculation() => throw Exception('Math error');
void networkOperation() => throw Exception('Connection failed');
Map<String, dynamic> processUserInput() => throw Exception('Invalid input');
Map<String, dynamic> getDataStructure() => throw Exception('Data error');
List<String> fetchItemList() => throw Exception('Fetch failed');

class Logger {
  void severe(String message) => print('SEVERE: $message');
}

Map<String, dynamic> performToolOperation() => {'result': 'success'};
void dangerousOperation() => throw Exception('Something went wrong');
void lowLevelOperation() => throw Exception('Low level error');
Future<String> unstableNetworkCall() => throw Exception('Network error');
void allocateResources() {}
void doWork() => throw Exception('Work failed');
void cleanup() {}
String executeToolCommand() => throw Exception('Tool error');

class CustomException implements Exception {
  final String message;
  final Object? cause;
  CustomException(this.message, this.cause);

  @override
  String toString() => 'CustomException: $message';
}

class ChatMessage {
  final String role;
  final List<ToolPart> parts;

  ChatMessage({required this.role, required this.parts});
}

class MessageRole {
  static const user = 'user';
  static const assistant = 'assistant';
}

class ToolPart {
  final String id;
  final String name;
  final Map<String, dynamic> result;

  ToolPart.result({required this.id, required this.name, required this.result});
}
