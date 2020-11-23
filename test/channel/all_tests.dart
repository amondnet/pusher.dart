import 'dart:developer';

import 'package:logging/logging.dart';

import 'channel_impl_test.dart' as channel;
import 'private_channel_impl_test.dart' as private_channel;

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((event) {
    print(event.message);
  });
  channel.main();
  private_channel.main();
}
