import 'dart:io';

import 'package:event_bloc_tester/src/tester.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuple/tuple.dart';

void main() {
  group("Auto File Commands", () {
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
      "I am Extra": () => "Extra",
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
      "I am Extra": () => const Tuple2("Extra", "Extra"),
    };

void createFileObjectTest() {
  final tester = SerializableListTester<Tuple2<String, String>>(
    testGroupName: "Auto File Commands",
    mainTestName: "createFileObject",
    // Use auto to automatically generateOutput or testOutput base on whether an existing output exists
    mode: ListTesterMode.auto,
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

  test("Cleanup", () {
    final file =
        File("test_output/Auto/File/Commands/createFileObject/I_am_Extra.json");
    file.deleteSync();

    expect(1, 1);
  });
}

void toFilePathTest() {
  final tester = SerializableListTester<String>(
    testGroupName: "Auto File Commands",
    mainTestName: "toFilePath",
    // Use auto to automatically generateOutput or testOutput base on whether an existing output exists
    mode: ListTesterMode.auto,
    testFunction: (value, tester) {
      tester.addTestValue(toFilePath(value));
      // You can do whatever between these two values. This is just a silly example.
      tester.addTestValue("${toFilePath(value)}.json");
    },
    testMap: commonTestCases,
  );

  tester.runTests();

  test("Cleanup", () {
    final file =
        File("test_output/Auto/File/Commands/toFilePath/I_am_Extra.json");
    file.deleteSync();

    expect(1, 1);
  });
}

void toFileNameTest() {
  final tester = SerializableListTester<String>(
    testGroupName: "Auto File Commands",
    mainTestName: "toFileName",
    // Use auto to automatically generateOutput or testOutput base on whether an existing output exists
    mode: ListTesterMode.auto,
    testFunction: (value, tester) {
      tester.addTestValue(toFilename(value));
      // You can do whatever between these two values. This is just a silly example.
      tester.addTestValue("${toFilename(value)}.json");
    },
    testMap: commonTestCases,
  );

  tester.runTests();
  test("Cleanup", () {
    final file =
        File("test_output/Auto/File/Commands/toFileName/I_am_Extra.json");
    file.deleteSync();

    expect(1, 1);
  });
}
