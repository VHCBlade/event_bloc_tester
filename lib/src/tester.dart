// ignore_for_file: avoid_print, require_trailing_commas

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

/// The modes that the Serializable Testers can be ran in with different
/// properties.
enum ListTesterMode {
  /// Will save the output to a file
  generateOutput,

  /// Will test the current output based on the output when [generateOutput]
  /// was last ran.
  testOutput,

  /// Will automatically generateOutput if necessary. Will testOutput if not
  /// available
  auto,

  /// No output will be generated or checked against
  noOutput,
}

/// Converts [rawName] to the expected filePath
String toFilePath(String rawName) =>
    rawName.trim().replaceAll(' ', '/').replaceAll(RegExp(r'\/+'), '/');

/// Converts [rawName] to a filename with no folder traversal
String toFilename(String rawName) => toFilePath(rawName).replaceAll('/', '_');

/// Converts [path] and [rawFilename] into the expected [File] object
File createFileObject(String path, String rawFilename) =>
    File('${toFilePath(path)}/${toFilename(rawFilename)}.json');

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

/// This is a mixin that stores the logic for creating a tester that supports
/// the various [ListTesterMode]s
///
/// See [SerializableListTester] and SerializableListWidgetTester for
/// implementations of this mixin
mixin SerializableListTesterMixin<T> {
  /// The name for the test group. Will be used to determine the file path
  /// for the test output.
  String get testGroupName;

  /// The name for the test. Will be used to determine the filename for the
  /// test output.
  String get mainTestName;

  /// The mode to determine what to do with the output for this test run.
  ListTesterMode get mode;

  /// Run the tests under the current [mode]
  Future<void> runTests();

  /// Generates the path that this tester will use in [runTests]
  ///
  /// This will also automatically create the path if needed by the created
  /// [mode]
  String generatePath() {
    final path =
        'test_output/${toFilePath(testGroupName)}/${toFilePath(mainTestName)}';
    if (mode == ListTesterMode.noOutput) {
      return path;
    }

    final folderCreated = createFolderIfNotExists(path);
    if (mode == ListTesterMode.generateOutput ||
        (folderCreated && mode == ListTesterMode.auto)) {
      print('Outputting test_output to $path');
      print(
        "If you're seeing this in a flutter test,"
        ' your tests might not be valid!',
      );
    }

    return path;
  }

  /// Generates the [SerializableTester] that will be used in [runTests]
  ///
  /// This will also automatically load any needed values for the
  /// [SerializableTester] based on [mode]
  Future<SerializableTester> generateListTester(
    String path,
    String testName, [
    ListTesterMode? modeOverride,
  ]) async {
    final usedMode = modeOverride ?? mode;
    if (usedMode == ListTesterMode.auto) {
      final file = createFileObject(path, testName);
      return generateListTester(
        path,
        testName,
        file.existsSync()
            ? ListTesterMode.testOutput
            : ListTesterMode.generateOutput,
      );
    }
    print(usedMode);

    final tester = SerializableTester(usedMode);
    if (usedMode == ListTesterMode.testOutput) {
      final file = createFileObject(path, testName);
      try {
        final value = file.readAsStringSync();
        tester.testOutput
            .addAll((json.decode(value) as List<dynamic>).map((e) => '$e'));
      } on PathNotFoundException {
        throw ArgumentError(
            'Unable to find generated output file. You need to run with mode: '
            'ListTesterMode.generateOutput before testing. ${file.path}');
      }
    }
    return tester;
  }
}

/// This helps you easily write unit tests that have a serializable output.
///
/// Based on the [ListTesterMode] you use, this will either generate the
/// expected output or test against the expected output generated with a
/// previous [ListTesterMode.generateOutput] call.
///
/// Please see test/example_test.dart for some example usage of this class.
///
/// If you need a version for Widget tests, please see
/// SerializableListWidgetTester
class SerializableListTester<T> with SerializableListTesterMixin<T> {
  /// [testGroupName] and [mainTestName] are passed as the test groups this
  /// tester is a part of.
  ///
  /// [mode] determines the behaviour of [runTests]. If it's in
  /// [ListTesterMode.generateOutput], an output file will be generated based on
  /// the output. If it's in [ListTesterMode.testOutput] the output will be
  /// tested against the output file generated with a previous run of
  /// [ListTesterMode.generateOutput]
  ///
  /// [testMap] is a map with key being the test name of the test, and the value
  /// being a supplier for an initial testValue.
  ///
  /// [testFunction] is the common test that will be run on everything in
  /// [testMap]. Use the provided [SerializableTester] to add your test values.
  SerializableListTester({
    required this.testGroupName,
    required this.mainTestName,
    required this.testFunction,
    required this.testMap,
    this.mode = ListTesterMode.testOutput,
  });
  @override
  final String testGroupName;
  @override
  final String mainTestName;
  @override
  final ListTesterMode mode;

  /// The function that will be ran for each test case in [testMap]
  final FutureOr<void> Function(T testInput, SerializableTester tester)
      testFunction;

  /// Holds the test cases with the test name being the key and the supplier
  /// function for the test case being the value.
  final Map<String, T Function()> testMap;

  @override
  Future<void> runTests() async {
    final path = generatePath();
    for (final testName in testMap.keys) {
      test(testName, () => runTest(path, testName));
    }
  }

  /// Runs a single test given the [path] and [testName] to determine the
  /// output location and [mode] to determine what to do with the output.
  Future<void> runTest(String path, String testName) async {
    final generatedValue = testMap[testName]!();
    final tester = await generateListTester(path, testName);
    await testFunction(generatedValue, tester);

    await tester.finish(path, testName);
  }
}

/// A Tester for a single test case
class SerializableTester {
  /// A tester for a single test case
  ///
  /// [mode] determines how [addTestValue] and [finish] will behave.
  SerializableTester(this.mode)
      : assert(mode != ListTesterMode.auto, 'SerializableTester cannot be ');

  /// Holds the expected testOutput, which is determined depending on the mode
  final testOutput = <String>[];

  /// Determines how [addTestValue] and [finish] will behave.
  final ListTesterMode mode;

  /// An internal counter for how many test values have been added.
  int testCase = 0;

  /// Adds [value] to the expected output or compares [value] to the expected
  /// output, depending on [mode].
  void addTestValue(dynamic value) {
    testCase++;
    switch (mode) {
      case ListTesterMode.noOutput:
      case ListTesterMode.generateOutput:
        testOutput.add(json.encode(value));
        return;
      case ListTesterMode.testOutput:
        expect(
          json.decode(json.encode(value)),
          json.decode(testOutput[testCase - 1]),
        );
        return;
      case ListTesterMode.auto:
        throw ArgumentError(
          'SerializableTester cannot be initialized with auto.',
        );
    }
  }

  /// Finishes the test by either saving the expected testOutput or
  /// doing nothing, depending on [mode]
  FutureOr<void> finish(String path, String testName) async {
    switch (mode) {
      case ListTesterMode.auto:
        throw ArgumentError(
          'SerializableTester cannot be initialized with auto.',
        );
      case ListTesterMode.testOutput:
        return;
      case ListTesterMode.noOutput:
        if (testOutput.isNotEmpty) {
          print(
              '$path $testName was ran with noOutput mode however an output was'
              ' produced. Your tests may be invalid!');
        }
        return;
      case ListTesterMode.generateOutput:
    }

    final file = createFileObject(path, testName);
    final encodedTestOutput =
        const JsonEncoder.withIndent('  ').convert(testOutput);

    await file.writeAsString(encodedTestOutput, flush: true);
  }
}
