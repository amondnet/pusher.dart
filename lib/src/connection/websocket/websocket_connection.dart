import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:retry/retry.dart';

import '../../util/factory.dart';
import '../connection_event_listener.dart';
import '../connection_state.dart';
import '../connection_state_change.dart';
import '../impl/internal_connection.dart';
import 'web_socket_client_wrapper.dart';
import 'web_socket_listener.dart';

final _logger = Logger('WebSocketConnection');

class WebSocketConnection implements InternalConnection, WebSocketListener {
  final Factory _factory;
  final Uri _webSocketUri;
  final Map<ConnectionState, Set<ConnectionEventListener>> _eventListeners =
      <ConnectionState, Set<ConnectionEventListener>>{};
  final int maxReconnectionAttempts;
  final Duration maxReconnectionGap;
  final RetryOptions r;
  static final String INTERNAL_EVENT_PREFIX = 'pusher:';

  ConnectionState _state = ConnectionState.DISCONNECTED;
  WebSocketClientWrapper _underlyingConnection;
  int reconnectAttempts = 0;
  String _socketId;

  WebSocketConnection(final String url, this.maxReconnectionAttempts,
      this.maxReconnectionGap, this._factory)
      : _webSocketUri = Uri.parse(url),
        r = RetryOptions(
            maxAttempts: maxReconnectionAttempts, maxDelay: maxReconnectionGap);

  @override
  void bind(ConnectionState state, ConnectionEventListener eventListener) {
    _eventListeners[state].add(eventListener);
  }

  @override
  void connect() {
    _factory.queueOnEventThread(() {
      if (state == ConnectionState.DISCONNECTED) {
        _tryConnecting();
      }
    });
  }

  @override
  void disconnect() {
    _factory.queueOnEventThread(() {
      if (state == ConnectionState.CONNECTED) {
        _updateState(ConnectionState.DISCONNECTING);
        _underlyingConnection.close();
      }
    });
  }

  @override
  void onClose(final int code, final String reason, final bool remote) {
    if (state == ConnectionState.DISCONNECTED ||
        state == ConnectionState.RECONNECTING) {
      _logger.warning(
          'Received close from underlying socket when already disconnected.');
      return;
    }

    if (!shouldReconnect(code)) {
      _updateState(ConnectionState.DISCONNECTING);
    }

    //Reconnection logic
    if (state == ConnectionState.CONNECTED ||
        state == ConnectionState.CONNECTING) {
      if (reconnectAttempts < maxReconnectionAttempts) {
        _tryReconnecting();
      } else {
        _updateState(ConnectionState.DISCONNECTING);
        cancelTimeoutsAndTransitonToDisconnected();
      }
      return;
    }

    if (state == ConnectionState.DISCONNECTING) {
      cancelTimeoutsAndTransitonToDisconnected();
    }
  }

  @override
  void onError(Object error, [StackTrace stackTrace]) {
    _factory.queueOnEventThread(() {
      // Do not change connection state as Java_WebSocket will also
      // call onClose.
      // See:
      // https://github.com/leggetter/pusher-java-client/issues/8#issuecomment-16128590
      // updateState(ConnectionState.DISCONNECTED);
      sendErrorToAllListeners(
          'An exception was thrown by the websocket', null, error);
    });
  }

  @override
  void onMessage(final String message) {
    _factory.queueOnEventThread(() {
      final Map<String, String> map = jsonDecode(message);
      final event = map['event'];
      handleEvent(event, message);
    });
  }

  @override
  void sendMessage(String message) {
    _factory.queueOnEventThread(() {
      try {
        if (state == ConnectionState.CONNECTED) {
          _underlyingConnection.send(message);
        } else {
          sendErrorToAllListeners(
              'Cannot send a message while in $state state', null, null);
        }
      } catch (e) {
        sendErrorToAllListeners(
            'An exception occurred while sending message [ $message ]',
            null,
            e);
      }
    });
  }

  @override
  String get socketId => _socketId;

  @override
  ConnectionState get state => _state;

  @override
  bool unbind(ConnectionState state, ConnectionEventListener eventListener) {
    return _eventListeners[state].remove(eventListener);
  }

  void _tryConnecting() {
    _underlyingConnection =
        _factory.newWebSocketClientWrapper(_webSocketUri, this);
    _updateState(ConnectionState.CONNECTING);
  }

  void _tryReconnecting() {
    _updateState(ConnectionState.RECONNECTING);
    r.retry(() => _tryConnecting());
  }

  void _updateState(final ConnectionState newState) {
    _logger
        .fine('State transition requested, current [$state], new [$newState]');

    final change = ConnectionStateChange(state, newState);
    _state = newState;

    final interestedListeners = <ConnectionEventListener>{};
    interestedListeners.addAll(_eventListeners[ConnectionState.ALL]);
    interestedListeners.addAll(_eventListeners[newState]);

    for (final listener in interestedListeners) {
      _factory.queueOnEventThread(() {
        listener.onConnectionStateChange(change);
      });
    }
  }

  // Received error codes 4000-4099 indicate we shouldn't attempt reconnection
  // https://pusher.com/docs/pusher_protocol#error-codes
  bool shouldReconnect(int code) {
    return code < 4000 || code >= 4100;
  }

  void sendErrorToAllListeners(
      final String message, final String code, final Exception e) {
    final allListeners = <ConnectionEventListener>{};
    for (final listenersForState in _eventListeners.values) {
      allListeners.addAll(listenersForState);
    }

    for (final listener in allListeners) {
      _factory.queueOnEventThread(() {
        listener.onError(message, code, e);
      });
    }
  }

  void handleEvent(final String event, final String wholeMessage) {
    if (event.startsWith(INTERNAL_EVENT_PREFIX)) {
      handleInternalEvent(event, wholeMessage);
    } else {
      // _factory._getChannelManager().onMessage(event, wholeMessage);
    }
  }

  void handleInternalEvent(final String event, final String wholeMessage) {
    if (event == 'pusher:connection_established') {
      handleConnectionMessage(wholeMessage);
    } else if (event == 'pusher:error') {
      handleError(wholeMessage);
    }
  }

  void handleConnectionMessage(final String message) {
    final Map jsonObject = jsonDecode(message);
    final String dataString = jsonObject['data'];
    final Map dataMap = jsonDecode(dataString);
    _socketId = dataMap['socket_id'];

    if (state != ConnectionState.CONNECTED) {
      _updateState(ConnectionState.CONNECTED);
    }
    reconnectAttempts = 0;
  }

  void handleError(final String wholeMessage) {
    final Map json = jsonDecode(wholeMessage);
    final Object data = json['data'];

    Map dataMap;
    if (data is String) {
      dataMap = jsonDecode(data) as Map;
    } else {
      dataMap = data as Map;
    }

    final String message = dataMap['message'];

    final Object codeObject = dataMap['code'];
    String code;
    if (codeObject != null) {
      code = (codeObject as double).round().toString();
    }

    sendErrorToAllListeners(message, code, null);
  }

  void cancelTimeoutsAndTransitonToDisconnected() {
    //activityTimer.cancelTimeouts();

    _factory.queueOnEventThread(() {
      _updateState(ConnectionState.DISCONNECTED);
      //_factory.shutdownThreads();
    });
    reconnectAttempts = 0;
  }
}
