import 'package:meta/meta.dart';
import 'package:mockito/mockito.dart';
import 'package:pusher_websocket/src/channel/channel_event_listner.dart';
import 'package:pusher_websocket/src/channel/channel_state.dart';
import 'package:pusher_websocket/src/channel/impl/channel_impl.dart';
import 'package:pusher_websocket/src/channel/pusher_event.dart';
import 'package:pusher_websocket/src/util/factory.dart';
import 'package:test/test.dart';

void main() {
  ChannelImplTest().testMain();
}

class ChannelImplTest {
  static final String EVENT_NAME = 'my-event';

  ChannelEventListener mockListener;
  Factory mockFactory;
  ChannelImpl channel;

  void testPublicChannelName() {
    test('public channel name', () {
      newInstance('my-channel');
    });
  }

  void testPresenceChannelName() {
    test('Presence Channel Name', () {
      expect(() => newInstance('presence-my-channel'), throwsArgumentError);
    });
  }

  void testPrivateEncryptedChannelName() {
    test('Private Encrypted Channel Name', () {
      expect(() => newInstance('private-encrypted-my-channel'),
          throwsArgumentError);
    });
  }

  void testPrivateChannelName() {
    test('private channel name', () {
      expect(() => newInstance('private-my-channel'), throwsArgumentError);
    });
  }

  void testReturnsCorrectSubscribeMessage() {
    test('should returns correct subscribe message', () {
      expect(
          channel.toSubscribeMessage(),
          '{\"event\":\"pusher:subscribe\",\"data\":{\"channel\":\"' +
              channelName +
              '\"}}');
    });
  }

