import 'dart:convert';

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:meta/meta.dart';
import 'package:pusher_websocket/src/authorizer.dart';
import 'package:pusher_websocket/src/channel/impl/private_channel_impl.dart';
import 'package:pusher_websocket/src/channel/presence_channel.dart';
import 'package:pusher_websocket/src/channel/user.dart';
import 'package:pusher_websocket/src/connection/impl/internal_connection.dart';
import 'package:pusher_websocket/src/util/factory.dart';
import 'package:synchronized/synchronized.dart';

import '../../serializers.dart';
import '../channel_event_listner.dart';
import '../presence_channel_event_listener.dart';
import '../subscription_event_listener.dart';
import 'channel_impl.dart';

part 'presence_channel_impl.g.dart';

class PresenceChannelImpl extends PrivateChannelImpl
    implements PresenceChannel {
  static final String MEMBER_ADDED_EVENT = 'pusher_internal:member_added';
  static final String MEMBER_REMOVED_EVENT = 'pusher_internal:member_removed';

  // TODO(amond): synchronized
  final Map<String, User> _idToUserMap = <String, User>{};

  String _myUserID;

  PresenceChannelImpl(
      final InternalConnection connection,
      final String channelName,
      final Authorizer authorizer,
      final Factory factory)
      : super(connection, channelName, authorizer, factory);

  /* PresenceChannel implementation */

  @override
  User getMe() {
    return _idToUserMap[_myUserID];
  }

  @override
  Set<User> getUsers() {
    return _idToUserMap.values.toSet();
  }

/* Base class overrides */
  @override
  Future<void> onMessage(final String event, final String message) async {
    await super.onMessage(event, message);

    if (event == ChannelImpl.SUBSCRIPTION_SUCCESS_EVENT) {
      _handleSubscriptionSuccessfulMessage(message);
    } else if (event == MEMBER_ADDED_EVENT) {
      _handleMemberAddedEvent(message);
    } else if (event == MEMBER_REMOVED_EVENT) {
      _handleMemberRemovedEvent(message);
    }
  }

  @override
  Future<String> toSubscribeMessage() async {
    var msg = await super.toSubscribeMessage();
    _myUserID = _extractUserIdFromChannelData(channelData);
    return msg;
  }

  @override
  Future<void> bind(
      final String eventName, final SubscriptionEventListener listener) {
    if (listener is! PresenceChannelEventListener) {
      throw ArgumentError(
          'Only instances of PresenceChannelEventListener can be bound to a presence channel');
    }

    return super.bind(eventName, listener);
  }

  @override
  @protected
  final List<String> disallowedNameExpressions = ['^(?!presence-).*'];

  @override
  String toString() {
    return '[Presence Channel: name=$name]';
  }

  void _handleSubscriptionSuccessfulMessage(final String message) {
    // extract data from the JSON message
    final presenceData = _extractPresenceDataFrom(message);
    final ids = presenceData.ids;
    final hash = presenceData.hash;

    if (ids != null && ids.isNotEmpty) {
      // build the collection of Users
      for (final id in ids) {
        final userData =
            hash.containsKey(id) != null ? jsonEncode(hash[id]) : null;
        final user = User(id, userData);
        _idToUserMap[id] = user;
      }
    }
    final listener = eventListener;
    if (listener != null) {
      final PresenceChannelEventListener presenceListener = listener;
      presenceListener.onUsersInformationReceived(name, getUsers());
    }
  }

  void _handleMemberAddedEvent(final String message) {
    final dataString = _extractDataStringFrom(message);
    final memberData = MemberData.fromJson(jsonDecode(dataString));

    final id = memberData.userId;
    final userData =
        memberData.userInfo != null ? jsonEncode(memberData.userInfo) : null;

    final user = User(id, userData);
    _idToUserMap[id] = user;

    final listener = eventListener;
    if (listener != null) {
      final PresenceChannelEventListener presenceListener = listener;
      presenceListener.userSubscribed(name, user);
    }
  }

  void _handleMemberRemovedEvent(final String message) {
    final dataString = _extractDataStringFrom(message);
    final memberData = MemberData.fromJson(jsonDecode(dataString));

    final user = _idToUserMap.remove(memberData.userId);

    final listener = eventListener;
    if (listener != null) {
      final PresenceChannelEventListener presenceListener = listener;
      presenceListener.userUnsubscribed(name, user);
    }
  }

  static String _extractDataStringFrom(final String message) {
    final Map jsonObject = jsonDecode(message);
    return jsonObject['data'];
  }

  static PresenceData _extractPresenceDataFrom(final String message) {
    final dataString = _extractDataStringFrom(message);
    return PresenceData.fromJson(jsonDecode(dataString));
  }

  String _extractUserIdFromChannelData(final String channelData) {
    Map channelDataMap;
    try {
      channelDataMap = jsonDecode(channelData);
    } catch (e) {
      throw AuthorizationFailureException(
          message:
              'Invalid response from Authorizer: unable to parse channel_data object: ' +
                  channelData,
          cause: e);
    }
    Object maybeUserId;
    try {
      maybeUserId = channelDataMap['user_id'];
    } catch (e) {
      throw AuthorizationFailureException(
          message:
              'Invalid response from Authorizer: no user_id key in channel_data object: ' +
                  channelData);
    }
    if (maybeUserId == null) {
      throw AuthorizationFailureException(
          message:
              'Invalid response from Authorizer: no user_id key in channel_data object: ' +
                  channelData);
    }
    // user_id can be a string or an integer in the Channels websocket protocol
    return maybeUserId?.toString();
  }
}

abstract class PresenceData
    implements Built<PresenceData, PresenceDataBuilder> {
  PresenceData._();

  factory PresenceData([void Function(PresenceDataBuilder) updates]) =
      _$PresenceData;

  Map<String, dynamic> toJson() {
    return serializers.serializeWith(PresenceData.serializer, this);
  }

  static PresenceData fromJson(Map<String, dynamic> json) {
    return serializers.deserializeWith(PresenceData.serializer, json);
  }

  static Serializer<PresenceData> get serializer => _$presenceDataSerializer;

  @BuiltValueField(wireName: 'count')
  int get count;

  @BuiltValueField(wireName: 'ids')
  List<String> get ids;

  @BuiltValueField(wireName: 'hash')
  Map<String, Object> get hash;
}

abstract class MemberData implements Built<MemberData, MemberDataBuilder> {
  MemberData._();

  factory MemberData([void Function(MemberDataBuilder) updates]) = _$MemberData;

  Map<String, dynamic> toJson() {
    return serializers.serializeWith(MemberData.serializer, this);
  }

  static MemberData fromJson(Map<String, dynamic> json) {
    return serializers.deserializeWith(MemberData.serializer, json);
  }

  static Serializer<MemberData> get serializer => _$memberDataSerializer;

  @BuiltValueField(wireName: 'user_id')
  String get userId;

  @BuiltValueField(wireName: 'user_info')
  Object get userInfo;
}

abstract class Presence implements Built<Presence, PresenceBuilder> {
  Presence._();

  factory Presence([void Function(PresenceBuilder) updates]) = _$Presence;

  Map<String, dynamic> toJson() {
    return serializers.serializeWith(Presence.serializer, this);
  }

  static Presence fromJson(Map<String, dynamic> json) {
    return serializers.deserializeWith(Presence.serializer, json);
  }

  static Serializer<Presence> get serializer => _$presenceSerializer;

  @BuiltValueField(wireName: 'presence')
  PresenceData get presence;
}
