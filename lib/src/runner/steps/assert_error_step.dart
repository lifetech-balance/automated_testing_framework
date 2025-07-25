import 'package:automated_testing_framework/automated_testing_framework.dart';
import 'package:flutter/material.dart';
import 'package:json_class/json_class.dart';

/// Test step that asserts that the error value equals (or does not equal) a
/// specific value.
class AssertErrorStep extends TestRunnerStep {
  AssertErrorStep({
    required this.caseSensitive,
    required this.equals,
    required this.error,
    required this.testableId,
    this.timeout,
  }) : assert(testableId.isNotEmpty == true);

  static const id = 'assert_error';

  static List<String> get behaviorDrivenDescriptions => List.unmodifiable([
        "assert that the `{{testableId}}` widget's error `{{equals}}` `null` and fail if the widget cannot be found in `{{timeout}}` seconds.",
        "assert that the `{{testableId}}` widget's error `{{equals}}` `null`.",
        "assert that the `{{testableId}}` widget's error `{{equals}}` `{{error}}` using a case `{{caseSensitive}}` comparison and fail if the widget cannot be found in `{{timeout}}` seconds.",
        "assert that the `{{testableId}}` widget's error `{{equals}}` `{{error}}` using a case `{{caseSensitive}}` comparison.",
      ]);

  /// Set to [true] if the comparison should be case sensitive.  Set to [false]
  /// to allow the comparison to be case insensitive.
  final bool caseSensitive;

  /// Set to [true] if the error from the widget must equal the [error] value.
  /// Set to [false] if the error from the widget must not equal the [error]
  /// value.
  final bool equals;

  /// The error value to test against.
  final String? error;

  /// The id of the [Testable] widget to interact with.
  final String testableId;

  /// The maximum amount of time this step will wait while searching for the
  /// [Testable] on the widget tree.
  final Duration? timeout;

  @override
  String get stepId => id;

  /// Creates an instance from a JSON-like map structure.  This expects the
  /// following format:
  ///
  /// ```json
  /// {
  ///   "caseSensitive": <bool>,
  ///   "equals": <bool>,
  ///   "error": <String>,
  ///   "testableId": <String>,
  ///   "timeout": <number>
  /// }
  /// ```
  ///
  /// See also:
  /// * [JsonClass.parseBool]
  /// * [JsonClass.parseDurationFromSeconds]
  static AssertErrorStep? fromDynamic(dynamic map) {
    AssertErrorStep? result;

    if (map != null) {
      result = AssertErrorStep(
        caseSensitive: map['caseSensitive'] == null
            ? true
            : JsonClass.parseBool(map['caseSensitive']),
        error: map['error'],
        equals:
            map['equals'] == null ? true : JsonClass.parseBool(map['equals']),
        testableId: map['testableId']!,
        timeout: JsonClass.parseDurationFromSeconds(map['timeout']),
      );
    }

    return result;
  }

  /// Executes the step.  This will first look for the [Testable], get the error
  /// from the [Testable], then compare it against the set [error] value.
  @override
  Future<void> execute({
    required CancelToken cancelToken,
    required TestReport report,
    required TestController tester,
  }) async {
    final error = tester.resolveVariable(this.error);
    final testableId = tester.resolveVariable(this.testableId);
    assert(testableId?.isNotEmpty == true);

    final name = "$id('$testableId', '$error', '$equals', '$caseSensitive')";
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
    if (widgetFinder.isNotEmpty == true) {
      final element = widgetFinder.first as StatefulElement;

      final state = element.state;
      if (state is TestableState) {
        try {
          final actual = state.onRequestError!();

          if (equals ==
              (caseSensitive == true
                  ? (actual?.toString() == error)
                  : (actual?.toString().toLowerCase() ==
                      error?.toString().toLowerCase()))) {
            match = true;
          } else {
            throw Exception(
              'testableId: [$testableId] -- actualValue: [$actual] ${equals == true ? '!=' : '=='} [$error] (caseSensitive = [$caseSensitive]).',
            );
          }
        } catch (e) {
          // no-op; fail via "match != true"
        }
      }
    }
    if (match != true) {
      throw Exception(
        'testableId: [$testableId] -- could not locate Testable with a functional [onRequestError] method.',
      );
    }
  }

  @override
  String getBehaviorDrivenDescription(TestController tester) {
    String result;

    if (timeout == null) {
      if (error == null) {
        result = behaviorDrivenDescriptions[1];
      } else {
        result = behaviorDrivenDescriptions[3];
      }
    } else {
      if (error == null) {
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
    result = result.replaceAll('{{value}}', error ?? 'null');

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
        'error': error,
        'testableId': testableId,
        'timeout': timeout?.inSeconds,
      };
}
