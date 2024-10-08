import 'package:automated_testing_framework/automated_testing_framework.dart';
import 'package:flutter/material.dart';
import 'package:json_class/json_class.dart';

import '../../flutter_test/flutter_test.dart' as test;

/// Step that will attempt to scroll another widget until it becomes visible.
class ScrollUntilVisibleStep extends TestRunnerStep {
  ScrollUntilVisibleStep({
    required this.increment,
    this.scrollableId,
    required this.testableId,
    this.timeout,
  }) : assert(testableId.isNotEmpty == true);

  static const id = 'scroll_until_visible';

  static const _scrollableIdNotNullIncrementNotNullTimeoutNotNull = 0;
  static const _scrollableIdNotNullIncrementNullTimeoutNotNull = 1;
  static const _scrollableIdNullIncrementNotNullTimeoutNotNull = 2;
  static const _scrollableIdNullIncrementNullTimeoutNotNull = 3;
  static const _scrollableIdNotNullIncrementNotNullTimeoutNull = 4;
  static const _scrollableIdNotNullIncrementNullTimeoutNull = 5;
  static const _scrollableIdNullIncrementNotNullTimeoutNull = 6;
  static const _scrollableIdNullIncrementNullTimeoutNull = 7;

  static final List<String> behaviorDrivenDescriptions = List.unmodifiable([
    'scroll the `{{scrollableId}}` widget `{{increment}}` pixels at a time until the `{{testableId}}` widget is visible and fail if it cannot be found in `{{timeout}}` seconds.',
    'scroll the `{{scrollableId}}` widget until the `{{testableId}}` widget is visible and fail if it cannot be found in `{{timeout}}` seconds.',
    'scroll `{{increment}}` pixels at a time until the `{{testableId}}` widget is visible and fail if it cannot be found in `{{timeout}}` seconds.',
    'scroll until the `{{testableId}}` widget is visible and fail if it cannot be found in `{{timeout}}` seconds.',
    'scroll the `{{scrollableId}}` widget {{increment}} pixels at a time until the `{{testableId}}` widget is visible.',
    'scroll the `{{scrollableId}}` widget until the `{{testableId}}` widget is visible.',
    'scroll `{{increment}}` pixels at a time until the `{{testableId}}` widget is visible.',
    'scroll until the `{{testableId}}` widget is visible.',
  ]);

  /// The increment in device-independent-pixels.  This may be a positive or
  /// negative number.  Positive to scroll "forward" and negative to scroll
  /// "backward".
  final String? increment;

  /// The id of the [Scrollable] widget to perform the scrolling actions on.
  final String? scrollableId;

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
  ///   "increment": <number>,
  ///   "scrollableId": <String>,
  ///   "testableId": <String>,
  ///   "timeout": <number>
  /// }
  /// ```
  ///
  /// See also:
  /// * [JsonClass.parseDouble]
  /// * [JsonClass.parseDurationFromSeconds]
  static ScrollUntilVisibleStep? fromDynamic(dynamic map) {
    ScrollUntilVisibleStep? result;

    if (map != null) {
      result = ScrollUntilVisibleStep(
        increment: map['increment']?.toString(),
        scrollableId: map['scrollableId'],
        testableId: map['testableId']!,
        timeout: JsonClass.parseDurationFromSeconds(map['timeout']),
      );
    }

    return result;
  }

