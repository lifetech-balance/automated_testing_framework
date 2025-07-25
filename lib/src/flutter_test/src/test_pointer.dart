// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

/// A class for generating coherent artificial pointer events.
///
/// You can use this to manually simulate individual events, but the simplest
/// way to generate coherent gestures is to use [TestGesture].
class TestPointer {
  /// Creates a [TestPointer]. By default, the pointer identifier used is 1,
  /// however this can be overridden by providing an argument to the
  /// constructor.
  ///
  /// Multiple [TestPointer]s created with the same pointer identifier will
  /// interfere with each other if they are used in parallel.
  TestPointer([
    this.pointer = 1,
    this.kind = PointerDeviceKind.touch,
    this._device,
    int buttons = kPrimaryButton,
  ]) : _buttons = buttons {
    switch (kind) {
      case PointerDeviceKind.mouse:
        _device ??= 1;
        break;
      case PointerDeviceKind.stylus:
      case PointerDeviceKind.invertedStylus:
      case PointerDeviceKind.trackpad:
      case PointerDeviceKind.touch:
      case PointerDeviceKind.unknown:
        _device ??= 0;
        break;
    }
  }

  /// The device identifier used for events generated by this object.
  ///
  /// Set when the object is constructed. Defaults to 1 if the [kind] is
  /// [PointerDeviceKind.mouse], and 0 otherwise.
  int? get device => _device;
  int? _device;

  /// The pointer identifier used for events generated by this object.
  ///
  /// Set when the object is constructed. Defaults to 1.
  final int pointer;

  /// The kind of pointing device to simulate. Defaults to
  /// [PointerDeviceKind.touch].
  final PointerDeviceKind kind;

  /// The kind of buttons to simulate on Down and Move events. Defaults to
  /// [kPrimaryButton].
  int get buttons => _buttons;
  int _buttons;

  /// Whether the pointer simulated by this object is currently down.
  ///
  /// A pointer is released (goes up) by calling [up] or [cancel].
  ///
  /// Once a pointer is released, it can no longer generate events.
  bool get isDown => _isDown;
  bool _isDown = false;

  /// The position of the last event sent by this object.
  ///
  /// If no event has ever been sent by this object, returns null.
  Offset? get location => _location;
  Offset? _location;

  /// If a custom event is created outside of this class, this function is used
  /// to set the [isDown].
  bool setDownInfo(
    PointerEvent event,
    Offset newLocation, {
    int? buttons,
  }) {
    _location = newLocation;
    if (buttons != null) _buttons = buttons;
    switch (event.runtimeType) {
      case PointerDownEvent:
        assert(!isDown);
        _isDown = true;
        break;
      case PointerUpEvent:
      case PointerCancelEvent:
        assert(isDown);
        _isDown = false;
        break;
      default:
        break;
    }
    return isDown;
  }

  /// Create a [PointerDownEvent] at the given location.
  ///
  /// By default, the time stamp on the event is [Duration.zero]. You can give a
  /// specific time stamp by passing the `timeStamp` argument.
  ///
  /// By default, the set of buttons in the last down or move event is used.
  /// You can give a specific set of buttons by passing the `buttons` argument.
  PointerDownEvent down(
    Offset newLocation, {
    Duration timeStamp = Duration.zero,
    int? buttons,
  }) {
    assert(!isDown);
    _isDown = true;
    _location = newLocation;
    if (buttons != null) _buttons = buttons;
    return PointerDownEvent(
      timeStamp: timeStamp,
      kind: kind,
      device: _device!,
      pointer: pointer,
      position: location!,
      buttons: _buttons,
    );
  }

  /// Create a [PointerMoveEvent] to the given location.
  ///
  /// By default, the time stamp on the event is [Duration.zero]. You can give a
  /// specific time stamp by passing the `timeStamp` argument.
  ///
  /// [isDown] must be true when this is called, since move events can only
  /// be generated when the pointer is down.
  ///
  /// By default, the set of buttons in the last down or move event is used.
  /// You can give a specific set of buttons by passing the `buttons` argument.
  PointerMoveEvent move(
    Offset newLocation, {
    Duration timeStamp = Duration.zero,
    int? buttons,
  }) {
    assert(
        isDown,
        'Move events can only be generated when the pointer is down. To '
        'create a movement event simulating a pointer move when the pointer is '
        'up, use hover() instead.');
    final delta = newLocation - location!;
    _location = newLocation;
    if (buttons != null) _buttons = buttons;
    return PointerMoveEvent(
      timeStamp: timeStamp,
      kind: kind,
      device: _device!,
      pointer: pointer,
      position: newLocation,
      delta: delta,
      buttons: _buttons,
    );
  }

