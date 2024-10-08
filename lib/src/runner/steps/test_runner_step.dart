import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:automated_testing_framework/automated_testing_framework.dart';
import 'package:flutter/material.dart';
import 'package:json_class/json_class.dart';
import 'package:logging/logging.dart';

import '../../flutter_test/flutter_test.dart' as test;
import '../overrides/override_widget_tester.dart';

/// Abstract step that all other test steps must extend.
@immutable
abstract class TestRunnerStep extends JsonClass {
  /// Returns the Behavior Driven Development description for the test step.
  /// The results of this may be in Markdown and this provides a description of
  /// the test step in a way that is more easily understood by non-developers.
  ///
  /// Variables in the step should be encoded with the mustache template format
  /// like `{{variable}}`.  Consumers of this call can match this up with the
  /// [toJson] call to convert variables to specific values.
  static final List<String> behaviorDrivenDescriptions = List.unmodifiable([
    'run an unknown step of `{{stepId}}` type and using `{{values}}` as the parameters.',
  ]);

  static final Logger _logger = Logger('TestRunnerStep');

  static final OverrideWidgetTester _driver =
      OverrideWidgetTester(WidgetsBinding.instance);

  /// Returns the function to call when logging is required
  static void _console(Object? message, [Level level = Level.INFO]) =>
      _logger.log(level, message);

  /// Returns the default timeout for the step.  Steps that should respond
  /// quickly should use a relatively low value and steps that may take a long
  /// time should return an appropriately longer time.
  Duration get defaultStepTimeout => const Duration(minutes: 1);

  /// Returns the test driver that can be used to interact with widgets.
  OverrideWidgetTester get driver => _driver;

  /// Returns the finder that can be used to locate widgets.
  test.CommonFinders get find => test.find;

  // The test step's identifier.
  String get stepId;

  /// Function that is called when the step needs to execute.
  Future<void> execute({
    required CancelToken cancelToken,
    required TestReport report,
    required TestController tester,
  });

  /// Gets the most appropriate BDD string based on the values set on the step.
  String getBehaviorDrivenDescription(TestController tester) {
    var result = behaviorDrivenDescriptions[0];

    result = result.replaceAll('{{stepId}}', stepId);
    result = result.replaceAll('{{values}}', json.encode(toJson()));

    return result;
  }

  /// Logs a message and posts it as a status update to the [TestRunner].
  @protected
  void log(
    String message, {
    required TestController tester,
  }) {
    _console(message);
    tester.status = message;
  }

  /// Gives the test step an opportunity to sleep after the step has been
  /// executed.  Steps that do not interact with the application may choose to
  /// override this and reduce or elimate the delay.
  Future<void> postStepSleep(Duration duration) async =>
      await Future.delayed(duration);

  /// Gives the test step an opportunity to sleep before the step has been
  /// executed.  Steps that do not interact with the application may choose to
  /// override this and reduce or elimate the delay.
  Future<void> preStepSleep(Duration duration) async =>
      await Future.delayed(duration);

