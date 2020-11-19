import 'dart:async';

import 'package:pusher_websocket/src/channel/impl/channel_manger.dart';
import 'package:pusher_websocket/src/connection/connection.dart';
import 'package:pusher_websocket/src/connection/websocket/web_socket_client_wrapper.dart';
import 'package:pusher_websocket/src/connection/websocket/web_socket_listener.dart';
import 'package:pusher_websocket/src/pusher_options.dart';
import 'package:synchronized/synchronized.dart';
import 'package:synchronized/extension.dart';

class Factory {
  final eventLock = Lock();

  Future<void> queueOnEventThread(final Function() r) async {
    return synchronized(() async {
      scheduleMicrotask(() => r.call());
    });
  }

  WebSocketClientWrapper newWebSocketClientWrapper(
      final Uri uri, final WebSocketListener webSocketListener) {
    return WebSocketClientWrapper(uri, webSocketListener);
  }

  Connection getConnection(String apiKey, PusherOptions pusherOptions) {}

  ChannelManager getChannelManger() {}
}
