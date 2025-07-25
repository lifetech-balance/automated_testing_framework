import 'package:automated_testing_framework/automated_testing_framework.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:static_translations/static_translations.dart';

import '../../tinycolor/tinycolor.dart';

/// Page that displays all the test steps for the current test.  This will allow
/// the reordering, clearing, editing, and saving of the steps w/in a current
/// test.
class TestableStepsPage extends StatefulWidget {
  TestableStepsPage({
    this.error,
    this.image,
    Key? key,
    this.scrollableId,
    this.testableId,
    this.types,
    this.value,
  }) : super(key: key);

  final String? error;
  final Uint8List? image;
  final String? scrollableId;
  final String? testableId;
  final List<TestableType>? types;
  final dynamic value;

  @override
  _TestableStepsPageState createState() => _TestableStepsPageState();
}

class _TestableStepsPageState extends State<TestableStepsPage>
    with ResetNavigationStateMixin {
  final List<AvailableTestStep> _globalSteps = [];
  final List<AvailableTestStep> _widgetSteps = [];

  @override
  void initState() {
    super.initState();

    final registry = TestStepRegistry.of(context);
    final availSteps = registry.availableSteps;

    availSteps
        .where((step) => step.widgetless == true)
        .forEach((step) => _globalSteps.add(step));

    availSteps.where((step) => step.widgetless == false).forEach((step) {
      if (step.supports(widget.types)) {
        _widgetSteps.add(step);
      }
    });
  }

  Map<String, dynamic> _createValues(AvailableTestStep step) => step.minify({
        'error': widget.error,
        'testableId': widget.testableId,
        'scrollableId': widget.scrollableId,
        'value': widget.value,
      });

  Widget _buildTestAction(
    BuildContext context,
    AvailableTestStep step,
  ) {
    final testController = TestController.of(context);
    final theme = TestRunner.of(context)?.theme ?? Theme.of(context);
    final translator = Translator.of(context);

    return ListTile(
      onTap: () async {
        final values = await Navigator.of(context).push(
          MaterialPageRoute<Map<String, dynamic>>(
            builder: (BuildContext context) => TestableFormPage(
              form: step.form,
              values: _createValues(step),
            ),
          ),
        );

        if (values != null) {
          testController!.currentTest.addTestStep(TestStep(
            id: step.id,
            image: step.widgetless == true ? null : widget.image,
            values: step.minify(values),
          ));
        }

        if (mounted == true) {
          setState(() {});
        }
      },
      title: Text(translator.translate(step.title)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (step.quickAddValues != null)
            Tooltip(
              message: translator
                  .translate(TestTranslations.atf_tooltip_add_and_run),
              child: IconButton(
                color: theme.iconTheme.color,
                icon: const Icon(
                  Icons.play_circle_filled,
                ),
                onPressed: () async {
                  final values = <String, dynamic>{}
                    ..addAll(_createValues(step))
                    ..addAll(step.quickAddValues!);
                  final testStep = TestStep(
                    id: step.id,
                    image: step.widgetless == true ? null : widget.image,
                    values: step.minify(values),
                  );
                  testController!.currentTest.addTestStep(testStep);

                  if (mounted == true) {
                    Navigator.of(context).pop();
                    // Wait for the back to complete before kicking off the step
                    await Future.delayed(const Duration(milliseconds: 300));
                    await testController.execute(
                      reset: false,
                      steps: [testStep],
                      submitReport: false,
                      version: 0,
                    );
                  }
                },
              ),
            ),
          if (step.quickAddValues != null)
            Tooltip(
              message: translator.translate(TestTranslations.atf_quick_add),
              child: IconButton(
                color: theme.iconTheme.color,
                icon: const Icon(
                  Icons.add_circle,
                ),
                onPressed: () {
                  final values = <String, dynamic>{}
                    ..addAll(_createValues(step))
                    ..addAll(step.quickAddValues!);
                  testController!.currentTest.addTestStep(TestStep(
                    id: step.id,
                    image: step.widgetless == true ? null : widget.image,
                    values: step.minify(values),
                  ));

                  final snackBar = SnackBar(
                    content: Text(
                      translator.translate(
                        TestTranslations.atf_added_step_action,
                        {
                          'step': translator.translate(step.title),
                        },
                      ),
                    ),
                    duration: const Duration(seconds: 1),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  if (mounted == true) {
                    setState(() {});
                  }
                },
              ),
            ),
          IconButton(
            color: theme.iconTheme.color,
            icon: const Icon(
              Icons.help,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) => Theme(
                  data: theme,
                  child: AlertDialog(
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          translator
                              .translate(TestTranslations.atf_button_close),
                        ),
                      ),
                    ],
                    content: Text(translator.translate(step.help)),
                    title: Text(translator.translate(step.title)),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final testController = TestController.of(context);
    final testableRenderController = TestableRenderController.of(context);
    final theme = TestRunner.of(context)?.theme ?? Theme.of(context);
    final translator = Translator.of(context);
    final wide = mq.size.width >= 600.0;

    return Theme(
      data: theme,
      child: Builder(
        builder: (BuildContext context) => Scaffold(
          appBar: AppBar(
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () async {
                  await showDialog(
                    context: context,
                    builder: (BuildContext context) => Theme(
                      data: theme,
                      child: AlertDialog(
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              translator.translate(
                                TestTranslations.atf_button_ok,
                              ),
                            ),
                          ),
                        ],
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            FormField<bool>(
                              builder: (FormFieldState<bool> state) =>
                                  SwitchListTile.adaptive(
                                onChanged: (value) {
                                  testableRenderController.showGlobalOverlay =
                                      value;
                                  state.setState(() {});
                                },
                                title: Text(
                                  translator.translate(
                                    TestTranslations.atf_show_global_overlays,
                                  ),
                                ),
                                value:
                                    testableRenderController.showGlobalOverlay,
                              ),
                            ),
                          ],
                        ),
                        contentPadding: const EdgeInsets.all(16.0),
                        title: Text(
                          translator.translate(
                            TestTranslations.atf_test_options,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.bug_report),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (BuildContext context) => AvailableTestsPage(),
                  ),
                ),
                tooltip: translator.translate(
                  TestTranslations.atf_open_tests_page,
                ),
              ),
            ],
            title: Text(
              translator.translate(
                TestTranslations.atf_available_test_steps,
              ),
            ),
          ),
          body: Material(
            child: Builder(
              builder: (BuildContext context) => SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: <Widget>[
                          if (widget.testableId?.isNotEmpty == true) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  16.0, 16.0, 16.0, 0.0),
                              child: Text(
                                translator
                                    .translate(TestTranslations.atf_widget),
                                style: theme.textTheme.titleLarge,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Flexible(
                                    child: Text(
                                      widget.testableId!,
                                      maxLines: 1,
                                      style: theme.textTheme.titleSmall,
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                      icon: const Icon(Icons.content_copy),
                                      onPressed: () {
                                        Clipboard.setData(
                                          ClipboardData(
                                            text: widget.testableId ?? '',
                                          ),
                                        );

                                        final snackBar = SnackBar(
                                          content: Text(
                                            translator.translate(
                                              TestTranslations
                                                  .atf_copied_to_clipboard,
                                            ),
                                          ),
                                          duration: const Duration(seconds: 1),
                                        );
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(snackBar);
                                      }),
                                ],
                              ),
                            ),
                          ],
                          if (widget.image != null) ...[
                            const Divider(),
                            Container(
                              alignment: Alignment.center,
                              color: theme.brightness == Brightness.dark
                                  ? TinyColor(theme.scaffoldBackgroundColor)
                                      .lighten(10)
                                      .color
                                  : TinyColor(theme.scaffoldBackgroundColor)
                                      .darken(10)
                                      .color,
                              height: 200.0,
                              child: Image.memory(
                                widget.image!,
                                fit: BoxFit.scaleDown,
                                scale: MediaQuery.of(context).devicePixelRatio,
                              ),
                            ),
                            const Divider(),
                          ],
                          if (widget.testableId?.isNotEmpty == true) ...[
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                translator.translate(
                                  TestTranslations.atf_selected_widget_steps,
                                ),
                                style: theme.textTheme.headlineSmall,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            for (var step in _widgetSteps)
                              _buildTestAction(
                                context,
                                step,
                              ),
                            const Divider(),
                          ],
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              translator.translate(
                                TestTranslations.atf_widgetless_steps,
                              ),
                              style: theme.textTheme.headlineSmall,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          for (var step in _globalSteps)
                            _buildTestAction(
                              context,
                              step,
                            ),
                          if (testController!.customRoutes.isNotEmpty ==
                              true) ...[
                            const Divider(),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                translator.translate(
                                  TestTranslations.atf_custom_pages,
                                ),
                                style: theme.textTheme.headlineSmall,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            for (var entry
                                in testController.customRoutes.entries)
                              ListTile(
                                onTap: () async {
                                  Navigator.of(context).pop();
                                  await Navigator.of(context).push(entry.value);
                                },
                                title: Text(entry.key),
                                trailing: const Icon(Icons.chevron_right),
                              ),
                          ]
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: BottomAppBar(
            color: theme.canvasColor,
            child: Container(
              alignment:
                  wide == true ? Alignment.centerRight : Alignment.center,
              height: 40.0,
              child: TextButton(
                onPressed: testController!.currentTest.steps.isEmpty == true
                    ? null
                    : () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (BuildContext context) => TestStepsPage(),
                          ),
                        );
                        if (mounted == true) {
                          setState(() {});
                        }
                      },
                child: Text(
                  translator.translate(
                    TestTranslations.atf_button_view_test_steps,
                    {
                      'count': testController.currentTest.steps.length,
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
