import 'package:automated_testing_framework/automated_testing_framework.dart';
import 'package:flutter/material.dart';
import 'package:json_class/json_class.dart';

/// Sets a value on the identified [Testable].
class SetValueStep extends TestRunnerStep {
  SetValueStep({
    required this.testableId,
    this.timeout,
    String type = 'String',
    required this.value,
  })  : assert(testableId.isNotEmpty == true),
        assert(type == 'bool' ||
            type == 'double' ||
            type == 'int' ||
            type == 'String'),
        type = type;

  static const id = 'set_value';

  static List<String> get behaviorDrivenDescriptions => List.unmodifiable([
        "set the `{{testableId}}` widget's value to `null` and fail if the widget cannot be found in `{{timeout}}` seconds.",
        "set the `{{testableId}}` widget's value to `null`.",
        "set the `{{testableId}}` widget's value to `{{value}}` using a `{{type}}` type and fail if the widget cannot be found in `{{timeout}}` seconds.",
        "set the `{{testableId}}` widget's value to `{{value}}` using a `{{type}}` type.",
      ]);

  /// The id of the [Testable] widget to interact with.
  final String testableId;

  /// The maximum amount of time this step will wait while searching for the
  /// [Testable] on the widget tree.
  final Duration? timeout;

  /// The type of value to set.  This must be one of:
  /// * `bool`
  /// * `double`
  /// * `int`
  /// * `String`
  final String type;

  /// The string representation of the value to set.
  final String? value;

  @override
  String get stepId => id;

  /// Creates an instance from a JSON-like map structure.  This expects the
  /// following format:
  ///
  /// ```json
  /// {
  ///   "testableId": <String>,
  ///   "timeout": <number>,
  ///   "type": <String>,
  ///   "value": <String>
  /// }
  /// ```
  ///
  /// See also:
  /// * [JsonClass.parseDurationFromSeconds]
  static SetValueStep? fromDynamic(dynamic map) {
    SetValueStep? result;

    if (map != null) {
      result = SetValueStep(
        testableId: map['testableId']!,
        timeout: JsonClass.parseDurationFromSeconds(map['timeout']),
        type: map['type'] ?? 'String',
        value: map['value']?.toString(),
      );
    }

    return result;
  }

  /// Attempts to locate the [Testable] identified by the [testableId] and will
  /// then set the associated [value] to the found widget.
  @override
  Future<void> execute({
    required CancelToken cancelToken,
    required TestReport report,
    required TestController tester,
  }) async {
    final testableId = tester.resolveVariable(this.testableId);
    final type = tester.resolveVariable(this.type);
    final value = tester.resolveVariable(this.value)?.toString();

    assert(testableId?.isNotEmpty == true);
    assert(type == 'bool' ||
        type == 'double' ||
        type == 'int' ||
        type == 'String');
    final name = "$id('$testableId', '$type', '$value')";

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

    dynamic typedValue;
    switch (type) {
      case 'bool':
        typedValue = JsonClass.parseBool(value);
        break;

      case 'double':
        typedValue = JsonClass.parseDouble(value);
        break;

      case 'int':
        typedValue = JsonClass.parseInt(value);
        break;

      case 'String':
        typedValue = value;
        break;

      default:
        throw Exception('Unknown type encountered: $type');
    }

    if (cancelToken.cancelled == true) {
      throw Exception('[CANCELLED]: step was cancelled by the test');
    }
    final widgetFinder = finder.evaluate();
    if (cancelToken.cancelled == true) {
      throw Exception('[CANCELLED]: step was cancelled by the test');
    }

    var match = false;
    if (widgetFinder.isNotEmpty == true) {
      try {
        final element = widgetFinder.first as StatefulElement;

        final state = element.state;
        if (state is TestableState) {
          state.onSetValue!(typedValue);
          match = true;
        }
      } catch (e) {
        // no-op; fail via "match != true".
      }
    }
    if (match != true) {
      throw Exception(
        'testableId: [$testableId] -- could not locate Testable with a functional [onSetValue] method.',
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

    result = result.replaceAll('{{testableId}}', testableId);
    result = result.replaceAll('{{type}}', type);
    result = result.replaceAll('{{value}}', value ?? 'null');

    return result;
  }

  /// Converts this to a JSON compatible map.  For a description of the format,
  /// see [fromDynamic].
  @override
  Map<String, dynamic> toJson() => {
        'testableId': testableId,
        'timeout': timeout?.inSeconds,
        'type': type,
        'value': value,
      };
}
