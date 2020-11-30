import 'package:mockito/mockito.dart';
import 'package:pusher_websocket/src/authorizer.dart';
import 'package:pusher_websocket/src/channel/channel_event_listner.dart';
import 'package:pusher_websocket/src/channel/impl/internal_channel.dart';
import 'package:pusher_websocket/src/channel/impl/presence_channel_impl.dart';
import 'package:pusher_websocket/src/channel/impl/private_channel_impl.dart';
import 'package:pusher_websocket/src/channel/presence_channel_event_listener.dart';
import 'package:pusher_websocket/src/channel/private_channel_event_listener.dart';
import 'package:pusher_websocket/src/connection/impl/internal_connection.dart';
import 'package:pusher_websocket/src/util/factory.dart';

class MockInternalConnection extends Mock implements InternalConnection {}

class MockInternalChannel extends Mock implements InternalChannel {}

class MockChannelEventListener extends Mock implements ChannelEventListener {}

class MockFactory extends Mock implements Factory {}

class MockPrivateChannelImpl extends Mock implements PrivateChannelImpl {}

class MockPrivateChannelEventListener extends Mock
    implements PrivateChannelEventListener {}

class MockPresenceChannelImpl extends Mock implements PresenceChannelImpl {}

class MockPresenceChannelEventListener extends Mock
    implements PresenceChannelEventListener {}

class MockConnection extends Mock implements InternalConnection {}

class MockAuthorizer extends Mock implements Authorizer {}