  @mustCallSuper
  void testMain() {
    setUp(() {
      mockFactory = MockFactory();

      when(mockFactory.queueOnEventThread(any)).thenAnswer((r) {
        Function f = r.positionalArguments[0];
        f.call();
        return;
      });
      mockListener = getEventListener();
      channel = newInstance(channelName);
      channel.eventListener = mockListener;
    });

    test('null channel name throws exception', () {
      expect(() => newInstance(null), throwsArgumentError);
    });

    testPublicChannelName();
    testPresenceChannelName();
    testPrivateEncryptedChannelName();
    testPrivateChannelName();
    testReturnsCorrectSubscribeMessage();

    test('get name returns name', () {
      expect(channelName, channel.name);
    });

    test('should returns correct unsubscribe message', () {
      expect(
          channel.toUnsubscribeMessage(),
          '{\"event\":\"pusher:unsubscribe\",\"data\":{\"channel\":\"' +
              channelName +
              '\"}}');
    });

    test(
        'Internal Subscription Succeeded Message Is Translated To A Subscription Successful Callback',
        () {
      channel.bind(EVENT_NAME, mockListener);
      channel.onMessage(
          'pusher_internal:subscription_succeeded',
          '{\"event\":\"pusher_internal:subscription_succeeded\",\"data\":\"{}\",\"channel\":\"' +
              channelName +
              '\"}');

      verify(mockListener.onSubscriptionSucceeded(channelName)).called(1);
    });

    test('is subscribed method', () {
      expect(channel.isSubscribed, isFalse);
      channel.bind(EVENT_NAME, mockListener);
      channel.onMessage(
          'pusher_internal:subscription_succeeded',
          '{\"event\":\"pusher_internal:subscription_succeeded\",\"data\":\"{}\",\"channel\":\"' +
              channelName +
              '\"}');

      expect(channel.isSubscribed, isTrue);
    });

    test('Data Is Extracted From Message And Passed To Single Listener',
        () async {
      // {"event":"my-event","data":"{\"some\":\"data\"}","channel":"my-channel"}
      expect(channel.isSubscribed, isFalse);
      await channel.bind(EVENT_NAME, mockListener);
      await channel.onMessage(EVENT_NAME,
          '{\"event\":\"event1\",\"data\":\"{\\\"fish\\\":\\\"chips\\\"}\"}');

      var captured = verify(mockListener.onEvent(captureAny)).captured.single;

      expect(captured, isA<PusherEvent>());
      expect(captured.eventName, 'event1');
      expect(captured.data, '{\"fish\":\"chips\"}');
    });

    test('Data Is Extracted From Message And Passed To Multiple Listeners',
        () async {
      final ChannelEventListener mockListener2 = getEventListener();
      await channel.bind(EVENT_NAME, mockListener);
      await channel.bind(EVENT_NAME, mockListener2);
      await channel.onMessage(EVENT_NAME,
          '{\"event\":\"event1\",\"data\":\"{\\\"fish\\\":\\\"chips\\\"}\"}');

      var captured = verify(mockListener.onEvent(captureAny)).captured.single;
      expect(captured, isA<PusherEvent>());
      expect(captured.eventName, 'event1');
      expect(captured.data, '{\"fish\":\"chips\"}');

      var captured2 = verify(mockListener2.onEvent(captureAny)).captured.single;
      expect(captured2, isA<PusherEvent>());
      expect(captured2.eventName, 'event1');
      expect(captured2.data, '{\"fish\":\"chips\"}');
    });

    test('Event Is Not Passed On If There Are No Matching Listeners', () async {
      await channel.bind(EVENT_NAME, mockListener);
      await channel.onMessage('DifferentEventName',
          '{\"event\":\"event1\",\"data\":{\"fish\":\"chips\"}}');
      verifyNever(mockListener.onEvent(any));
    });

    test('Bind With Null Event Name Throws Exception', () async {
      expect(() => channel.bind(null, mockListener), throwsArgumentError);
    });

    test('Bind With Null Listener Throws Exception', () async {
      expect(() => channel.bind(EVENT_NAME, null), throwsArgumentError);
    });

    test('Bind To Internal Event Throws Exception', () async {
      expect(
          () => channel.bind(
              'pusher_internal:subscription_succeeded', mockListener),
          throwsArgumentError);
    });

    test('Unbind With Null Event Name Throws Exception', () async {
      await channel.bind(EVENT_NAME, mockListener);
      expect(() => channel.unbind(null, mockListener), throwsArgumentError);
    });

    test('Unbind With Null Listener Throws Exception', () async {
      await channel.bind(EVENT_NAME, mockListener);
      expect(() => channel.unbind(EVENT_NAME, null), throwsArgumentError);
    });

    test(
        'Unbind When Listener Is Not Bound To Event Is Ignored And Does Not Throw Exception',
        () async {
      await channel.bind(EVENT_NAME, mockListener);
      await channel.unbind('different event name', mockListener);
    });

    test(
        'Update State To Subscribe Sent Does Not Notify Listener That Subscription Succeeded',
        () async {
      await channel.bind(EVENT_NAME, mockListener);
      channel.updateState(ChannelState.SUBSCRIBE_SENT);
      verifyNever(mockListener.onSubscriptionSucceeded(channelName));
    });

    test('testUpdateStateToSubscribedNotifiesListenerThatSubscriptionSucceeded',
        () async {
      await channel.bind(EVENT_NAME, mockListener);
      channel.updateState(ChannelState.SUBSCRIBE_SENT);
      channel.updateState(ChannelState.SUBSCRIBED);

      verify(mockListener.onSubscriptionSucceeded(channelName));
    });

    test('testBindWhenInUnsubscribedStateThrowsException', () async {
      channel.updateState(ChannelState.UNSUBSCRIBED);
      expect(() => channel.bind(EVENT_NAME, mockListener), throwsStateError);
    });

    test('Unbind When In Unsubscribed State Throws Exception', () async {
      await channel.bind(EVENT_NAME, mockListener);
      channel.updateState(ChannelState.UNSUBSCRIBED);
      expect(() => channel.unbind(EVENT_NAME, mockListener), throwsStateError);
    });
  }

  /* end of tests */

  /// This method is overridden in the test subclasses so that these tests can
  /// be run against [PrivateChannelImpl] and [PresenceChannelImpl].
  @protected
  ChannelImpl newInstance(final String channelName) {
    return ChannelImpl(channelName, mockFactory);
  }

  /// This method is overridden in the test subclasses so that the private
  /// channel tests can run with a valid private channel name and the presence
  /// channel tests can run with a valid presence channel name.
  @protected
  String get channelName {
    return 'my-channel';
  }

  /// This method is overridden to allow the private and presence channel tests
  /// to use the appropriate listener subclass.
  @protected
  ChannelEventListener getEventListener() {
    final ChannelEventListener listener = MockChannelEventListener();
    return listener;
  }
}

class MockChannelEventListener extends Mock implements ChannelEventListener {}

class MockFactory extends Mock implements Factory {}