  /// Executes the test step.  If the [scrollableId] is set then this will get
  /// that [Scrollable] instance and interact with it.  Otherwise, this will
  /// attempt to find the first [Scrollable] instance currently in the viewport
  /// and interact with that.
  ///
  /// For the most part, pages with a single [Scrollable] will work fine with
  /// omitting the [scrollableId].  However pages with multiple [Scrollables]
  /// (like a Netflix style stacked carousel) will require the [scrollableId] to
  /// be set in order to be able to find and interact with the inner
  /// [Scrollable] instances.
  ///
  /// The [timeout] defines how much time is allowed to pass while attempting to
  /// scroll and find the [Testable] identified by [testableId].
  @override
  Future<void> execute({
    required CancelToken cancelToken,
    required TestReport report,
    required TestController tester,
  }) async {
    final increment =
        JsonClass.parseDouble(tester.resolveVariable(this.increment)) ?? 200.0;
    final scrollableId = tester.resolveVariable(this.scrollableId);
    final testableId = tester.resolveVariable(this.testableId);
    assert(testableId?.isNotEmpty == true);

    final name = "$id('$testableId', '$scrollableId', '$increment')";
    final timeout = this.timeout ?? tester.delays.defaultTimeout;
    log(
      name,
      tester: tester,
    );

    late test.Finder finder;

    if (scrollableId == null) {
      try {
        finder = find.byType(Scrollable).first;
      } catch (e) {
        // no-op, will be handled later
      }
    } else {
      final scroller = await waitFor(
        scrollableId,
        cancelToken: cancelToken,
        tester: tester,
      );
      finder = find
          .descendant(
            of: scroller,
            matching: find.byType(Scrollable),
          )
          .first;
    }

    if (cancelToken.cancelled == true) {
      throw Exception('[CANCELLED]: step was cancelled by the test');
    }
    dynamic widget;
    try {
      widget = finder.evaluate().first.widget;
    } catch (e) {
      // no-op
    }
    if (cancelToken.cancelled == true) {
      throw Exception('[CANCELLED]: step was cancelled by the test');
    }

    if (widget == null) {
      throw Exception(
          'ScrollableId: $scrollableId -- Scrollable could not be found.');
    }

    Scrollable scrollable;
    if (widget is Scrollable) {
      scrollable = widget;
    } else {
      throw Exception(
          'ScrollableId: $scrollableId -- Widget is not a Scrollable.');
    }

    late Offset offset;
    switch (scrollable.axisDirection) {
      case AxisDirection.down:
        offset = Offset(0.0, -1.0 * increment);
        break;
      case AxisDirection.left:
        offset = Offset(increment, 0.0);
        break;
      case AxisDirection.right:
        offset = Offset(-1.0 * increment, 0.0);
        break;
      case AxisDirection.up:
        offset = Offset(0.0, increment);
        break;
    }

    final scroller = (int count) async {
      await driver.drag(finder, offset);
    };

    final start = DateTime.now().millisecondsSinceEpoch;
    final end = start + timeout.inMilliseconds;

    final widgetFinder = find.byKey(ValueKey<String?>(testableId!));
    var count = 0;
    var found = widgetFinder.evaluate().isNotEmpty == true;
    while (found != true && DateTime.now().millisecondsSinceEpoch < end) {
      if (cancelToken.cancelled == true) {
        throw Exception('[CANCELLED]: step was cancelled by the test');
      }

      var diff = end - DateTime.now().millisecondsSinceEpoch;
      tester.sleep = ProgressValue(
        error: true,
        max: 100,
        value: ((1 - (diff / timeout.inMilliseconds)) * 100).toInt(),
      );

      await scroller(count);

      diff = end - DateTime.now().millisecondsSinceEpoch;
      tester.sleep = ProgressValue(
        error: true,
        max: 100,
        value: ((1 - (diff / timeout.inMilliseconds)) *
                tester.delays.scrollIncrement.inMilliseconds)
            .toInt(),
      );
      await Future.delayed(tester.delays.scrollIncrement);
      if (cancelToken.cancelled == true) {
        throw Exception('[CANCELLED]: step was cancelled by the test');
      }

      final widgetFinder = find.byKey(ValueKey<String?>(testableId)).evaluate();

      count++;
      found = widgetFinder.isNotEmpty == true;

      diff = end - DateTime.now().millisecondsSinceEpoch;
      tester.sleep = ProgressValue(
        error: true,
        max: 100,
        value: ((1 - (diff / timeout.inMilliseconds)) * 100).toInt(),
      );
    }
    tester.sleep = null;

    if (found == true) {
      final testableFinder = await waitFor(
        testableId,
        cancelToken: cancelToken,
        tester: tester,
      );

      final widgetFinder = find
          .descendant(
            of: testableFinder,
            matching: find.byType(Stack),
          )
          .evaluate();

      final globalKey =
          widgetFinder.first.widget.key as GlobalKey<State<StatefulWidget>>;
      if (cancelToken.cancelled == true) {
        throw Exception('[CANCELLED]: step was cancelled by the test');
      }

      await Scrollable.ensureVisible(globalKey.currentContext!);
    } else {
      throw Exception(
        'testableId: [$testableId] -- time out trying to scroll widget to visible.',
      );
    }
  }

  @override
  String getBehaviorDrivenDescription(TestController tester) {
    String result;

    if (timeout == null) {
      if (scrollableId == null) {
        if (increment == null) {
          result = behaviorDrivenDescriptions[
              _scrollableIdNullIncrementNullTimeoutNull];
        } else {
          result = behaviorDrivenDescriptions[
              _scrollableIdNullIncrementNotNullTimeoutNull];
        }
      } else {
        if (increment == null) {
          result = behaviorDrivenDescriptions[
              _scrollableIdNotNullIncrementNullTimeoutNull];
        } else {
          result = behaviorDrivenDescriptions[
              _scrollableIdNotNullIncrementNotNullTimeoutNull];
        }
      }
    } else {
      if (scrollableId == null) {
        if (increment == null) {
          result = behaviorDrivenDescriptions[
              _scrollableIdNullIncrementNullTimeoutNotNull];
        } else {
          result = behaviorDrivenDescriptions[
              _scrollableIdNullIncrementNotNullTimeoutNotNull];
        }
      } else {
        if (increment == null) {
          result = behaviorDrivenDescriptions[
              _scrollableIdNotNullIncrementNullTimeoutNotNull];
        } else {
          result = behaviorDrivenDescriptions[
              _scrollableIdNotNullIncrementNotNullTimeoutNotNull];
        }
      }

      result = result.replaceAll(
        '{{timeout}}',
        timeout!.inSeconds.toString(),
      );
    }

    result = result.replaceAll('{{increment}}', increment ?? 'null');
    result = result.replaceAll('{{scrollableId}}', scrollableId ?? 'null');
    result = result.replaceAll('{{testableId}}', testableId);

    return result;
  }

  /// Converts this to a JSON compatible map.  For a description of the format,
  /// see [fromDynamic].
  @override
  Map<String, dynamic> toJson() => {
        'increment': increment,
        'scrollableId': scrollableId,
        'testableId': testableId,
        'timeout': timeout?.inSeconds,
      };
}
