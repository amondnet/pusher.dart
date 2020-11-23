import 'dart:convert';

import 'package:pusher_websocket/src/authorizer.dart';
import 'package:pusher_websocket/src/connection/connection_event_listener.dart';
import 'package:pusher_websocket/src/connection/connection_state.dart';
import 'package:pusher_websocket/src/connection/connection_state_change.dart';
import 'package:pusher_websocket/src/connection/impl/internal_connection.dart';
import 'package:pusher_websocket/src/util/factory.dart';
import 'package:quiver/check.dart';
import 'package:synchronized/synchronized.dart';

import '../channel.dart';
import '../channel_event_listner.dart';
import '../channel_state.dart';
import '../presence_channel.dart';
import '../private_channel.dart';
import '../private_channel_event_listener.dart';
import '../private_encrypted_channel.dart';
import 'internal_channel.dart';

class ChannelManager implements ConnectionEventListener {
  final Factory factory;
  final _lock = Lock();
  // TODO(amond): concurrent
  final Map<String, InternalChannel> channelNameToChannelMap =
      <String, InternalChannel>{};

  InternalConnection _connection;

  ChannelManager(this.factory);

  Channel getChannel(String channelName) {
    if (channelName.startsWith('private-')) {
      throw ArgumentError('Please use the getPrivateChannel method');
    } else if (channelName.startsWith('presence-')) {
      throw ArgumentError('Please use the getPresenceChannel method');
    }
    return _findChannelInChannelMap(channelName);
  }

  PrivateChannel getPrivateChannel(String channelName) {
    if (!channelName.startsWith('private-')) {
      throw ArgumentError("Private channels must begin with 'private-'");
    } else {
      return _findChannelInChannelMap(channelName) as PrivateChannel;
    }
  }

  PrivateEncryptedChannel getPrivateEncryptedChannel(String channelName) {
    if (!channelName.startsWith('private-encrypted-')) {
      throw ArgumentError(
          "Encrypted private channels must begin with 'private-encrypted-'");
    } else {
      return _findChannelInChannelMap(channelName) as PrivateEncryptedChannel;
    }
  }

  PresenceChannel getPresenceChannel(String channelName) {
    if (!channelName.startsWith('presence-')) {
      throw ArgumentError("Presence channels must begin with 'presence-'");
    } else {
      return _findChannelInChannelMap(channelName) as PresenceChannel;
    }
  }

  InternalChannel _findChannelInChannelMap(String channelName) {
    return channelNameToChannelMap[channelName];
  }

  set connection(final InternalConnection connection) {
    if (connection == null) {
      throw ArgumentError(
          'Cannot construct ChannelManager with a null connection');
    }

    if (_connection != null) {
      _connection.unbind(ConnectionState.CONNECTED, this);
    }

    _connection = connection;
    connection.bind(ConnectionState.CONNECTED, this);
  }

  Future<void> subscribeTo(
      final InternalChannel channel, final ChannelEventListener listener,
      [final Iterable<String> eventNames = const []]) async {
    await _validateArgumentsAndBindEvents(channel, listener, eventNames);
    await _lock
        .synchronized(() => channelNameToChannelMap[channel.name] = channel);
    await _sendOrQueueSubscribeMessage(channel);
  }

  void unsubscribeFrom(final String channelName) async {
    if (channelName == null) {
      throw ArgumentError('Cannot unsubscribe from null channel');
    }
    await _lock.synchronized(() {
      final channel = channelNameToChannelMap.remove(channelName);
      if (channel == null) {
        return;
      }
      if (_connection.state == ConnectionState.CONNECTED) {
        _sendUnsubscribeMessage(channel);
      }
    });
  }

  void onMessage(final String event, final String wholeMessage) {
    final Map<Object, Object> json = jsonDecode(wholeMessage);
    final channelNameObject = json['channel'];

    if (channelNameObject != null) {
      _lock.synchronized(() {
        final channelName = channelNameObject as String;
        final channel = channelNameToChannelMap[channelName];

        if (channel != null) {
          channel.onMessage(event, wholeMessage);
        }
      });
    }
  }

  /* ConnectionEventListener implementation */

  @override
  void onConnectionStateChange(ConnectionStateChange change) {
    if (change.getCurrentState() == ConnectionState.CONNECTED) {
      _lock.synchronized(() {
        for (final channel in channelNameToChannelMap.values) {
          _sendOrQueueSubscribeMessage(channel);
        }
      });
    }
  }

  @override
  void onError(String message, String code, Exception e) {
    // ignore or log
  }

  /* implementation detail */

  void _sendOrQueueSubscribeMessage(final InternalChannel channel) {
    factory.queueOnEventThread(() async {
      if (_connection.state == ConnectionState.CONNECTED) {
        try {
          final message = await channel.toSubscribeMessage();
          _connection.sendMessage(message);
          channel.updateState(ChannelState.SUBSCRIBE_SENT);
        } catch (e) {
          if (e is AuthorizationFailureException) {
            _handleAuthenticationFailure(channel, e);
          }
        }
      }
    });
  }

  void _sendUnsubscribeMessage(final InternalChannel channel) {
    factory.queueOnEventThread(() {
      _connection.sendMessage(channel.toUnsubscribeMessage());
      channel.updateState(ChannelState.UNSUBSCRIBED);
    });
  }

  void _handleAuthenticationFailure(final InternalChannel channel,
      final AuthorizationFailureException e) async {
    await _lock
        .synchronized(() => channelNameToChannelMap.remove(channel.name));
    channel.updateState(ChannelState.FAILED);

    if (channel.eventListener != null) {
      await factory.queueOnEventThread(() {
        // Note: this cast is safe because an
        // AuthorizationFailureException will never be thrown
        // when subscribing to a non-private channel
        final eventListener = channel.eventListener;
        final privateChannelListener =
            eventListener as PrivateChannelEventListener;
        privateChannelListener.onAuthenticationFailure(e.message, e);
      });
    }
  }

  Future<void> _validateArgumentsAndBindEvents(
      final InternalChannel channel, final ChannelEventListener listener,
      [final Iterable<String> eventNames = const []]) async {
    checkArgument(channel != null,
        message: 'Cannot subscribe to a null channel');
    checkArgument(!channelNameToChannelMap.containsKey(channel.name),
        message: 'Already subscribed to a channel with name ${channel.name}');

    for (final eventName in eventNames) {
      await channel.bind(eventName, listener);
    }

    channel.eventListener = listener;
  }
}
