import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:quiver/check.dart';
import 'package:synchronized/synchronized.dart';

import '../../util/factory.dart';
import '../channel_event_listner.dart';
import '../channel_state.dart';
import '../pusher_event.dart';
import '../subscription_event_listener.dart';
import 'internal_channle.dart';

final _logger = Logger('ChannelImpl');

class ChannelImpl implements InternalChannel {
  static final String INTERNAL_EVENT_PREFIX = 'pusher_internal:';
  final Map<String, Set<SubscriptionEventListener>> _eventNameToListenerMap =
      <String, Set<SubscriptionEventListener>>{};
  ChannelState state = ChannelState.INITIAL;
  var lock = Lock();
  final Factory _factory;
  @protected
  static final String SUBSCRIPTION_SUCCESS_EVENT =
      'pusher_internal:subscription_succeeded';

  @override
  final String name;

  @override
  ChannelEventListener eventListener;

  ChannelImpl(String channelName, this._factory) : name = channelName {
    checkArgument(channelName != null,
        message: 'Cannot subscribe to a channel with a null name');

    for (final disallowedPattern in disallowedNameExpressions) {
      var match = RegExp(disallowedPattern).hasMatch(channelName);
      checkArgument(!match,
          message:
              'Channel name $channelName is invalid. Private channel names must start with \"private-\" and presence channel names must start with \"presence-\"');
    }
  }

  /* Channel implementation */

  @override
  Future<void> bind(String eventName, SubscriptionEventListener listener) {
    _validateArguments(eventName, listener);
    return lock.synchronized(() {
      var listeners = _eventNameToListenerMap[eventName];
      if (listeners == null) {
        _logger.info('listeners is null');
        listeners = <SubscriptionEventListener>{};
        _eventNameToListenerMap[eventName] = listeners;
      }
      listeners.add(listener);
    });
  }

  @override
  Future<void> unbind(String eventName, SubscriptionEventListener listener) {
    _validateArguments(eventName, listener);
    return lock.synchronized(() {
      var listeners = _eventNameToListenerMap[eventName];
      if (listeners != null) {
        listeners.remove(listener);
        if (listeners.isEmpty) {
          _eventNameToListenerMap.remove(eventName);
        }
      }
    });
  }

  @override
  bool get isSubscribed => state == ChannelState.SUBSCRIBED;

  /* InternalChannel implementation */

  @override
  PusherEvent prepareEvent(String event, String message) {
    return PusherEvent(jsonDecode(message));
  }

  @override
  Future<void> onMessage(final String event, final String message) async {
    _logger.fine('[onMessage] event : $event');
    _logger.fine('[onMessage] message : $message');

    if (event == SUBSCRIPTION_SUCCESS_EVENT) {
      _logger.fine(SUBSCRIPTION_SUCCESS_EVENT);
      updateState(ChannelState.SUBSCRIBED);
    } else {
      _logger.fine('getInterestedListeners for $event');
      final listeners = await getInterestedListeners(event);
      if (listeners != null) {
        _logger.fine('listeners is exists');
        final pusherEvent = prepareEvent(event, message);
        _logger.finest('pusherEvent : ${pusherEvent}');
        if (pusherEvent != null) {
          for (final listener in listeners) {
            _logger.finest('queueOnEventThread : ${listener}');
            await _factory.queueOnEventThread(() {
              listener.onEvent(pusherEvent);
              _logger.finest('listener.onEvent');
            });
          }
        }
      }
    }
  }

  @override
  int compareTo(InternalChannel other) {
    return name.compareTo(other.name);
  }

  @override
  String toSubscribeMessage() {
    final jsonObject = <Object, Object>{};
    jsonObject['event'] = 'pusher:subscribe';

    final dataMap = <Object, Object>{};
    dataMap['channel'] = name;

    jsonObject['data'] = dataMap;

    return jsonEncode(jsonObject);
  }

  @override
  String toUnsubscribeMessage() {
    final jsonObject = <Object, Object>{};
    jsonObject['event'] = 'pusher:unsubscribe';

    final dataMap = <Object, Object>{};
    dataMap['channel'] = name;

    jsonObject['data'] = dataMap;

    return jsonEncode(jsonObject);
  }

  @override
  void updateState(state) {
    this.state = state;

    if (state == ChannelState.SUBSCRIBED && eventListener != null) {
      _factory.queueOnEventThread(() {
        eventListener.onSubscriptionSucceeded(name);
      });
    }
  }

  @protected
  List<String> get disallowedNameExpressions {
    return [r'^private-.*', r'^presence-.*'];
  }

  void _validateArguments(
      final String eventName, final SubscriptionEventListener listener) {
    if (eventName == null) {
      throw ArgumentError(
          'Cannot bind or unbind to channel $name with a null event name');
    }

    if (listener == null) {
      throw ArgumentError(
          'Cannot bind or unbind to channel $name with a null listener');
    }

    if (eventName.startsWith(INTERNAL_EVENT_PREFIX)) {
      throw ArgumentError(
          'Cannot bind or unbind channel $name with an internal event name such as $eventName');
    }

    if (state == ChannelState.UNSUBSCRIBED) {
      throw StateError(
          'Cannot bind or unbind to events on a channel that has been unsubscribed. Call Pusher.subscribe() to resubscribe to this channel');
    }
  }

  @protected
  Future<Set<SubscriptionEventListener>> getInterestedListeners(String event) {
    return lock.synchronized(() {
      final sharedListeners = _eventNameToListenerMap[event];

      if (sharedListeners == null) {
        print('sharedListeners is null');
        return null;
      }

      return sharedListeners;
    });
  }

  @override
  String toString() {
    return '[Public Channel: name=$name]';
  }
}
