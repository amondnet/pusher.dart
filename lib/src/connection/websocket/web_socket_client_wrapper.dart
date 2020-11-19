import 'dart:async';
import 'dart:io';

import 'package:pusher_websocket/src/connection/websocket/web_socket_listener.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketClientWrapper {
  final WebSocketChannel _channel;
  WebSocketListener _webSocketListener;
  StreamSubscription _streamSubscription;

  WebSocketClientWrapper(Uri uri, this._webSocketListener)
      : _channel = IOWebSocketChannel.connect(uri) {
    ;
    _streamSubscription = _channel.stream.listen(
      _webSocketListener?.onMessage,
      onDone: onDone,
      onError: _webSocketListener?.onError,
    );
  }

  /// Removes the WebSocketListener so that the underlying WebSocketClient doesn't expose any listener events.
  void removeWebSocketListener() {
    _webSocketListener = null;
  }

  void send(String message) {
    _channel.sink.add(message);
  }

  void onDone() {
    _webSocketListener.onClose(_channel.closeCode, _channel.closeReason, true);
  }

  void close() {
    _channel.sink.close();
  }
}
