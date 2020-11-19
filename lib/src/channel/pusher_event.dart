class PusherEvent {
  final Map<String, Object> eventData;

  PusherEvent(this.eventData);

  /// getProperty returns the value associated with the key, or null.
  /// It is recommended that you use the specialized getters in this class instead.
  ///
  /// key : The key you wish to get.
  Object getProperty(String key) {
    return eventData[key];
  }

  /// Returns the userId associated with this event.
  ///
  /// @return
  ///      The userID string: https://pusher.com/docs/channels/using_channels/events#user-id-in-client-events,
  ///      or null if the event is not a client event on a presence channel.
  String get userId {
    return eventData['user_id'] as String;
  }

  String get channelName {
    return eventData['channel'] as String;
  }

  String get eventName {
    return eventData['event'] as String;
  }

  String get data {
    return eventData['data'] as String;
  }

  @override
  String toString() {
    return eventData.toString();
  }
}
