/// Represents a user that is subscribed to a
/// {@link com.pusher.client.channel.PresenceChannel PresenceChannel}.

class User {
  /// The user id
  final String id;

  /// jsonData The user JSON data
  final String _jsonData;

  User(this.id, this._jsonData);

  /// Custom additional information about a user as a String encoding a JSON
  /// hash
  ///
  /// @return The user info as a JSON string
  String get info {
    return _jsonData;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          _jsonData == other._jsonData;

  @override
  int get hashCode => id.hashCode ^ _jsonData.hashCode;

  @override
  String toString() {
    return 'User{id: $id, _jsonData: $_jsonData}';
  }

// TODO(amond) : get info

}
