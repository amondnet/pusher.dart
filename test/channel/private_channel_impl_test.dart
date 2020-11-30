import 'package:meta/meta.dart';
import 'package:mockito/mockito.dart';
import 'package:pusher_websocket/src/authorizer.dart';
import 'package:pusher_websocket/src/channel/channel_event_listner.dart';
import 'package:pusher_websocket/src/channel/channel_state.dart';
import 'package:pusher_websocket/src/channel/impl/channel_impl.dart';
import 'package:pusher_websocket/src/channel/impl/private_channel_impl.dart';
import 'package:pusher_websocket/src/channel/private_channel_event_listener.dart';
import 'package:pusher_websocket/src/connection/connection_state.dart';
import 'package:pusher_websocket/src/connection/impl/internal_connection.dart';
import 'package:test/test.dart';

import '../mocks.dart';
import 'channel_impl_test.dart';

class PrivateChannelImplTest extends ChannelImplTest {
  InternalConnection mockConnection;

  Authorizer mockAuthorizer;

  static final AUTH_RESPONSE =
      '\"auth\":\"a87fe72c6f36272aa4b1:41dce43734b18bb\"';
  static final String AUTH_RESPONSE_WITH_CHANNEL_DATA =
      '\"auth\":\"a87fe72c6f36272aa4b1:41dce43734b18bb\",\"channel_data\":\"{\\\"user_id\\\":\\\"51169fc47abac\\\"}\"';

  PrivateChannelImplTest() {
    setUp(testSetUp);
  }

  @override
  void testSetUp() {
    super.testSetUp();
    mockAuthorizer = MockAuthorizer();
    when(mockAuthorizer.authorize(channelName, any))
        .thenAnswer((_) => Future.value('{$AUTH_RESPONSE}'));
    mockConnection = MockConnection();
  }

