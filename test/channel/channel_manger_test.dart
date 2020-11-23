import 'package:mockito/mockito.dart';
import 'package:pusher_websocket/src/authorizer.dart';
import 'package:pusher_websocket/src/channel/channel_event_listner.dart';
import 'package:pusher_websocket/src/channel/channel_state.dart';
import 'package:pusher_websocket/src/channel/impl/channel_manger.dart';
import 'package:pusher_websocket/src/channel/impl/internal_channel.dart';
import 'package:pusher_websocket/src/channel/impl/presence_channel_impl.dart';
import 'package:pusher_websocket/src/channel/impl/private_channel_impl.dart';
import 'package:pusher_websocket/src/channel/presence_channel_event_listener.dart';
import 'package:pusher_websocket/src/channel/private_channel_event_listener.dart';
import 'package:pusher_websocket/src/connection/connection_state.dart';
import 'package:pusher_websocket/src/connection/connection_state_change.dart';
import 'package:pusher_websocket/src/connection/impl/internal_connection.dart';
import 'package:pusher_websocket/src/util/factory.dart';
import 'package:test/test.dart';

import '../mocks.dart';

final String CHANNEL_NAME = 'my-channel';
final String PRIVATE_CHANNEL_NAME = '-my-channel';
final String PRESENCE_CHANNEL_NAME = 'presence-my-channel';
final String OUTGOING_SUBSCRIBE_MESSAGE = '{\"event\":\"pusher:subscribe\"}';
final String OUTGOING_UNSUBSCRIBE_MESSAGE =
    '{\"event\":\"pusher:unsubscribe\"}';
final String SOCKET_ID = '21234.41243';
final String PRIVATE_OUTGOING_SUBSCRIBE_MESSAGE =
    '{\"event\":\"pusher:subscribe\", \"data\":{}}';

