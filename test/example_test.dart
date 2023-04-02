import 'package:event_bloc_tester/src/tester.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuple/tuple.dart';

void main() {
  group("File Commands", () {
    group("toFilePath", toFilePathTest);
    group("toFileName", toFileNameTest);
    group("createFileObject", createFileObjectTest);
  });
}

// You can have the same test cases for different functions!
Map<String, String Function()> get commonTestCases => {
      "Basic 1": () => "File",
      "Basic 2": () => "Cool",
      "WithSpaces 1": () => "Amazing File",
      "WithSpaces 2": () => "Amazing Files Here Come and Get Them",
      "Trailing Spaces": () => "Greate     ",
      "Leading Spaces": () => "      Greate",
      "MultiSpace": () => "I  put    multiple    Spaces",
      "Existing slashes": () => "wow/you/just/want///tosee/theworld/burn",
      "Space slash": () => "I / Like /// // / / random / slashes",
    };

Map<String, Tuple2<String, String> Function()> get filePathTestCases => {
      "Basic": () => const Tuple2("File", " Cool"),
      "WithSpaces": () =>
          const Tuple2("Amazing File", "Amazing Files Here Come and Get Them"),
      "Leading and Trailing Spaces": () =>
          const Tuple2("Greate     ", "      Cooler"),
      "MultiSpace and Existing Slashes": () => const Tuple2(
          "I  put    multiple    Spaces",
          "wow/you/just/want///tosee/theworld/burn"),
      "Space slash": () =>
          const Tuple2("This / slash", "I / Like /// // / / random / slashes"),
    };

void createFileObjectTest() {
  final tester = SerializableListTester<Tuple2<String, String>>(
    testGroupName: "File Commands",
    mainTestName: "createFileObject",
    // Change this value to determine whether you generate the output file or check against it.
    // mode: ListTesterMode.generateOutput,
    mode: ListTesterMode.testOutput,
    testFunction: (value, tester) {
      // You can easily do permutations like this.
      tester.addTestValue(createFileObject(value.item1, value.item2).path);
      tester.addTestValue(createFileObject(value.item2, value.item1).path);
      tester.addTestValue(createFileObject(value.item1, value.item1).path);
      tester.addTestValue(createFileObject(value.item2, value.item2).path);
    },
    testMap: filePathTestCases,
  );

  tester.runTests();
}

void toFilePathTest() {
  final tester = SerializableListTester<String>(
    testGroupName: "File Commands",
    mainTestName: "toFilePath",
    // Change this value to determine whether you generate the output file or check against it.
    // mode: ListTesterMode.generateOutput,
    mode: ListTesterMode.testOutput,
    testFunction: (value, tester) {
      tester.addTestValue(toFilePath(value));
      // You can do whatever between these two values. This is just a silly example.
      tester.addTestValue("${toFilePath(value)}.json");
    },
    testMap: commonTestCases,
  );

  tester.runTests();
}

void toFileNameTest() {
  final tester = SerializableListTester<String>(
    testGroupName: "File Commands",
    mainTestName: "toFileName",
    // Change this value to determine whether you generate the output file or check against it.
    // mode: ListTesterMode.generateOutput,
    mode: ListTesterMode.testOutput,
    testFunction: (value, tester) {
      tester.addTestValue(toFilename(value));
      // You can do whatever between these two values. This is just a silly example.
      tester.addTestValue("${toFilename(value)}.json");
    },
    testMap: commonTestCases,
  );

  tester.runTests();
}