  /// Sleeps for the defined [Duration].  This accept an optional [cancelStream]
  /// which can be used to cancel the sleep.  The [error] flag informs the
  /// sleeper about whether the duration is a standard duration or an error
  /// based timeout.
  ///
  /// The optional [message] can be used to provide more details to the sleep
  /// step.
  @protected
  Future<void> sleep(
    Duration duration, {
    required Stream<void>? cancelStream,
    bool error = false,
    String? message,
    required TestController tester,
  }) async {
    if (duration.inMilliseconds > 0) {
      // Let's reduce the number of log entries to 1 per 100ms or 10 per second.
      final calcSteps = duration.inMilliseconds / 100;

      // However, let's put sanity limits.  At lest 10 events and no more than
      // 50.
      final steps = max(5, min(50, calcSteps)).toInt();

      tester.sleep = ProgressValue(max: steps, value: 0);
      final sleepMillis = duration.inMilliseconds ~/ steps;
      var canceled = false;

      final cancelListener = cancelStream?.listen((_) {
        canceled = true;
      });
      try {
        String buildString(int count) {
          var str = '[';
          for (var i = 0; i < count; i++) {
            str += String.fromCharCode(0x2588);
          }
          for (var i = count; i < steps; i++) {
            str += '_';
          }

          str += ']';
          return str;
        }

        if (message?.isNotEmpty == true) {
          _console(message, Level.FINEST);
        } else {
          _console(
            'Sleeping for ${duration.inMilliseconds} millis...',
            Level.FINEST,
          );
        }

        for (var i = 0; i < steps; i++) {
          _console(buildString(i), Level.FINEST);
          tester.sleep = ProgressValue(
            error: error,
            max: steps,
            value: i,
          );
          await Future.delayed(Duration(milliseconds: sleepMillis));

          if (canceled == true) {
            break;
          }
        }
        _console(buildString(steps), Level.FINEST);
      } finally {
        tester.sleep = ProgressValue(
          error: error,
          max: steps,
          value: steps,
        );
        await Future.delayed(const Duration(milliseconds: 100));
        tester.sleep = null;
        await cancelListener?.cancel();
      }
    }
  }

  /// Waits for a widget with a key that has [testableId] as the value.
  @protected
  Future<test.Finder> waitFor(
    dynamic testableId, {
    required CancelToken cancelToken,
    required TestController tester,
    Duration? timeout,
  }) async {
    timeout ??= tester.delays.defaultTimeout;

    final controller = StreamController<void>.broadcast();
    final name = "waitFor('$testableId')";
    try {
      final waiter = () async {
        final end =
            DateTime.now().millisecondsSinceEpoch + timeout!.inMilliseconds;
        test.Finder? finder;
        var found = false;
        while (found != true && DateTime.now().millisecondsSinceEpoch < end) {
          try {
            finder = test.find.byKey(_TestableKey(testableId));

            final items = finder.evaluate();
            final item = items.first;
            if (item.widget is! Testable) {
              finder = test.find.descendant(
                of: finder,
                matching: find.byType(Testable),
              );
              finder.evaluate().first;
            }
            found = true;
          } catch (e) {
            if (cancelToken.cancelled == true) {
              throw Exception('[CANCELLED]: step was cancelled by the test');
            }

            await Future.delayed(const Duration(milliseconds: 100));
          }
        }

        if (found != true) {
          throw Exception('testableId: [$testableId] -- Timeout exceeded.');
        }
        return finder!;
      };

      final sleeper = sleep(
        timeout,
        cancelStream: controller.stream,
        error: true,
        message: '[$name]: ${timeout.inSeconds} seconds',
        tester: tester,
      );

      final result = await waiter();
      if (cancelToken.cancelled == true) {
        throw Exception('[CANCELLED]: step was cancelled by the test');
      }

      controller.add(null);
      await sleeper;
      if (cancelToken.cancelled == true) {
        throw Exception('[CANCELLED]: step was cancelled by the test');
      }

      try {
        final finder = result.evaluate().first;
        if (finder.widget is Testable) {
          final element = finder as StatefulElement;
          final state = element.state;
          if (state is TestableState) {
            _console('flash: [$testableId]', Level.FINEST);
            await state.flash();
            _console('flash complete: [$testableId]', Level.FINEST);
          }
        }
      } catch (e) {
        // no-op
      }

      return result;
    } catch (e) {
      log(
        'ERROR: [$name] -- $e',
        tester: tester,
      );
      rethrow;
    } finally {
      await controller.close();
    }
  }
}

class _TestableKey extends ValueKey<String> {
  _TestableKey(super.value);

  @override
  bool operator ==(Object other) {
    String? value;

    if (other is ValueKey) {
      value = other.value;
    }
    return this.value == value;
  }

  @override
  int get hashCode => Object.hash(runtimeType, value);
}
