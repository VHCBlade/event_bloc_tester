## 0.1.6

* Added noOutput testMode for cases where no output is required
* Applied Very Good Analysis and applied the suggested changes

## 0.1.5

* Fixed Issue causing test and actual to be mixed up when running in testMode

## 0.1.4

* Removed Flutter dependency from event_bloc_tester

## 0.1.3

* Added ListTesterMode.auto that will automatically generateOutput or testOutput based on the presence of the corresponding test file.

## 0.1.2+1

* Fixed issue where testing output with SerializableListWidgetTester would run indefinitely

## 0.1.2

* Refactored SerializableListTester to have some functionality be in SerializableListTesterMixin
* Added SerializableListWidgetTester

## 0.1.1

* Added Special Error for when the generated test output isn't found.

## 0.1.0

* Initial Version!
