import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:pusher_websocket/src/authorizer.dart';
import 'package:pusher_websocket/src/channel/channel_state.dart';
import 'package:pusher_websocket/src/channel/impl/channel_impl.dart';
import 'package:pusher_websocket/src/channel/private_channel.dart';
import 'package:pusher_websocket/src/connection/connection_state.dart';
import 'package:pusher_websocket/src/connection/impl/internal_connection.dart';
import 'package:pusher_websocket/src/util/factory.dart';
import 'package:quiver/check.dart';

import '../private_channel_event_listener.dart';
import '../subscription_event_listener.dart';

class PrivateChannelImpl extends ChannelImpl implements PrivateChannel {
  static final String _CLIENT_EVENT_PREFIX = 'client-';

  final InternalConnection _connection;
  final Authorizer _authorizer;

  @protected
  String channelData;

  PrivateChannelImpl(this._connection, final String channelName,
      this._authorizer, final Factory factory)
      : super(channelName, factory);

  @override
  void trigger(final String eventName, final String data) {
    if (eventName == null || !eventName.startsWith(_CLIENT_EVENT_PREFIX)) {
      throw ArgumentError(
          'Cannot trigger event  $eventName: client events must start with \"client-\"');
    }
    checkState(state == ChannelState.SUBSCRIBED,
        message:
            'Cannot trigger event $eventName  because channel name is in $state state');

    checkState(_connection.state == ConnectionState.CONNECTED,
        message:
            'Cannot trigger event  $eventName  because connection is in ${_connection.state.toString()} state');

    try {
      final jsonPayload = <Object, Object>{};
      jsonPayload['event'] = eventName;
      jsonPayload['channel'] = name;
      jsonPayload['data'] = data;

      final jsonMessage = jsonEncode(jsonPayload);
      _connection.sendMessage(jsonMessage);
    } catch (e) {
      throw ArgumentError(
          'Cannot trigger event $eventName because "$data" could not be parsed as valid JSON');
    }
  }

  @override
  Future<void> bind(
      final String eventName, final SubscriptionEventListener listener) {
    if (listener is! PrivateChannelEventListener) {
      throw ArgumentError(
          'Only instances of PrivateChannelEventListener can be bound to a private channel');
    }

    return super.bind(eventName, listener);
  }

  @override
  Future<String> toSubscribeMessage() async {
    final authResponse = await getAuthResponse();

    try {
      final Map authResponseMap = jsonDecode(authResponse);
      final String authKey = authResponseMap['auth'];
      channelData = authResponseMap['channel_data'];

      final jsonObject = <Object, Object>{};
      jsonObject['event'] = 'pusher:subscribe';

      final dataMap = <Object, Object>{};
      dataMap['channel'] = name;
      dataMap['auth'] = authKey;
      if (channelData != null) {
        dataMap['channel_data'] = channelData;
      }

      jsonObject['data'] = dataMap;

      final json = jsonEncode(jsonObject);
      return json;
    } catch (e) {
      throw AuthorizationFailureException(
          message: 'Unable to parse response from Authorizer: ' + authResponse,
          cause: e);
    }
  }

  @override
  @protected
  List<String> get disallowedNameExpressions {
    return [
      r'^(?!private-).*', // double negative, don't not start with private-
      r'^private-encrypted-.*' // doesn't start with private-encrypted-
    ];
  }

  /// Protected access because this is also used by PresenceChannelImpl.
  @protected
  Future<String> getAuthResponse() {
    final socketId = _connection.socketId;
    return _authorizer.authorize(name, socketId);
  }

  @override
  String toString() {
    return 'Private Channel: name=$name';
  }
}