  /// Create a [PointerUpEvent].
  ///
  /// By default, the time stamp on the event is [Duration.zero]. You can give a
  /// specific time stamp by passing the `timeStamp` argument.
  ///
  /// The object is no longer usable after this method has been called.
  PointerUpEvent up({Duration timeStamp = Duration.zero}) {
    assert(isDown);
    _isDown = false;
    return PointerUpEvent(
      timeStamp: timeStamp,
      kind: kind,
      device: _device!,
      pointer: pointer,
      position: location!,
    );
  }

  /// Create a [PointerCancelEvent].
  ///
  /// By default, the time stamp on the event is [Duration.zero]. You can give a
  /// specific time stamp by passing the `timeStamp` argument.
  ///
  /// The object is no longer usable after this method has been called.
  PointerCancelEvent cancel({Duration timeStamp = Duration.zero}) {
    assert(isDown);
    _isDown = false;
    return PointerCancelEvent(
      timeStamp: timeStamp,
      kind: kind,
      device: _device!,
      pointer: pointer,
      position: location!,
    );
  }

  /// Create a [PointerAddedEvent] with the [PointerDeviceKind] the pointer was
  /// created with.
  ///
  /// By default, the time stamp on the event is [Duration.zero]. You can give a
  /// specific time stamp by passing the `timeStamp` argument.
  PointerAddedEvent addPointer({
    Duration timeStamp = Duration.zero,
    Offset? location,
  }) {
    _location = location ?? _location;
    return PointerAddedEvent(
      timeStamp: timeStamp,
      kind: kind,
      device: _device!,
      position: _location ?? Offset.zero,
    );
  }

  /// Create a [PointerRemovedEvent] with the [PointerDeviceKind] the pointer
  /// was created with.
  ///
  /// By default, the time stamp on the event is [Duration.zero]. You can give a
  /// specific time stamp by passing the `timeStamp` argument.
  PointerRemovedEvent removePointer({
    Duration timeStamp = Duration.zero,
    Offset? location,
  }) {
    _location = location ?? _location;
    return PointerRemovedEvent(
      timeStamp: timeStamp,
      kind: kind,
      device: _device!,
      position: _location ?? Offset.zero,
    );
  }

  /// Create a [PointerHoverEvent] to the given location.
  ///
  /// By default, the time stamp on the event is [Duration.zero]. You can give a
  /// specific time stamp by passing the `timeStamp` argument.
  ///
  /// [isDown] must be false, since hover events can't be sent when the pointer
  /// is up.
  PointerHoverEvent hover(
    Offset newLocation, {
    Duration timeStamp = Duration.zero,
  }) {
    assert(
        !isDown,
        'Hover events can only be generated when the pointer is up. To '
        'simulate movement when the pointer is down, use move() instead.');
    assert(kind != PointerDeviceKind.touch,
        "Touch pointers can't generate hover events");
    final delta = location != null ? newLocation - location! : Offset.zero;
    _location = newLocation;
    return PointerHoverEvent(
      timeStamp: timeStamp,
      kind: kind,
      device: _device!,
      position: newLocation,
      delta: delta,
    );
  }

  /// Create a [PointerScrollEvent] (e.g., scroll wheel scroll; not finger-drag
  /// scroll) with the given delta.
  ///
  /// By default, the time stamp on the event is [Duration.zero]. You can give a
  /// specific time stamp by passing the `timeStamp` argument.
  PointerScrollEvent scroll(
    Offset scrollDelta, {
    Duration timeStamp = Duration.zero,
  }) {
    assert(kind != PointerDeviceKind.touch,
        "Touch pointers can't generate pointer signal events");
    return PointerScrollEvent(
      timeStamp: timeStamp,
      kind: kind,
      device: _device!,
      position: location!,
      scrollDelta: scrollDelta,
    );
  }
}

/// Signature for a callback that can dispatch events and returns a future that
/// completes when the event dispatch is complete.
typedef EventDispatcher = Future<void> Function(
    PointerEvent event, HitTestResult? result);

/// Signature for callbacks that perform hit-testing at a given location.
typedef HitTester = HitTestResult Function(Offset location);

