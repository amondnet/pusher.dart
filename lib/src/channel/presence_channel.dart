import 'private_channel.dart';
import 'user.dart';

/// An object that represents a Pusher presence channel. An implementation of
/// this interface is returned when you call
/// [Pusher.subscribePresence(String)] or
/// [Pusher.subscribePresence(String, PresenceChannelEventListener, String...)]
/// .
abstract class PresenceChannel extends PrivateChannel {
  /// Gets a set of users currently subscribed to the channel.
  Set<User> getUsers();

  /// Gets the user that represents the currently connected client.
  User getMe();
}
