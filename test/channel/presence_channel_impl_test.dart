import 'dart:convert';

import 'package:pusher_websocket/src/channel/impl/presence_channel_impl.dart';
import 'package:pusher_websocket/src/channel/impl/private_channel_impl.dart';
import 'package:pusher_websocket/src/channel/presence_channel_event_listener.dart';
import 'package:pusher_websocket/src/channel/user.dart';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'private_channel_impl_test.dart';

class PresenceChannelImplTest extends PrivateChannelImplTest {
  static final String AUTH_RESPONSE =
      '\"auth\":\"a87fe72c6f36272aa4b1:f9db294eae7\",\"channel_data\":\"{\\\"user_id\\\":\\\"5116a4519575b\\\",\\\"user_info\\\":{\\\"name\\\":\\\"Phil Leggetter\\\",\\\"twitter_id\\\":\\\"@leggetter\\\"}}\"';
  static final String AUTH_RESPONSE_NUMERIC_ID =
      '\"auth\":\"a87fe72c6f36272aa4b1:f9db294eae7\",\"channel_data\":\"{\\\"user_id\\\":51169,\\\"user_info\\\":{\\\"name\\\":\\\"Phil Leggetter\\\",\\\"twitter_id\\\":\\\"@leggetter\\\"}}\"';
  static final String USER_ID = '5116a4519575b';

  PresenceChannelEventListener mockEventListener;

  @override
  void testSetUp() {
    super.testSetUp();
    setUp(() {
      channel.eventListener = mockEventListener;
      when(mockAuthorizer.authorize(channelName, any))
          .thenAnswer((_) => Future.value('{' + AUTH_RESPONSE + '}'));
    });
  }

  @override
  void testMain() {
    super.testMain();

    test('testReturnsCorrectSubscribeMessageWhenNumericId', () async {
      when(mockAuthorizer.authorize(channelName, any)).thenAnswer(
          (_) => Future.value('{' + AUTH_RESPONSE_NUMERIC_ID + '}'));

      final message = await channel.toSubscribeMessage();
      expect(
          '{\"event\":\"pusher:subscribe\",\"data\":{\"channel\":\"' +
              channelName +
              '\",' +
              AUTH_RESPONSE_NUMERIC_ID +
              '}}',
          message);
    });

    test('testStoresCorrectUser', () async {
      await channel.toSubscribeMessage();
      await channel.onMessage('pusher_internal:subscription_succeeded',
          '{\"event\":\"pusher_internal:subscription_succeeded\",\"data\":\"{\\\"presence\\\":{\\\"count\\\":1,\\\"ids\\\":[\\\"5116a4519575b\\\"],\\\"hash\\\":{\\\"5116a4519575b\\\":{\\\"name\\\":\\\"Phil Leggetter\\\",\\\"twitter_id\\\":\\\"@leggetter\\\"}}}}\",\"channel\":\"presence-myChannel\"}');
      expect(USER_ID, (channel as PresenceChannelImpl).getMe().id);
    });

    test(
        'testThatUserIdsPassedAsIntegersGetStoredAsStringifiedIntegersAndNotDoubles',
        () async {
      final userInfo = <String, String>{};
      userInfo['name'] = 'Phil Leggetter';
      userInfo['twitter_id'] = '@leggetter';

      final Map<String, Object> data = <String, String>{};
      data['user_id'] = 123;
      data['user_info'] = userInfo;

      final eventName = 'pusher_internal:member_added';

      await channel.onMessage(
          eventName, eventJson(eventName, data, channelName));

      final argument = verify(mockEventListener.userSubscribed(
              channelName, captureThat(isA<User>())))
          .captured;

      final User user = argument.first;
      expect(user.id, '123');
    });

    test('testInternalMemberAddedMessageIsTranslatedToUserSubscribedCallback',
        () async {
      await _addUser(USER_ID);

      final argument = verify(mockEventListener.userSubscribed(
              channelName, captureThat(isA<User>())))
          .captured;

      expect(argument.first, isA<User>());

      final User user = argument.first;
      expect(user.id, USER_ID);
      expect(user.info,
          "{\"name\":\"Phil Leggetter\",\"twitter_id\":\"@leggetter\"}");
    });
  }

  Future<void> _addUser(final String userId) async {
    final userInfo = <String, String>{};
    userInfo['name'] = 'Phil Leggetter';
    userInfo['twitter_id'] = '@leggetter';

    final Map<String, Object> data = <String, String>{};
    data['user_id'] = userId;
    data['user_info'] = userInfo;

    final eventName = 'pusher_internal:member_added';

    await channel.onMessage(eventName, eventJson(eventName, data, channelName));
  }

  @override
  void testReturnsCorrectSubscribeMessage() async {
    final message = await channel.toSubscribeMessage();
    expect(
        '{\"event\":\"pusher:subscribe\",\"data\":{\"channel\":\"' +
            channelName +
            '\",' +
            AUTH_RESPONSE +
            '}}',
        message);
  }

  @override
  void testIsSubscribedMethod() async {
    expect(channel.isSubscribed, isFalse);
    await channel.onMessage('pusher_internal:subscription_succeeded',
        '{\"event\":\"pusher_internal:subscription_succeeded\",\"data\":\"{\\\"presence\\\":{\\\"count\\\":1,\\\"ids\\\":[\\\"5116a4519575b\\\"],\\\"hash\\\":{\\\"5116a4519575b\\\":{\\\"name\\\":\\\"Phil Leggetter\\\",\\\"twitter_id\\\":\\\"@leggetter\\\"}}}}\",\"channel\":\"presence-myChannel\"}');
    expect(channel.isSubscribed, isTrue);
  }

  @override
  void
      testInternalSubscriptionSucceededMessageIsTranslatedToASubscriptionSuccessfulCallback() {
    final eventName = 'pusher_internal:subscription_succeeded';

    final userInfo = <String, Object>{};
    userInfo['name'] = 'Phil Leggetter';
    userInfo['twitter_id'] = '@leggetter';

    final hash = <String, Object>{};
    hash[USER_ID] = userInfo;

    final presence = <String, Object>{};
    presence['count'] = 1;
    presence['ids'] = [USER_ID];
    presence['hash'] = hash;

    final data = <String, Object>{};
    data['presence'] = presence;

    channel.onMessage(eventName, eventJson(eventName, data, channelName));

    verify(mockEventListener.onSubscriptionSucceeded(channelName));
    var argument = verify(mockEventListener.onUsersInformationReceived(
            channelName, captureThat(isA<Set>())))
        .captured;

    expect(argument.length, 1);
    expect(argument.first, isA<User>());

    final User user = argument.first;
    expect(user.id, USER_ID);
    expect(user.info,
        '{\"name\":\"Phil Leggetter\",\"twitter_id\":\"@leggetter\"}');
  }

  static String eventJson(
      final String eventName, final Map data, final String channelName) {
    return _eventJson(eventName, jsonEncode(data), channelName);
  }

  static String _eventJson(final String eventName, final String dataString,
      final String channelName) {
    final map = <String, String>{};
    map['event'] = eventName;
    map['data'] = dataString;
    map['channel'] = channelName;
    return jsonEncode(map);
  }
}

void main() {
  final t = PresenceChannelImplTest();
  t.testSetUp();
  t.testMain();
}
