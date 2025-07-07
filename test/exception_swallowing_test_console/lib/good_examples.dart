// EXAMPLES - Only rethrow and throw are legitimate

/// ✅ GOOD: Proper rethrow after logging
void properRethrow() {
  try {
    dangerousOperation();
  } on Exception catch (e) {
    print('Operation failed: $e');
    rethrow; // Exception still bubbles up
  }
}

/// ✅ GOOD: Exception transformation
void exceptionTransformation() {
  try {
    lowLevelOperation();
  } on Exception catch (e) {
    throw CustomException('High-level operation failed', e);
  }
}

/// ✅ GOOD: Cleanup with rethrow
void cleanupWithRethrow() {
  try {
    allocateResources();
    doWork();
  } on Exception catch (_) {
    cleanup();
    rethrow; // Still propagates the exception after cleanup
  }
}

// Helper functions for examples
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