void main() {
  ChannelManager channelManager;
  InternalConnection mockConnection;
  InternalChannel mockInternalChannel;
  ChannelEventListener mockEventListener;
  PrivateChannelImpl mockPrivateChannel;
  PrivateChannelEventListener mockPrivateChannelEventListener;
  PresenceChannelImpl mockPresenceChannel;
  PresenceChannelEventListener mockPresenceChannelEventListener;
  Factory factory;

  ChannelManager subscriptionTestChannelManager;
  Factory subscriptionTestFactory;
  InternalConnection subscriptionTestConnection;

  setUp(() {
    mockConnection = MockInternalConnection();
    mockInternalChannel = MockInternalChannel();
    mockEventListener = MockChannelEventListener();
    mockPrivateChannel = MockPrivateChannelImpl();
    mockPrivateChannelEventListener = MockPrivateChannelEventListener();
    mockPresenceChannel = MockPresenceChannelImpl();
    mockPresenceChannelEventListener = MockPresenceChannelEventListener();
    factory = MockFactory();
    subscriptionTestFactory = MockFactory();
    subscriptionTestConnection = MockInternalConnection();

    when(factory.queueOnEventThread(any)).thenAnswer((realInvocation) {
      final r = realInvocation.positionalArguments[0];
      r();
      return null;
    });

    when(mockInternalChannel.name).thenReturn(CHANNEL_NAME);
    when(mockInternalChannel.toSubscribeMessage())
        .thenAnswer((_) => Future.value(OUTGOING_SUBSCRIBE_MESSAGE));
    when(mockInternalChannel.toUnsubscribeMessage())
        .thenReturn(OUTGOING_UNSUBSCRIBE_MESSAGE);
    when(mockInternalChannel.eventListener).thenReturn(mockEventListener);
    when(mockConnection.socketId).thenReturn(SOCKET_ID);
    when(mockConnection.state).thenReturn(ConnectionState.CONNECTED);
    when(mockPrivateChannel.name).thenReturn(PRIVATE_CHANNEL_NAME);
    when(mockPrivateChannel.toSubscribeMessage())
        .thenAnswer((_) => Future.value(PRIVATE_OUTGOING_SUBSCRIBE_MESSAGE));
    when(mockPrivateChannel.eventListener)
        .thenReturn(mockPrivateChannelEventListener);
    when(mockPresenceChannel.name).thenReturn(PRESENCE_CHANNEL_NAME);
    when(mockPresenceChannel.toSubscribeMessage())
        .thenAnswer((_) => Future.value(PRIVATE_OUTGOING_SUBSCRIBE_MESSAGE));
    when(mockPresenceChannel.eventListener)
        .thenReturn(mockPresenceChannelEventListener);

    channelManager = ChannelManager(factory);
    channelManager.connection = mockConnection;

    when(subscriptionTestFactory.queueOnEventThread(any))
        .thenAnswer((realInvocation) {
      final r = realInvocation.positionalArguments[0];
      r();
      return null;
    });
    subscriptionTestChannelManager = ChannelManager(subscriptionTestFactory);
    subscriptionTestChannelManager.connection = subscriptionTestConnection;
  });

  test('testSetConnectionBindsAsListener', () {
    final manager = ChannelManager(factory);
    final InternalConnection connection = MockInternalConnection();

    manager.connection = connection;
    verify(connection.bind(ConnectionState.CONNECTED, manager));
  });

  test('testSetConnectionUnbindsFromPreviousConnection', () {
    final manager = ChannelManager(factory);
    final InternalConnection connection = MockInternalConnection();

    manager.connection = connection;

    final InternalConnection secondConnection = MockInternalConnection();
    manager.connection = secondConnection;
    verify(connection.unbind(ConnectionState.CONNECTED, manager));
  });

  test('testSetConnectionWithNullConnectionThrowsException', () {
    final manager = ChannelManager(factory);

    expect(() => manager.connection = null, throwsArgumentError);
  });

  test('testSubscribeWithAListenerAndNoEventsSubscribes', () async {
    await channelManager.subscribeTo(mockInternalChannel, mockEventListener);

    verify(mockConnection.sendMessage(OUTGOING_SUBSCRIBE_MESSAGE));
    verifyNever(mockInternalChannel.bind(any, any));
  });

  test(
      'testSubscribeWithAListenerAndEventsBindsTheListenerToTheEventsBeforeSubscribing',
      () async {
    await channelManager.subscribeTo(
        mockInternalChannel, mockEventListener, ['event1', 'event2']);

    verify(mockInternalChannel.bind('event1', mockEventListener));
    verify(mockInternalChannel.bind('event2', mockEventListener));
    verify(mockConnection.sendMessage(OUTGOING_SUBSCRIBE_MESSAGE));
  });

  test('testSubscribeSetsStatusOfChannelToSubscribeSent', () async {
    await channelManager.subscribeTo(mockInternalChannel, mockEventListener);
    verify(mockInternalChannel.updateState(ChannelState.SUBSCRIBE_SENT));
  });

  test('testSubscribeWithANullListenerAndNoEventsSubscribes', () async {
    await channelManager.subscribeTo(mockInternalChannel, null);

    verify(mockConnection.sendMessage(OUTGOING_SUBSCRIBE_MESSAGE));
    verifyNever(mockInternalChannel.bind(any, any));
  });

  test('testSubscribeWithNullChannelThrowsException', () async {
    try {
      await channelManager.subscribeTo(null, mockEventListener);
      fail('throw exception');
    } catch (e) {
      expect(e, isA<ArgumentError>());
    }
  });

  test('testSubscribeWithADuplicateNameThrowsException', () async {
    try {
      await channelManager.subscribeTo(mockInternalChannel, mockEventListener);
      await channelManager.subscribeTo(mockInternalChannel, mockEventListener);
      fail('throw exception');
    } catch (e) {
      expect(e, isA<ArgumentError>());
    }
  });

  test('testSubscribeToPrivateChannelSubscribes', () async {
    await channelManager.subscribeTo(
        mockPrivateChannel, mockPrivateChannelEventListener);

    verify(mockPrivateChannel.toSubscribeMessage());
    verify(mockConnection.sendMessage(PRIVATE_OUTGOING_SUBSCRIBE_MESSAGE));
  });

  test(
      'testSubscribeWhileDisconnectedQueuesSubscriptionUntilConnectedCallbackIsReceived',
      () async {
    when(mockConnection.state).thenReturn(ConnectionState.DISCONNECTED);

    await channelManager.subscribeTo(mockInternalChannel, mockEventListener);
    verifyNever(mockConnection.sendMessage(any));

    when(mockConnection.state).thenReturn(ConnectionState.CONNECTED);
    await channelManager.onConnectionStateChange(ConnectionStateChange(
        ConnectionState.CONNECTING, ConnectionState.CONNECTED));
    verify(mockConnection.sendMessage(OUTGOING_SUBSCRIBE_MESSAGE));
  });

  test(
      'testDelayedSubscriptionThatFailsToAuthorizeNotifiesListenerAndDoesNotAttemptToSubscribe',
      () async {
    final exception =
        AuthorizationFailureException(message: 'Unable to contact auth server');
    when(mockConnection.state).thenReturn(ConnectionState.DISCONNECTED);
    when(mockPrivateChannel.toSubscribeMessage()).thenThrow(exception);

    await channelManager.subscribeTo(
        mockPrivateChannel, mockPrivateChannelEventListener);
    verifyNever(mockConnection.sendMessage(any));

    when(mockConnection.state).thenReturn(ConnectionState.CONNECTED);
    channelManager.onConnectionStateChange(ConnectionStateChange(
        ConnectionState.CONNECTING, ConnectionState.CONNECTED));
    verify(mockPrivateChannelEventListener.onAuthenticationFailure(
        'Unable to contact auth server', exception));
    verifyNever(mockConnection.sendMessage(any));
  });

  test('testSubscriptionsAreResubscribedEveryTimeTheConnectionIsReestablished',
      () async {
    when(mockConnection.state).thenReturn(ConnectionState.DISCONNECTED);

    // initially the connection is down so it should not attempt to
    // subscribe
    await channelManager.subscribeTo(mockInternalChannel, mockEventListener);
    verifyNever(mockConnection.sendMessage(any));

    // when the connection is made the first subscribe attempt should be
    // made
    when(mockConnection.state).thenReturn(ConnectionState.CONNECTED);
    await channelManager.onConnectionStateChange(ConnectionStateChange(
        ConnectionState.CONNECTING, ConnectionState.CONNECTED));
    verify(mockConnection.sendMessage(any)).called(1);

    // when the connection fails and comes back up the channel should be
    // subscribed again
    when(mockConnection.state).thenReturn(ConnectionState.DISCONNECTED);
    await channelManager.onConnectionStateChange(ConnectionStateChange(
        ConnectionState.CONNECTED, ConnectionState.DISCONNECTED));

    when(mockConnection.state).thenReturn(ConnectionState.CONNECTED);
    await channelManager.onConnectionStateChange(ConnectionStateChange(
        ConnectionState.DISCONNECTED, ConnectionState.CONNECTED));

    //TODO(amond) : called 2?
    verify(mockConnection.sendMessage(OUTGOING_SUBSCRIBE_MESSAGE)).called(1);
  });

  // TODO(Amond) : test
}
