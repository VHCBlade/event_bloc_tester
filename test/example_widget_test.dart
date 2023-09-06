import 'package:event_bloc_tester/event_bloc_widget_tester.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Widget Test', () {
    group('Hello World', helloWorldTest);
  });
}

Map<String, String Function()> get commonTestCases => {
      'Basic 1': () => 'File',
      'Basic 2': () => 'Cool',
      'Basic 3': () => 'Matthew Graham',
    };

void helloWorldTest() {
  SerializableListWidgetTester<String>(
    testGroupName: 'Widget Test',
    mainTestName: 'Hello World',
    // Change this value to determine whether you generate the output file or
    // check against it.
    // mode: ListTesterMode.generateOutput,
    testFunction: (value, tester, widgetTester) async {
      final key = GlobalKey();
      await widgetTester.pumpWidget(
        MaterialApp(
          home: Text(
            'Hello $value!',
            key: key,
          ),
        ),
      );
      await widgetTester.pumpAndSettle();

      tester.addTestValue(widgetTester.widget<Text>(find.byKey(key)).data);

      await widgetTester.pumpWidget(
        MaterialApp(
          home: Text(
            '$value is the best!',
            key: key,
          ),
        ),
      );
      await widgetTester.pumpAndSettle();

      tester.addTestValue(widgetTester.widget<Text>(find.byKey(key)).data);
    },
    testMap: commonTestCases,
  ).runTests();
}
