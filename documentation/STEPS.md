# Test Steps

## Table of Contents

* [Introduction](#introduction)
* [Working with Variables](#working-with-variables)
* [Test Step Summary](#test-step-summary)
* [Details](#details)
  * [assert_error](#assert_error)
  * [assert_semantics](#assert_semantics)
  * [assert_value](#assert_value)
  * [comment](#comment)
  * [dismiss_keyboard](#dismiss_keyboard)
  * [double_tap](#double_tap)
  * [ensure_exists](#ensure_exists)
  * [exit_app](#exit_app)
  * [go_back](#go_back)
  * [long_press](#long_press)
  * [remove_global_variable](#remove_global_variable)
  * [remove_variable](#remove_variable)
  * [screenshot](#screenshot)
  * [scroll_until_visible](#scroll_until_visible)
  * [set_global_variable](#set_global_variable)
  * [set_value](#set_value)
  * [set_variable](#set_variable)
  * [sleep](#sleep)
  * [tap](#tap)


## Introduction

The default JSON format for the test steps is as follows:
```json
{
  "id": "<Test Step ID>",
  "image": "<Optional Base64 Encoded Image>",
  "values": {
    ...
  }
}
```

The values map is step dependent.  It is always required, though may be empty for some steps.  The image is an optional base64 encoded image that the framework will display along side the step when set.

As a quick note, all data types can be string encoded or set as the native value.  So "200" and 200 are both acceptable on any number.  Likewise, for a boolean, any of the following values will evaluate to `true`: `true`, "true", 1, "1", "yes".  The string values are case-insensitive.


---

## Working with Variables

The `TestController` has the ability to provide variable definitions.  You can use the `set_variable` step to set a variable or explicitly set the variable using the `setVariable` on the current `TestController`.  Variables can be referenced using the double-curley-braces format, example: `{{myVariableName}}`.

The variables will be evaluated when the Test Step executes.


---

## Test Step Summary

Test Step IDs                                 | Description
----------------------------------------------|-------------
[assert_error](#assert_error)                 | Asserts the error message on the `Testable` equals (or does not equal) a specified value.
[assert_semantics](#assert_semantics)         | Asserts the semantics field value on the `Testable` equals a specified value.
[assert_value](#assert_value)                 | Asserts the value on the `Testable` equals (or does not equal) a specified value.
[dismiss_keyboard](#dismiss_keyboard)         | Dismisses the keyboard, if it is currently visible.  Does nothing otherwise.
[double_tap](#double_tap)                     | Executes a double tap gesture on the associated `Testable`.
[ensure_exists](#ensure_exists)               | Ensures the `Testable` exists on the widget tree.
[exit_app](#exit_app)                         | Attempts to quite the app.  This does nothing on Web.
[go_back](#go_back)                           | Hit's the app bar's "Back" button.
[long_press](#long_press)                     | Executes a long-press on the associated `Testable`.
[screenshot](#screenshot)                     | Takes a screenshot of the current screen.
[scroll_until_visible](#scroll_until_visible) | Scrolls the associated `Scrollable` until the `Testable` is visible on the screen.
[set_value](#set_value)                       | Sets the value of the `Testable`.
[set_variable](#set_variable)                 | Sets the value of to the defined key on the `TestController`.
[sleep](#sleep)                               | Sleeps for a specified number of seconds.
[tap](#tap)                                   | Executes a tap gesture on the associated `Testable`.


---
## Details

### assert_error

**How it Works**

1. Looks for the `Testable` on the widget tree.  If not found before `timeout` the step will fail.
2. Compares the error message from the `Testable` to the assigned `error`.  The step will fail if either statement is not true:
    1. The `equals` is `true` or undefined and the `Testable`'s error message does not match the `error`.
    2. The `equals` is `false` and the `Testable`'s error message does match the `error`.

**Example**

```json
{
  "id": "assert_error",
  "image": "<optional_base_64_image>",
  "values": {
    "caseSensitive": true,
    "equals": true,
    "error": "Value is required",
    "testableId": "my-text-id",
    "timeout": 10
  }
}
```

**Values**

Key             | Type    | Required | Supports Variable | Description
----------------|---------|----------|-------------------|-------------
`caseSensitive` | boolean | No       | No                | Defines whether the `equals` comparison requires case to match or will consider two values equal if only the case differs.  Defaults to `true` if not defined.
`equals`        | boolean | No       | No                | Defines whether the `Testable`'s error message must equal the `error` or must not equal the `error`.  Defaults to `true` if not defined.
`error`         | String  | Yes      | Yes               | The error message evaluate against.
`testableId`    | String  | Yes      | Yes               | The `id` of the `Testable` to evaluate the error message.
`timeout`       | integer | No       | No                | Number of seconds the step will wait for the `Testable` widget to be available on the widget tree.

---

### assert_semantics

**How it Works**

1. Will automatically fail if `kReleaseMode` is `true` as the components this step requires do not exist in Release builds.
2. Looks for the `Testable` on the widget tree.  If not found before `timeout` the step will fail.
3. Compares the `field`'s String value on the `SemanticsNode` from the `Testable` to the given `value` and will fail if they do not match.

**Example**

```json
{
  "id": "assert_semantics",
  "image": "<optional_base_64_image>",
  "values": {
    "field": "semanticNodeFieldName",
    "testableId": "my-text-id",
    "timeout": 10,
    "value": "String value for the semantic node field's value",
  }
}
```

**Values**

Key             | Type    | Required | Supports Variable | Description
----------------|---------|----------|-------------------|-------------
`field`         | boolean | Yes      | No                | Defines whether the `Testable`'s error message must equal the `error` or must not equal the `error`.  Defaults to `true` if not defined.
`testableId`    | String  | Yes      | Yes               | The `id` of the `Testable` to evaluate the error message.
`timeout`       | integer | No       | No                | Number of seconds the step will wait for the `Testable` widget to be available on the widget tree.
`value`         | String  | Yes      | Yes               | The error message evaluate against.

---

### assert_value

**How it Works**

1. Looks for the `Testable` on the widget tree.  If not found before `timeout` the step will fail.
2. Compares the value from the `Testable` to the assigned `value`.  The step will fail if either statement is not true:
    1. The `equals` is `true` or undefined and the `Testable`'s value does not match the `value`.
    2. The `equals` is `false` and the `Testable`'s value does match the `value`.

**Example**

```json
{
  "id": "assert_value",
  "image": "<optional_base_64_image>",
  "values": {
    "caseSensitive": true,
    "equals": true,
    "testableId": "my-text-id",
    "timeout": 10,
    "value": "My Expected Value"
  }
}
```

**Values**

Key             | Type    | Required | Supports Variable | Description
----------------|---------|----------|-------------------|-------------
`caseSensitive` | boolean | No       | No                | Defines whether the `equals` comparison requires case to match or will consider two values equal if only the case differs.  Defaults to `true` if not defined.
`equals`        | boolean | No       | No                | Defines whether the `Testable`'s value must equal the `value` or must not equal the `value`.  Defaults to `true` if not defined.
`testableId`    | String  | Yes      | Yes               | The `id` of the `Testable` to evaluate the value.
`timeout`       | integer | No       | Yes               | Number of seconds the step will wait for the `Testable` widget to be available on the widget tree.
`value`         | String  | Yes      | Yes               | The value to evaluate against.


---

### comment

**How it Works**

1. Simply emits the `comment` into the logs.

**Example**

```json
{
  "id": "comment",
  "values": {
    "comment": "My Comment Here"
  }
}
```

**Values**

Key       | Type   | Required | Supports Variable | Description
----------|--------|----------|-------------------|-------------
`comment` | String | Yes      | Yes               | The comment to emit to the logs.


---

### dismiss_keyboard

**How it Works**

1. Looks for the `Testable` on the widget tree.  If not found before `timeout` the step will fail.
2. Executes a Double Tap gesture on the `Testable`.

**Example**

```json
{
  "id": "dismiss_keyboard",
  "image": "<optional_base_64_image>",
  "values": {
  }
}
```

**Values**

n/a


---

### double_tap

**How it Works**

1. Looks for the `Testable` on the widget tree.  If not found before `timeout` the step will fail.
2. Executes a Double Tap gesture on the `Testable`.

**Example**

```json
{
  "id": "tap",
  "image": "<optional_base_64_image>",
  "values": {
    "testableId": "my-text-id",
    "timeout": 10
  }
}
```

**Values**

Key          | Type    | Required | Supports Variable | Description
-------------|---------|----------|-------------------|-------------
`testableId` | String  | Yes      | Yes               | The `id` of the `Testable` to evaluate the value.
`timeout`    | integer | No       | No                | Number of seconds the step will wait for the `Testable` widget to be available on the widget tree.


---

### drag

**How it Works**

1. Looks for the `Testable` on the widget tree.  If not found before `timeout` the step will fail.
2. Executes a drag gesture in the number of pixels in the horizontal direction of `dx` and the vertical direction of `dy`.

**Example**

```json
{
  "id": "drag",
  "image": "<optional_base_64_image>",
  "values": {
    "dx": -100,
    "dy": 100,
    "testableId": "my-draggable-id",
    "timeout": 10
  }
}
```

**Values**

Key          | Type    | Required | Supports Variable | Description
-------------|---------|----------|-------------------|-------------
`dx`         | number  | no       | Yes               | The number of pixels to scroll in the horizontal direction.
`dy`         | number  | no       | Yes               | The number of pixels to scroll in the vertical direction.
`testableId` | String  | Yes      | Yes               | The `id` of the `Testable` to evaluate the value.
`timeout`    | integer | No       | No                | Number of seconds the step will wait for the `Testable` widget to be available on the widget tree.


---

### ensure_exists

**How it Works**

1. Looks for the `Testable` on the widget tree.  If not found before `timeout` the step will fail.

**Example**

```json
{
  "id": "ensure_exists",
  "image": "<optional_base_64_image>",
  "values": {
    "testableId": "my-text-id",
    "timeout": 10
  }
}
```

**Values**

Key          | Type    | Required | Supports Variable | Description
-------------|---------|----------|-------------------|-------------
`testableId` | String  | Yes      | Yes               | The `id` of the `Testable` to evaluate the value.
`timeout`    | integer | No       | No                | Number of seconds the step will wait for the `Testable` widget to be available on the widget tree.


---

### exit_app

**How it Works**

1. Attempts to exit the application.  Does nothing on Web.

**Example**

```json
{
  "id": "exit_app",
  "image": "<optional_base_64_image>",
  "values": {
  }
}
```

**Values**

n/a


---

### go_back

**How it Works**

1. Looks for the either a Material back button or a Cupertino one.
2. If found, the step will execute a Tap gesture on the button; fails if not found.

**Example**

```json
{
  "id": "go_back",
  "image": "<optional_base_64_image>",
  "values": {
  }
}
```

**Values**

n/a


---

### long_press

**How it Works**

1. Looks for the `Testable` on the widget tree.  If not found before `timeout` the step will fail.
2. Executes a Long Press gesture on the `Testable`.

**Example**

```json
{
  "id": "long_press",
  "image": "<optional_base_64_image>",
  "values": {
    "testableId": "my-text-id",
    "timeout": 10
  }
}
```

**Values**

Key          | Type    | Required | Supports Variable | Description
-------------|---------|----------|-------------------|-------------
`testableId` | String  | Yes      | Yes               | The `id` of the `Testable` to evaluate the value.
`timeout`    | integer | No       | No                | Number of seconds the step will wait for the `Testable` widget to be available on the widget tree.


---


### remove_global_variable

**How it Works**

1. Removes global variable named `variableName`.

**Example**

```json
{
  "id": "remove_global_variable",
  "image": "<optional_base_64_image>",
  "values": {
    "variableName": "my-variable-key"
  }
}
```

**Values**

Key            | Type    | Required | Supports Variable | Description
---------------|---------|----------|-------------------|-------------
`variableName` | String  | Yes      | Yes               | The name of the variable to set.


---


### remove_variable

**How it Works**

1. Removes the variable named `variableName` from the current test run.

**Example**

```json
{
  "id": "remove_variable",
  "image": "<optional_base_64_image>",
  "values": {
    "variableName": "my-variable-key"
  }
}
```

**Values**

Key            | Type    | Required | Supports Variable | Description
---------------|---------|----------|-------------------|-------------
`variableName` | String  | Yes      | Yes               | The name of the variable to remove.


---

### screenshot

**How it Works**

1. If running on Web, this does nothing.
2. If the `disable_screen_shots` variable on the `TestController` is `true`, this does nothing.
3. Otherwise, takes a screenshot and saves it in memory on the current test report.

**Example**

```json
{
  "id": "screenshot",
  "image": "<optional_base_64_image>",
  "values": {
    "goldenCompatible": true,
    "imageId": "my_image_id"
  }
}
```

**Values**


Key                | Type    | Required | Supports Variable | Description
-------------------|---------|----------|-------------------|-------------
`goldenCompatible` | bool    | No       | No                | Defaults to `true`.  Set to `false` if the image contains dynamic information that is known to be incompatible with automated tests.
`imageId`          | String  | No       | Yes               | Defaults to `screenshot_$index` when not set.


---

### scroll_until_visible

**How it Works**

1. If `scrollableId` is defined, the step looks for a widget with a `ValueKey` containing the `scrollableId` as the value.  Otherwise, the step will look for the closest-to-the-root `Scrollable` widget and use that widget.  If neither can be found before `timeout` is exceeded then the step will fail.
2. Using the `Scrollable` found in #1, the step will scroll by `increment` until the `Testable` with `testableId` is found.  If `timeout` is exceeded before the `Testable` is found then the step will fail.
3. Once the `Testable` is found, the step will request that the `Scrollable` scroll it into view.

**Example**

```json
{
  "id": "scroll_until_visible",
  "image": "<optional_base_64_image>",
  "values": {
    "increment": -200,
    "testableId": "button_one"
  }
}
```

**Values**

Key            | Type    | Required | Supports Variable | Description
---------------|---------|----------|-------------------|-------------
`increment`    | number  | No       | Yes               | The number of pixels to scroll by with each scroll iteration.  This should be >= 100 or else iOS's "scroll friction" will result in the scroll not really happening.  Set to a positive value to scroll forward and a negative value to scroll backwards. Defaults to 200 when not set.
`scrollableId` | String  | No       | Yes               | The identifier of a `Scrollable`'s `ValueKey`.  This is required when there are multiple scrolling elements (like a Netflix style list of scrollable rows).  When not set, the tester will attempt to scroll the first `Scrollable` it finds.  
`testableId`   | String  | Yes      | Yes               | The `id` of the `Testable` to scroll into the view.
`timeout`      | integer | No       | No                | Number of seconds the step will execute and attempt to find the `Testable` widget before failing with a timeout.


---

### set_global_variable

**How it Works**

1. Sets the `value` to the global `variableName` on the `TestController` so that it is accessible by all tests.

**Example**

```json
{
  "id": "set_global_variable",
  "image": "<optional_base_64_image>",
  "values": {
    "type": "String",
    "value": "My Set Value",
    "variableName": "my-variable-key"
  }
}
```

**Values**

Key            | Type    | Required | Supports Variable | Description
---------------|---------|----------|-------------------|-------------
`type`         | String  | No       | Yes               | Defines the data type to set.  This can be `String`, `int`, `double`, or `bool`.  Defaults to `String` if not set.
`value`        | String  | No       | Yes               | The value to set on the variable.
`variableName` | String  | Yes      | Yes               | The name of the variable to set.


---

### set_value

**How it Works**

1. Looks for the `Testable` on the widget tree.  If not found before `timeout` the step will fail.
2. Sets the value on the `Testable` to the given `value`.

**Example**

```json
{
  "id": "set_value",
  "image": "<optional_base_64_image>",
  "values": {
    "testableId": "my-text-id",
    "timeout": 10,
    "type": "String",
    "value": "My Set Value"
  }
}
```

**Values**

Key          | Type    | Required | Supports Variable | Description
-------------|---------|----------|-------------------|-------------
`testableId` | String  | Yes      | Yes               | The `id` of the `Testable` to evaluate the value.
`timeout`    | integer | No       | No                | Number of seconds the step will wait for the `Testable` widget to be available on the widget tree.
`type`       | String  | No       | Yes               | Defines the data type to set.  This can be `String`, `int`, `double`, or `bool`.  Defaults to `String` if not set.
`value`      | String  | No       | Yes               | The value to evaluate against.


---

### set_variable

**How it Works**

1. Sets the `value` to the current test's `variableName` on the `TestController`.

**Example**

```json
{
  "id": "set_variable",
  "image": "<optional_base_64_image>",
  "values": {
    "type": "String",
    "value": "My Set Value",
    "variableName": "my-variable-key"
  }
}
```

**Values**

Key            | Type    | Required | Supports Variable | Description
---------------|---------|----------|-------------------|-------------
`type`         | String  | No       | Yes               | Defines the data type to set.  This can be `String`, `int`, `double`, or `bool`.  Defaults to `String` if not set.
`value`        | String  | No       | Yes               | The value to set on the variable.
`variableName` | String  | Yes      | Yes               | The name of the variable to set.


---

### sleep

**How it Works**

1. Sleep (pause) the test for `timeout` seconds.

**Example**

```json
{
  "id": "sleep",
  "image": "<optional_base_64_image>",
  "values": {
    "timeout": 10
  }
}
```

**Values**

Key          | Type    | Required | Supports Variable | Description
-------------|---------|----------|-------------------|-------------
`timeout`    | integer | No       | No                | Number of seconds the step will sleep / pause for.


---

### tap

**How it Works**

1. Looks for the `Testable` on the widget tree.  If not found before `timeout` the step will fail.
2. Executes a Tap gesture on the `Testable`.

**Example**

```json
{
  "id": "tap",
  "image": "<optional_base_64_image>",
  "values": {
    "testableId": "my-text-id",
    "timeout": 10
  }
}
```

**Values**

Key          | Type    | Required | Supports Variable | Description
-------------|---------|----------|-------------------|-------------
`testableId` | String  | Yes      | Yes               | The `id` of the `Testable` to evaluate the value.
`timeout`    | integer | No       | No                | Number of seconds the step will wait for the `Testable` widget to be available on the widget tree.

