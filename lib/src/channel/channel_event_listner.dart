import 'subscription_event_listener.dart';

/// Client applications should implement this interface if they want to be
/// notified when events are received on a public or private channel.
///
///
/// To bind your implementation of this interface to a channel, either:
///
///
/// * Call [Pusher.subscribe(String)] to subscribe and
/// receive an instance of [Channel].
/// * Call [Channel.bind(String, SubscriptionEventListener)] to bind your
/// listener to a specified event.
///
///
/// Or, call
/// [Pusher.subscribe(String, ChannelEventListener, String...)]
/// to subscribe to a channel and bind your listener to one or more events at the
/// same time.
///
abstract class ChannelEventListener extends SubscriptionEventListener {
  /// Callback that is fired when a subscription success acknowledgement
  /// message is received from Pusher after subscribing to the channel.
  ///
  ///
  /// For public channels this callback will be more or less immediate,
  /// assuming that you are connected to Pusher at the time of subscription.
  /// For private channels this callback will not be fired unless you are
  /// successfully authenticated.
  ///
  ///
  /// [channelName] The name of the channel that was successfully subscribed.
  void onSubscriptionSucceeded(String channelName);
}