  @override
  void testMain() {
    super.testMain();

    test('Construct With Non Private Channel Name Throws Exception', () {
      final invalidNames = [
        'my-channel',
        'private:my-channel',
        'Private-my-channel'
      ];

      for (var invalidName in invalidNames) {
        try {
          newInstance(invalidName);
          fail('No exception thrown for invalid name: $invalidName');
        } catch (e) {
          // exception correctly thrown
        }
      }
    });

    test('testReturnsCorrectSubscribeMessageWithChannelData', () async {
      when(mockAuthorizer.authorize(channelName, any)).thenAnswer(
          (_) => Future.value('{' + AUTH_RESPONSE_WITH_CHANNEL_DATA + '}'));

      expect(
          await channel.toSubscribeMessage(),
          '{\"event\":\"pusher:subscribe\",\"data\":{\"channel\":\"' +
              channelName +
              '\",' +
              AUTH_RESPONSE_WITH_CHANNEL_DATA +
              '}}');
    });

    test('ThrowsAuthorizationFailureExceptionIfAuthorizerThrowsException',
        () async {
      when(mockAuthorizer.authorize(any, any)).thenThrow(
          AuthorizationFailureException(
              message: 'Unable to contact auth server'));

      try {
        await channel.toSubscribeMessage();
        fail('exception not thrown');
      } catch (e) {
        expect(e, isA<AuthorizationFailureException>());
      }
    });

    test(
        'testThrowsAuthorizationFailureExceptionIfAuthorizerReturnsBasicString',
        () async {
      when(mockAuthorizer.authorize(any, any))
          .thenAnswer((_) => Future.value("I'm a string"));

      try {
        await channel.toSubscribeMessage();
        fail('exception not thrown');
      } catch (e) {
        expect(e, isA<AuthorizationFailureException>());
      }
    });

    test(
        'testThrowsAuthorizationFailureExceptionIfAuthorizerReturnsInvalidJSON',
        () async {
      when(mockAuthorizer.authorize(any, any))
          .thenAnswer((_) => Future.value('{\"auth\":\"'));

      try {
        await channel.toSubscribeMessage();
        fail('exception not thrown');
      } catch (e) {
        expect(e, isA<AuthorizationFailureException>());
      }
    });

    test(
        'testThrowsAuthorizationFailureExceptionIfAuthorizerReturnsJSONWithoutAnAuthToken',
        () async {
      when(mockAuthorizer.authorize(any, any))
          .thenAnswer((_) => Future.value('{\"fish\":\"chips\"'));

      try {
        await channel.toSubscribeMessage();
        fail('exception not thrown');
      } catch (e) {
        expect(e, isA<AuthorizationFailureException>());
      }
    });

    test('testTriggerWithValidEventSendsMessage', () async {
      when(mockConnection.state).thenReturn(ConnectionState.CONNECTED);
      await channel.updateState(ChannelState.SUBSCRIBED);
      (channel as PrivateChannelImpl)
          .trigger('client-myEvent', '{\"fish\":\"chips\"}');
      verify(mockConnection.sendMessage(
          '{\"event\":\"client-myEvent\",\"channel\":\"' +
              channelName +
              '\",\"data\":\"{\\\"fish\\\":\\\"chips\\\"}\"}'));
    });

    test('testTriggerWithNullEventNameThrowsException', () async {
      when(mockConnection.state).thenReturn(ConnectionState.CONNECTED);
      await channel.updateState(ChannelState.SUBSCRIBED);
      expect(
          () => (channel as PrivateChannelImpl)
              .trigger(null, '{\"fish\":\"chips\"}'),
          throwsArgumentError);
    });

    test('testTriggerWithInvalidEventNameThrowsException', () async {
      when(mockConnection.state).thenReturn(ConnectionState.CONNECTED);
      await channel.updateState(ChannelState.SUBSCRIBED);
      expect(
          () => (channel as PrivateChannelImpl)
              .trigger('myEvent', '{\"fish\":\"chips\"}'),
          throwsArgumentError);
    });

    test('testTriggerWithString', () async {
      when(mockConnection.state).thenReturn(ConnectionState.CONNECTED);
      await channel.updateState(ChannelState.SUBSCRIBED);
      (channel as PrivateChannelImpl).trigger('client-myEvent', 'string');

      verify(mockConnection.sendMessage(
          '{\"event\":\"client-myEvent\",\"channel\":\"' +
              channelName +
              '\",\"data\":\"string\"}'));
    });

    test('testTriggerWhenChannelIsInInitialStateThrowsException', () async {
      when(mockConnection.state).thenReturn(ConnectionState.CONNECTED);

      expect(
          () => (channel as PrivateChannelImpl)
              .trigger('client-myEvent', '{\"fish\":\"chips\"}'),
          throwsStateError);
    });

    test('testTriggerWhenChannelIsInSubscribeSentStateThrowsException',
        () async {
      when(mockConnection.state).thenReturn(ConnectionState.CONNECTED);
      await channel.updateState(ChannelState.SUBSCRIBE_SENT);

      expect(
          () => (channel as PrivateChannelImpl)
              .trigger('client-myEvent', '{\"fish\":\"chips\"}'),
          throwsStateError);
    });

    test('testTriggerWhenChannelIsInUnsubscribedStateThrowsException',
        () async {
      when(mockConnection.state).thenReturn(ConnectionState.CONNECTED);
      await channel.updateState(ChannelState.UNSUBSCRIBED);

      expect(
          () => (channel as PrivateChannelImpl)
              .trigger('client-myEvent', '{\"fish\":\"chips\"}'),
          throwsStateError);
    });

    test('testTriggerWhenConnectionIsInDisconnectedStateThrowsException',
        () async {
      when(mockConnection.state).thenReturn(ConnectionState.DISCONNECTED);
      await channel.updateState(ChannelState.SUBSCRIBED);

      expect(
          () => (channel as PrivateChannelImpl)
              .trigger('client-myEvent', '{\"fish\":\"chips\"}'),
          throwsStateError);
    });

    test('testTriggerWhenConnectionIsInConnectingStateThrowsException',
        () async {
      when(mockConnection.state).thenReturn(ConnectionState.CONNECTING);
      await channel.updateState(ChannelState.SUBSCRIBED);

      expect(
          () => (channel as PrivateChannelImpl)
              .trigger('client-myEvent', '{\"fish\":\"chips\"}'),
          throwsStateError);
    });

    test('testCannotBindIfListenerIsNotAPrivateChannelEventListener', () async {
      final ChannelEventListener listener = MockChannelEventListener();

      try {
        await channel.bind('private-myEvent', listener);
        fail('now throws error');
      } catch (e) {
        expect(e, isA<ArgumentError>());
      }
    });
  }

  @override
  void testPublicChannelName() {
    test('public channel name', () {
      expect(() => newInstance('stuffchannel'), throwsArgumentError);
    });
  }

  @override
  void testPresenceChannelName() {
    test('presence channel name', () {
      expect(() => newInstance('presence-stuffchannel'), throwsArgumentError);
    });
  }

  @override
  void testPrivateEncryptedChannelName() {
    test('private encrypted channel name', () {
      expect(() => newInstance('presence-encrypted=stuffchannel'),
          throwsArgumentError);
    });
  }

  @override
  void testPrivateChannelName() {
    newInstance("private-stuffchannel");
  }

  @override
  void testReturnsCorrectSubscribeMessage() {
    test('should returns correct subscribe message', () async {
      expect(
          await channel.toSubscribeMessage(),
          '{\"event\":\"pusher:subscribe\",\"data\":{\"channel\":\"' +
              channelName +
              '\",' +
              AUTH_RESPONSE +
              '}}');
    });
  }

  /* end of tests */

  @override
  ChannelImpl newInstance(final String channelName) {
    return PrivateChannelImpl(
        mockConnection, channelName, mockAuthorizer, mockFactory);
  }

  @override
  String get channelName {
    return 'private-my-channel';
  }

  @override
  ChannelEventListener getEventListener() {
    final PrivateChannelEventListener listener =
        MockPrivateChannelEventListener();
    return listener;
  }
}

void main() {
  final t = PrivateChannelImplTest();
  t.testMain();
}
