import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

import '../event_bloc_tester.dart';

/// This helps you easily write widget tests that have a serializable output.
///
/// Based on the [ListTesterMode] you use, this will either generate the expected output or
/// test against the expected output generated with a previous [generateOuput] call.
///
/// Please see test/example_widget_test.dart for some example usage of this class.
///
/// If you need a version for unit tests, please see [SerializableListTester]
class SerializableListWidgetTester<T> with SerializableListTesterMixin<T> {
  @override
  final String testGroupName;
  @override
  final String mainTestName;
  @override
  final ListTesterMode mode;
  final FutureOr<void> Function(
          T testInput, SerializableTester tester, WidgetTester widgetTester)
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
  SerializableListWidgetTester({
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
      final completer = Completer<SerializableTester>();
      testWidgets(testName,
          (widgetTester) => runTest(path, testName, widgetTester, completer));

      completer.future.then((value) => value.finish(path, testName));
    }

    if (mode == ListTesterMode.generateOutput || mode == ListTesterMode.auto) {
      // This is super janky, but we need it so that the SerializableTester will output to local.
      testWidgets("Delay to let file output happen...", (widgetTester) async {
        final currentTime = DateTime.now();
        while (DateTime.now().millisecondsSinceEpoch -
                currentTime.millisecondsSinceEpoch <
            1500) {
          await widgetTester.pumpAndSettle(const Duration(seconds: 1));
        }
      });
    }
  }

  Future<void> runTest(
    String path,
    String testName,
    WidgetTester widgetTester,
    Completer<SerializableTester> completer,
  ) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final generatedValue = testMap[testName]!();
    final tester = await generateListTester(path, testName);
    await testFunction(generatedValue, tester, widgetTester);
    completer.complete(tester);
  }
}
