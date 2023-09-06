import 'package:event_bloc_tester/src/tester.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuple/tuple.dart';

void main() {
  group('NoOutput File Commands', () {
    group('toFilePath', toFilePathTest);
    group('toFileName', toFileNameTest);
    group('createFileObject', createFileObjectTest);
  });
}

// You can have the same test cases for different functions!
Map<String, String Function()> get commonTestCases => {
      'Basic 1': () => 'File',
      'Basic 2': () => 'Cool',
      'WithSpaces 1': () => 'Amazing File',
      'WithSpaces 2': () => 'Amazing Files Here Come and Get Them',
      'Trailing Spaces': () => 'Greate     ',
      'Leading Spaces': () => '      Greate',
      'MultiSpace': () => 'I  put    multiple    Spaces',
      'Existing slashes': () => 'wow/you/just/want///tosee/theworld/burn',
      'Space slash': () => 'I / Like /// // / / random / slashes',
      'I am Extra': () => 'Extra',
    };

Map<String, Tuple2<String, String> Function()> get filePathTestCases => {
      'Basic': () => const Tuple2('File', ' Cool'),
      'WithSpaces': () =>
          const Tuple2('Amazing File', 'Amazing Files Here Come and Get Them'),
      'Leading and Trailing Spaces': () =>
          const Tuple2('Greate     ', '      Cooler'),
      'MultiSpace and Existing Slashes': () => const Tuple2(
            'I  put    multiple    Spaces',
            'wow/you/just/want///tosee/theworld/burn',
          ),
      'Space slash': () =>
          const Tuple2('This / slash', 'I / Like /// // / / random / slashes'),
      'I am Extra': () => const Tuple2('Extra', 'Extra'),
    };

void createFileObjectTest() {
  SerializableListTester<Tuple2<String, String>>(
    testGroupName: 'NoOutput File Commands',
    mainTestName: 'createFileObject',
    mode: ListTesterMode.noOutput,
    testFunction: (value, tester) {
      expect(value.item1, value.item1);
      expect(value.item2.length > 4, true);
    },
    testMap: filePathTestCases,
  ).runTests();
}

void toFilePathTest() {
  SerializableListTester<String>(
    testGroupName: 'NoOutput File Commands',
    mainTestName: 'toFilePath',
    mode: ListTesterMode.noOutput,
    testFunction: (value, tester) {
      expect(value, value);
      expect(value.length > 3, true);
    },
    testMap: commonTestCases,
  ).runTests();
}

void toFileNameTest() {
  SerializableListTester<String>(
    testGroupName: 'NoOutput File Commands',
    mainTestName: 'toFileName',
    mode: ListTesterMode.noOutput,
    testFunction: (value, tester) {
      tester.addTestValue(toFilename(value));
      expect(value, value);
      expect(value.length > 3, true);
    },
    testMap: commonTestCases,
  ).runTests();
}
