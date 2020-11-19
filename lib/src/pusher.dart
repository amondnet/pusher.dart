import 'package:pusher_websocket/src/channel/channel.dart';
import 'package:pusher_websocket/src/channel/channel_event_listner.dart';
import 'package:pusher_websocket/src/channel/presence_channel.dart';
import 'package:pusher_websocket/src/channel/presence_channel_event_listener.dart';
import 'package:pusher_websocket/src/channel/private_channel.dart';
import 'package:pusher_websocket/src/channel/private_channel_event_listener.dart';
import 'package:pusher_websocket/src/client.dart';
import 'package:pusher_websocket/src/connection/connection.dart';
import 'package:pusher_websocket/src/connection/connection_event_listener.dart';
import 'package:pusher_websocket/src/connection/connection_state.dart';
import 'package:pusher_websocket/src/pusher_options.dart';
import 'package:pusher_websocket/src/util/factory.dart';
import 'package:meta/meta.dart';
import 'package:quiver/check.dart';
import 'package:quiver/strings.dart';

import 'channel/impl/channel_manger.dart';
import 'connection/impl/internal_connection.dart';

/// This class is the main entry point for accessing Pusher.
///
///
/// By creating a new [Pusher] instance and calling
/// [Pusher.connect] a connection to Pusher is established.
///
///
/// Subscriptions for data are represented by
/// [Channel] objects, or subclasses thereof.
/// Subscriptions are created by calling [Pusher.subscribe(String)],
/// [Pusher.subscribePrivate],
/// [Pusher.subscribePresence] or one of the overloads.
class Pusher implements Client {
  /// Creates a new instance of Pusher.
  ///
  /// Note that if you use this constructor you will not be able to subscribe
  /// to private or presence channels because no [Authorizer] has been
  /// set. If you want to use private or presence channels:
  ///
  ///
  /// * Create an implementation of the [Authorizer] interface, or use
  /// the [HttpAuthorizer] provided.
  /// * Create an instance of [PusherOptions] and set the authorizer on
  /// it by calling [PusherOptions.setAuthorizer].
  /// * Use the [Pusher(String, PusherOptions)] constructor to create
  /// an instance of Pusher.
  ///
  ///
  /// The [PrivateChannelExampleApp] and [PresenceChannelExampleApp] example
  /// applications show how to do this.
  ///
  /// [apiKey]
  ///            Your Pusher API key.
  Pusher(this.apiKey, {PusherOptions pusherOptions, Factory factory})
      : pusherOptions = pusherOptions ?? PusherOptions(),
        factory = Factory(),
        connection = factory.getConnection(apiKey, pusherOptions),
        channelManager = factory.getChannelManger() {
    checkArgument(isNotBlank(apiKey),
        message: 'API Key cannot be null or empty');
    checkNotNull(pusherOptions, message: 'PusherOptions cannot be null');
    channelManager.connection = connection;
  }

  final String apiKey;
  final PusherOptions pusherOptions;
  final Factory factory;
  final InternalConnection connection;
  final ChannelManager channelManager;

  @override
  void connect(
      {ConnectionEventListener eventListener,
      Iterable<ConnectionState> connectionStates}) {
    // TODO: implement connect
  }

  @override
  void disconnect() {
    // TODO: implement disconnect
  }

  @override
  Channel getChannel(String channelName) {
    // TODO: implement getChannel
    throw UnimplementedError();
  }

  @override
  Connection getConnection() {
    // TODO: implement getConnection
    throw UnimplementedError();
  }

  @override
  PresenceChannel getPresenceChannel(String channelName) {
    // TODO: implement getPresenceChannel
    throw UnimplementedError();
  }

  @override
  PrivateChannel getPrivateChannel(String channelName) {
    // TODO: implement getPrivateChannel
    throw UnimplementedError();
  }

  @override
  Channel subscribe(String channelName,
      {ChannelEventListener listener, Iterable<String> eventNames}) {
    // TODO: implement subscribe
    throw UnimplementedError();
  }

  @override
  PresenceChannel subscribePresence(String channelName,
      {PresenceChannelEventListener listener, Iterable<String> eventNames}) {
    // TODO: implement subscribePresence
    throw UnimplementedError();
  }

  @override
  PrivateChannel subscribePrivate(String channelName,
      {PrivateChannelEventListener listener, Iterable<String> eventNames}) {
    // TODO: implement subscribePrivate
    throw UnimplementedError();
  }

  @override
  void unsubscribe(String channelName) {
    // TODO: implement unsubscribe
  }
}
