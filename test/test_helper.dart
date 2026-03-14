/// Test helper file for configuring test environment
///
/// This file sets up the test environment for all tests in the project.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mocktail/mocktail.dart';

/// Sets up the test environment for all tests.
///
/// Call this in setUpAll or setUp of test files that need:
/// - Widget bindings (for widget tests)
/// - Database (for service tests)
/// - Mocktail fallback values
void setUpTestEnvironment() {
  // Initialize Flutter binding for widget tests
  TestWidgetsFlutterBinding.ensureInitialized();

  // Initialize FFI for database tests
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Register fallback values for mocktail
  registerFallbackValue(const Duration(seconds: 30));
  registerFallbackValue(<String, dynamic>{});
  registerFallbackValue(<int>[]);
  registerFallbackValue(<String>[]);

  // Add more fallback values as needed
}

/// Tears down the test environment.
void tearDownTestEnvironment() {
  // Clean up resources if needed
}
