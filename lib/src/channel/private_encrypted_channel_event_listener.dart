import 'private_channel_event_listener.dart';

/// Interface to listen to private encrypted channel events.
/// Note: This needs to extend the [PrivateChannelEventListener] because in the
/// [ChannelManager._handleAuthenticationFailure] we assume it's safe to cast to a
/// [PrivateChannelEventListener]
abstract class PrivateEncryptedChannelEventListener
    extends PrivateChannelEventListener {
  void onDecryptionFailure(String event, String reason);
}
