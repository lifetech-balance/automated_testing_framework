import 'package:automated_testing_framework/automated_testing_framework.dart';
import 'package:flutter/material.dart';
import 'package:json_class/json_class.dart';

/// Test step that asserts that the value equals (or does not equal) a specific
/// value.
class AssertValueStep extends TestRunnerStep {
  AssertValueStep({
    required this.caseSensitive,
    required this.equals,
    required this.testableId,
    this.timeout,
    required this.value,
  }) : assert(testableId.isNotEmpty == true);

  static const id = 'assert_value';

  static List<String> get behaviorDrivenDescriptions => List.unmodifiable([
        "assert that the `{{testableId}}` widget's value `{{equals}}` `null` and fail if the widget cannot be found in `{{timeout}}` seconds.",
        "assert that the `{{testableId}}` widget's value `{{equals}}` `null`.",
        "assert that the `{{testableId}}` widget's value `{{equals}}` `{{value}}` using a case `{{caseSensitive}}` comparison and fail if the widget cannot be found in `{{timeout}}` seconds.",
        "assert that the `{{testableId}}` widget's value `{{equals}}` `{{value}}` using a case `{{caseSensitive}}` comparison.",
      ]);

  /// Set to [true] if the comparison should be case sensitive.  Set to [false]
  /// to allow the comparison to be case insensitive.
  final bool caseSensitive;

  /// Set to [true] if the value from the [Testable] must equal the set [value].
  /// Set to [false] if the value from the [Testable] must not equal the
  /// [value].
  final bool equals;

  /// The id of the [Testable] widget to interact with.
  final String testableId;

  /// The maximum amount of time this step will wait while searching for the
  /// [Testable] on the widget tree.
  final Duration? timeout;

  /// The [value] to test againt when comparing the [Testable]'s value.
  final String? value;

  @override
  String get stepId => id;

  /// Creates an instance from a JSON-like map structure.  This expects the
  /// following format:
  ///
  /// ```json
  /// {
  ///   "caseSensitive": <bool>,
  ///   "equals": <bool>,
  ///   "testableId": <String>,
  ///   "timeout": <number>,
  ///   "value": <String>
  /// }
  /// ```
  ///
  /// See also:
  /// * [JsonClass.parseBool]
  /// * [JsonClass.parseDurationFromSeconds]
  static AssertValueStep? fromDynamic(dynamic map) {
    AssertValueStep? result;

    if (map != null) {
      result = AssertValueStep(
        caseSensitive: map['caseSensitive'] == null
            ? true
            : JsonClass.parseBool(map['caseSensitive']),
        equals:
            map['equals'] == null ? true : JsonClass.parseBool(map['equals']),
        testableId: map['testableId']!,
        timeout: JsonClass.parseDurationFromSeconds(map['timeout']),
        value: map['value']?.toString(),
      );
    }

    return result;
  }

  /// Executes the step.  This will first look for the [Testable], get the value
  /// from the [Testable], then compare it against the set [value].
  @override
  Future<void> execute({
    required CancelToken cancelToken,
    required TestReport report,
    required TestController tester,
  }) async {
    final testableId = tester.resolveVariable(this.testableId);
    final value = tester.resolveVariable(this.value)?.toString();
    assert(testableId?.isNotEmpty == true);

    final name = "$id('$testableId', '$value', '$equals', '$caseSensitive')";
    log(
      name,
      tester: tester,
    );
    final finder = await waitFor(
      testableId,
      cancelToken: cancelToken,
      tester: tester,
      timeout: timeout,
    );

    await sleep(
      tester.delays.postFoundWidget,
      cancelStream: cancelToken.stream,
      tester: tester,
    );

    if (cancelToken.cancelled == true) {
      throw Exception('[CANCELLED]: step was cancelled by the test');
    }
    final widgetFinder = finder.evaluate();
    var match = false;
    dynamic actual;
    if (widgetFinder.isNotEmpty == true) {
      final element = widgetFinder.first as StatefulElement;

      final state = element.state;
      if (state is TestableState) {
        try {
          actual = state.onRequestValue!();
          if (equals ==
              (caseSensitive == true
                  ? (actual?.toString() == value)
                  : (actual?.toString().toLowerCase() ==
                      value?.toString().toLowerCase()))) {
            match = true;
          }
        } catch (e) {
          throw Exception(
            'testableId: [$testableId] -- could not locate Testable with a functional [onRequestValue] method.',
          );
        }
      }
    }
    if (match != true) {
      throw Exception(
        'testableId: [$testableId] -- actualValue: [$actual] ${equals == true ? '!=' : '=='} [$value] (caseSensitive = [$caseSensitive]).',
      );
    }
  }

  @override
  String getBehaviorDrivenDescription(TestController tester) {
    String result;

    if (timeout == null) {
      if (value == null) {
        result = behaviorDrivenDescriptions[1];
      } else {
        result = behaviorDrivenDescriptions[3];
      }
    } else {
      if (value == null) {
        result = behaviorDrivenDescriptions[0];
      } else {
        result = behaviorDrivenDescriptions[2];
      }
      result = result.replaceAll(
        '{{timeout}}',
        timeout!.inSeconds.toString(),
      );
    }

    result = result.replaceAll(
      '{{caseSensitive}}',
      caseSensitive ? 'sensitive' : 'insensitive',
    );
    result = result.replaceAll(
      '{{equals}}',
      equals ? 'equals' : 'does not equal',
    );
    result = result.replaceAll('{{testableId}}', testableId);
    result = result.replaceAll('{{value}}', value ?? 'null');

    return result;
  }

  /// Overidden to ignore the delay
  @override
  Future<void> postStepSleep(Duration duration) async {}

  /// Converts this to a JSON compatible map.  For a description of the format,
  /// see [fromDynamic].
  @override
  Map<String, dynamic> toJson() => {
        'caseSensitive': caseSensitive,
        'equals': equals,
        'testableId': testableId,
        'timeout': timeout?.inSeconds,
        'value': value,
      };
}
