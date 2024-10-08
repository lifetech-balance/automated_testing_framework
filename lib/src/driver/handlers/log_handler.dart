import 'dart:async';

import 'package:automated_testing_framework/automated_testing_framework.dart';
import 'package:logging/logging.dart';

class LogHandler {
  factory LogHandler() => _singleton;
  LogHandler._internal();
  static final LogHandler _singleton = LogHandler._internal();

  late TestDriver _driver;
  StreamSubscription? _logSubscription;

  set driver(TestDriver driver) => _driver = driver;

  void cancel() {
    _logSubscription?.cancel();
    _logSubscription = null;
  }

  Future<CommandAck> startStream(
    DeviceCommand command,
  ) async {
    var result = CommandAck(
      commandId: command.id,
      message: '[${command.type}]: unknown command type',
      success: false,
    );
    await _logSubscription?.cancel();
    _logSubscription = null;

    if (command is StartLogStreamCommand) {
      result = CommandAck(
        commandId: command.id,
        message: '[${command.type}]: starting log stream',
        success: true,
      );

      Logger.root.onRecord.listen((record) {
        if (_driver.state.driverName == null) {
          cancel();
        } else {
          if (record.level.value <= command.level.value) {
            final jrecord = JsonLogRecord.fromLogRecord(record);
            final response = LogResponse(record: jrecord);
            final ack = CommandAck(
              commandId: command.id,
              response: response,
            );
            _driver.communicator!.sendCommand(ack);
          }
        }
      });
    }

    return result;
  }

  Future<CommandAck> stopStream(
    DeviceCommand command,
  ) async {
    cancel();

    return CommandAck(
      commandId: command.id,
      message: '[${command.type}]: success',
      success: true,
    );
  }
}
