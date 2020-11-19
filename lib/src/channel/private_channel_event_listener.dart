import 'package:pusher_websocket/src/channel/pusher_event.dart';

import 'channel_event_listner.dart';

/// Interface to listen to private channel events.
abstract class PrivateChannelEventListener extends ChannelEventListener {
  /// Called when an attempt to authenticate a private channel fails.
  ///
  /// [message] A description of the problem.
  /// [e] An associated exception, if available.
  void onAuthenticationFailure(String message, Exception e);
}
