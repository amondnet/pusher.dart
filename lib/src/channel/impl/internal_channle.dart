import '../channel.dart';
import '../channel_event_listner.dart';
import '../channel_state.dart';
import '../pusher_event.dart';

abstract class InternalChannel extends Channel
    implements Comparable<InternalChannel> {
  String toSubscribeMessage();

  String toUnsubscribeMessage();

  PusherEvent prepareEvent(String event, String message);

  void onMessage(String event, String message);

  void updateState(ChannelState state);

  set eventListener(ChannelEventListener listener);

  ChannelEventListener get eventListener;
}
