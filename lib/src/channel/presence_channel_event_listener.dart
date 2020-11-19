import 'private_channel_event_listener.dart';
import 'user.dart';

/// Used to listen for presence specific events as well as those defined by the
/// [PrivateChannelEventListener] and parent interfaces.
abstract class PresenceChannelEventListener
    extends PrivateChannelEventListener {
  /// Called when the subscription has succeeded and an initial list of
  /// subscribed users has been received from Pusher.
  ///
  /// [channelName]
  ///            The name of the channel the list is for.
  /// [users]
  ///            The users.
  void onUsersInformationReceived(String channelName, Set<User> users);

  /// Called when a new user subscribes to the channel.
  ///
  /// [channelName]
  ///            channelName The name of the channel the list is for.
  /// [user]
  ///            The newly subscribed user.
  void userSubscribed(String channelName, User user);

  /// Called when an existing user unsubscribes from the channel.
  ///
  /// [channelName]
  ///            The name of the channel that the user unsubscribed from.
  /// [user]
  ///            The user who unsubscribed.
  void userUnsubscribed(String channelName, User user);
}
