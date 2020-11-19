import 'authorizer.dart';

/// Configuration for a [Pusher] instance.
class PusherOptions {
  static final String SRC_LIB_DEV_VERSION = '@version@';
  static final String LIB_DEV_VERSION = '0.0.0-dev';
  static final String LIB_VERSION = '0.0.1';

  static final String URI_SUFFIX =
      '?client=java-client&protocol=5&version=$LIB_VERSION';
  static final String WS_SCHEME = 'ws';
  static final String WSS_SCHEME = 'wss';

  static final int WS_PORT = 80;
  static final int WSS_PORT = 443;
  static final String PUSHER_DOMAIN = 'pusher.com';

  static final int DEFAULT_ACTIVITY_TIMEOUT = 120000;
  static final int DEFAULT_PONG_TIMEOUT = 30000;

  static final int MAX_RECONNECTION_ATTEMPTS = 6; //Taken from the Swift lib
  static final int MAX_RECONNECT_GAP_IN_SECONDS = 30;

  // Note that the primary cluster lives on a different domain
  // (others are subdomains of pusher.com). This is not an oversight.
  // Legacy reasons.
  String host = "ws.pusherapp.com";
  int wsPort = WS_PORT;
  int wssPort = WSS_PORT;
  bool useTLS = true;
  int activityTimeout = DEFAULT_ACTIVITY_TIMEOUT;
  int pongTimeout = DEFAULT_PONG_TIMEOUT;
  Authorizer authorizer;

  //Proxy proxy = Proxy.NO_PROXY;
  int maxReconnectionAttempts = MAX_RECONNECTION_ATTEMPTS;
  int maxReconnectGapInSeconds = MAX_RECONNECT_GAP_IN_SECONDS;

  /// Construct the URL for the WebSocket connection based on the options
  /// previous set on this object and the provided API key
  ///
  /// [apiKey] The API key
  String buildUrl(final String apiKey) {
    final scheme = useTLS ? WSS_SCHEME : WS_SCHEME;
    final port = useTLS ? wssPort : wsPort;

    return '$scheme://$host:$port/app/$apiKey$URI_SUFFIX';
  }

  PusherOptions();
}