/// A class for performing gestures in tests.
///
/// The simplest way to create a [TestGesture] is to call
/// [WidgetTester.startGesture].
class TestGesture {
  /// Create a [TestGesture] without dispatching any events from it.
  /// The [TestGesture] can then be manipulated to perform future actions.
  ///
  /// By default, the pointer identifier used is 1. This can be overridden by
  /// providing the `pointer` argument.
  ///
  /// A function to use for hit testing must be provided via the `hitTester`
  /// argument, and a function to use for dispatching events must be provided
  /// via the `dispatcher` argument.
  ///
  /// The device `kind` defaults to [PointerDeviceKind.touch], but move events
  /// when the pointer is "up" require a kind other than
  /// [PointerDeviceKind.touch], like [PointerDeviceKind.mouse], for example,
  /// because touch devices can't produce movement events when they are "up".
  ///
  /// None of the arguments may be null. The `dispatcher` and `hitTester`
  /// arguments are required.
  TestGesture({
    required EventDispatcher dispatcher,
    required HitTester hitTester,
    int pointer = 1,
    PointerDeviceKind kind = PointerDeviceKind.touch,
    int? device,
    int buttons = kPrimaryButton,
  })  : _dispatcher = dispatcher,
        _hitTester = hitTester,
        _pointer = TestPointer(pointer, kind, device, buttons),
        _result = null;

  /// Dispatch a pointer down event at the given `downLocation`, caching the
  /// hit test result.
  Future<void> down(Offset downLocation,
      {Duration timeStamp = Duration.zero}) async {
    _result = _hitTester(downLocation);
    return _dispatcher(
        _pointer.down(downLocation, timeStamp: timeStamp), _result);
  }

  /// Dispatch a pointer down event at the given `downLocation`, caching the
  /// hit test result with a custom down event.
  Future<void> downWithCustomEvent(
      Offset downLocation, PointerDownEvent event) async {
    _pointer.setDownInfo(event, downLocation);
    _result = _hitTester(downLocation);
    return _dispatcher(event, _result);
  }

  final EventDispatcher _dispatcher;
  final HitTester _hitTester;
  final TestPointer _pointer;
  HitTestResult? _result;

  /// In a test, send a move event that moves the pointer by the given offset.
  @visibleForTesting
  Future<void> updateWithCustomEvent(PointerEvent event,
      {Duration timeStamp = Duration.zero}) {
    _pointer.setDownInfo(event, event.position);
    return _dispatcher(event, _result);
  }

  /// In a test, send a pointer add event for this pointer.
  Future<void> addPointer(
      {Duration timeStamp = Duration.zero, Offset? location}) {
    return _dispatcher(
        _pointer.addPointer(
            timeStamp: timeStamp, location: location ?? _pointer.location),
        null);
  }

  /// In a test, send a pointer remove event for this pointer.
  Future<void> removePointer(
      {Duration timeStamp = Duration.zero, Offset? location}) {
    return _dispatcher(
        _pointer.removePointer(
            timeStamp: timeStamp, location: location ?? _pointer.location),
        null);
  }

  /// Send a move event moving the pointer by the given offset.
  ///
  /// If the pointer is down, then a move event is dispatched. If the pointer is
  /// up, then a hover event is dispatched. Touch devices are not able to send
  /// hover events.
  Future<void> moveBy(Offset offset, {Duration timeStamp = Duration.zero}) {
    return moveTo(_pointer.location! + offset, timeStamp: timeStamp);
  }

  /// Send a move event moving the pointer to the given location.
  ///
  /// If the pointer is down, then a move event is dispatched. If the pointer is
  /// up, then a hover event is dispatched. Touch devices are not able to send
  /// hover events.
  Future<void> moveTo(Offset location, {Duration timeStamp = Duration.zero}) {
    if (_pointer._isDown) {
      assert(
          _result != null,
          'Move events with the pointer down must be preceded by a down '
          'event that captures a hit test result.');
      return _dispatcher(
          _pointer.move(location, timeStamp: timeStamp), _result);
    } else {
      assert(_pointer.kind != PointerDeviceKind.touch,
          'Touch device move events can only be sent if the pointer is down.');
      return _dispatcher(_pointer.hover(location, timeStamp: timeStamp), null);
    }
  }

  /// End the gesture by releasing the pointer.
  Future<void> up({Duration timeStamp = Duration.zero}) async {
    assert(_pointer._isDown);
    await _dispatcher(_pointer.up(timeStamp: timeStamp), _result);
    assert(!_pointer._isDown);
    _result = null;
  }

  /// End the gesture by canceling the pointer (as would happen if the
  /// system showed a modal dialog on top of the Flutter application,
  /// for instance).
  Future<void> cancel({Duration timeStamp = Duration.zero}) async {
    assert(_pointer._isDown);
    await _dispatcher(_pointer.cancel(timeStamp: timeStamp), _result);
    assert(!_pointer._isDown);
    _result = null;
  }
}
