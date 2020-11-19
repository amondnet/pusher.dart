import 'package:pusher_websocket/src/channel/private_channel_event_listener.dart';

import 'channel/channel.dart';
import 'channel/channel_event_listner.dart';
import 'channel/presence_channel.dart';
import 'channel/presence_channel_event_listener.dart';
import 'channel/private_channel.dart';
import 'connection/connection.dart';
import 'connection/connection_event_listener.dart';
import 'connection/connection_state.dart';

abstract class Client {
  Connection getConnection();
  void connect(
      {final ConnectionEventListener eventListener,
      Iterable<ConnectionState> connectionStates});
  void disconnect();
  Channel subscribe(final String channelName,
      {final ChannelEventListener listener, final Iterable<String> eventNames});
  PrivateChannel subscribePrivate(final String channelName,
      {final PrivateChannelEventListener listener,
      final Iterable<String> eventNames});

  PresenceChannel subscribePresence(final String channelName,
      {final PresenceChannelEventListener listener,
      final Iterable<String> eventNames});

  void unsubscribe(final String channelName);
  Channel getChannel(String channelName);
  PrivateChannel getPrivateChannel(String channelName);
  PresenceChannel getPresenceChannel(String channelName);
}
