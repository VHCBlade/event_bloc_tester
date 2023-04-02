// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

enum ListTesterMode {
  generateOutput,
  testOutput,
}

String toFilePath(String rawName) =>
    rawName.trim().replaceAll(" ", "/").replaceAll(RegExp(r'\/+'), "/");
String toFilename(String rawName) => toFilePath(rawName).replaceAll("/", "_");
File createFileObject(String path, String rawFilename) =>
    File("${toFilePath(path)}/${toFilename(rawFilename)}.json");

void createFolderIfNotExists(String path) {
  if (!Directory(path).existsSync()) {
    Directory(path).createSync(recursive: true);
    print('Folder created at $path');
  } else {
    print('Folder already exists at $path');
  }
}

/// This helps you easily write tests that have a serializable output.
///
/// Based on the [ListTesterMode] you use, this will either generate the expected output or
/// test against the expected output generated with a previous [generateOuput] call.
///
/// Please see test/example_test.dart for some example usage of this class.
class SerializableListTester<T> {
  final String testGroupName;
  final String mainTestName;
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

  void runTests() {
    final String path =
        "test_output/${toFilePath(testGroupName)}/${toFilePath(mainTestName)}";
    if (mode == ListTesterMode.generateOutput) {
      createFolderIfNotExists(path);
      print("Outputting test_output to $path");
      print(
          "If you're seeing this in a flutter test, your tests might not be valid!");
    }

    for (final testName in testMap.keys) {
      test(testName, () => runTest(path, testName));
    }
  }

  Future<void> runTest(String path, String testName) async {
    final generatedValue = testMap[testName]!();
    final tester = SerializableTester(mode);
    if (mode == ListTesterMode.testOutput) {
      final file = createFileObject(path, testName);
      final value = await file.readAsString();
      tester.testOutput.addAll(json.decode(value));
    }
    await testFunction(generatedValue, tester);

    tester.finish(path, testName);
  }
}

class SerializableTester {
  final testOutput = [];
  final ListTesterMode mode;
  int testCase = 0;

  SerializableTester(this.mode);

  void addTestValue(dynamic value) {
    testCase++;
    switch (mode) {
      case ListTesterMode.generateOutput:
        testOutput.add(json.encode(value));
        break;
      case ListTesterMode.testOutput:
        expect(json.decode(testOutput[testCase - 1]),
            json.decode(json.encode(value)));
    }
  }

  void finish(String path, String testName) {
    if (mode != ListTesterMode.generateOutput) {
      return;
    }

    final file = createFileObject(path, testName);
    final encodedTestOutput =
        const JsonEncoder.withIndent('  ').convert(testOutput);

    file.writeAsString(encodedTestOutput);
  }
}
