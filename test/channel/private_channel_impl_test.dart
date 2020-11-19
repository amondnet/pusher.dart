import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../lib/src/channel/channel_event_listner.dart';
import '../../lib/src/channel/impl/channel_impl.dart';
import '../../lib/src/channel/private_channel_event_listener.dart';
import '../../lib/src/connection/impl/internal_connection.dart';
import 'channel_impl_test.dart';

class PrivateChannelImplTest extends ChannelImplTest {
  InternalConnection mockConnection;

  @override
  void testMain() {
    super.testMain();

    setUp(() {
      // when(mock)
      mockConnection = MockConnection();
    });
  }

  /* end of tests */

  @override
  ChannelImpl newInstance(final String channelName) {
    return PrivateChannelImpl(
        mockConnection, channelName, mockAuthorizer, factory);
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
  PrivateChannelImplTest().testMain();
}

class MockConnection extends Mock implements InternalConnection {}

class MockPrivateChannelEventListener extends Mock
    implements PrivateChannelEventListener {}
