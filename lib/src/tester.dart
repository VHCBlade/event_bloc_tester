// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

enum ListTesterMode {
  generateOutput,
  testOutput,
  // Will automatically generateOutput if necessary. Will testOutput if not available
  auto,
}

String toFilePath(String rawName) =>
    rawName.trim().replaceAll(" ", "/").replaceAll(RegExp(r'\/+'), "/");
String toFilename(String rawName) => toFilePath(rawName).replaceAll("/", "_");
File createFileObject(String path, String rawFilename) =>
    File("${toFilePath(path)}/${toFilename(rawFilename)}.json");

/// returns true if a folder was created and false if not
bool createFolderIfNotExists(String path) {
  if (!Directory(path).existsSync()) {
    Directory(path).createSync(recursive: true);
    print('Folder created at $path');
    return true;
  }

  print('Folder already exists at $path');
  return false;
}

/// This is a mixin that stores the logic for creating a tester that supports the various [ListTesterMode]s
///
/// See [SerializableListTester] and [SerializableListWidgetTester] for implementations of this mixin
mixin SerializableListTesterMixin<T> {
  String get testGroupName;
  String get mainTestName;
  ListTesterMode get mode;

  /// Run the tests under the current [mode]
  Future<void> runTests();

  /// Generates the path that this tester will use in [runTests]
  ///
  /// This will also automatically create the path if needed by the created [mode]
  String generatePath() {
    final String path =
        "test_output/${toFilePath(testGroupName)}/${toFilePath(mainTestName)}";

    final folderCreated = createFolderIfNotExists(path);
    if (mode == ListTesterMode.generateOutput ||
        (folderCreated && mode == ListTesterMode.auto)) {
      print("Outputting test_output to $path");
      print(
          "If you're seeing this in a flutter test, your tests might not be valid!");
    }

    return path;
  }

  /// Generates the [SerializableTester] that will be used in [runTests]
  ///
  /// This will also automatically load any needed values for the [SerializableTester] based on [mode]
  Future<SerializableTester> generateListTester(String path, String testName,
      [ListTesterMode? modeOverride]) async {
    final usedMode = modeOverride ?? mode;
    if (usedMode == ListTesterMode.auto) {
      final file = createFileObject(path, testName);
      return generateListTester(
          path,
          testName,
          file.existsSync()
              ? ListTesterMode.testOutput
              : ListTesterMode.generateOutput);
    }

    final tester = SerializableTester(usedMode);
    if (usedMode == ListTesterMode.testOutput) {
      final file = createFileObject(path, testName);
      try {
        final value = file.readAsStringSync();
        tester.testOutput.addAll(json.decode(value));
      } on PathNotFoundException {
        throw ArgumentError(
            "Unable to find generated output file. You need to run with mode: ListTesterMode.generateOutput before testing. ${file.path}");
      }
    }
    return tester;
  }
}

/// This helps you easily write unit tests that have a serializable output.
///
/// Based on the [ListTesterMode] you use, this will either generate the expected output or
/// test against the expected output generated with a previous [generateOuput] call.
///
/// Please see test/example_test.dart for some example usage of this class.
///
/// If you need a version for Widget tests, please see [SerializableListWidgetTester]
class SerializableListTester<T> with SerializableListTesterMixin<T> {
  @override
  final String testGroupName;
  @override
  final String mainTestName;
  @override
  final ListTesterMode mode;
  final FutureOr<void> Function(T testInput, SerializableTester tester)
      testFunction;
  final Map<String, T Function()> testMap;

  /// [testGroupName] and [mainTestName] are passed as the test groups this tester is a part of.
  ///
  /// [mode] determines the behaviour of [runTests]. If it's in [ListTesterMode.generateOutput],
  /// an output file will be generated based on the output. If it's in [ListTesterMode.testOutput]
  /// the output will be tested against the output file generated with a previous run of [ListTesterMode.generateOutput]
  ///
  /// [testMap] is a map with key being the test name of the test, and the value being a supplier for an
  /// initial testValue.
  ///
  /// [testFunction] is the common test that will be run on everything in [testMap]. Use the provided
  /// [SerializableTester] to add your test values.
  SerializableListTester({
    required this.testGroupName,
    required this.mainTestName,
    this.mode = ListTesterMode.testOutput,
    required this.testFunction,
    required this.testMap,
  });

  @override
  Future<void> runTests() async {
    final path = generatePath();
    for (final testName in testMap.keys) {
      test(testName, () => runTest(path, testName));
    }
  }

  Future<void> runTest(String path, String testName) async {
    final generatedValue = testMap[testName]!();
    final tester = await generateListTester(path, testName);
    await testFunction(generatedValue, tester);

    await tester.finish(path, testName);
  }
}

class SerializableTester {
  final testOutput = [];
  final ListTesterMode mode;
  int testCase = 0;

  SerializableTester(this.mode) : assert(mode != ListTesterMode.auto);

  void addTestValue(dynamic value) {
    testCase++;
    switch (mode) {
      case ListTesterMode.generateOutput:
        testOutput.add(json.encode(value));
        return;
      case ListTesterMode.testOutput:
        expect(json.decode(testOutput[testCase - 1]),
            json.decode(json.encode(value)));
        return;
      case ListTesterMode.auto:
        throw ArgumentError(
            "SerializableTester cannot be initialized with auto.");
    }
  }

  FutureOr<void> finish(String path, String testName) async {
    if (mode != ListTesterMode.generateOutput) {
      return null;
    }

    final file = createFileObject(path, testName);
    final encodedTestOutput =
        const JsonEncoder.withIndent('  ').convert(testOutput);

    await file.writeAsString(encodedTestOutput, flush: true);
  }
}
