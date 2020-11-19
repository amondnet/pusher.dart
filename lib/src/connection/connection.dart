import 'connection_event_listener.dart';
import 'connection_state.dart';

/// Represents a connection to Pusher.
///
abstract class Connection {
  /// No need to call this via the API. Instead use [Pusher.connect].
  void connect();

  /// Bind to connection events.
  ///
  /// [state]
  ///            The states to bind to.
  /// [eventListener]
  ///            A listener to be called when the state changes.
  void bind(ConnectionState state, ConnectionEventListener eventListener);

  /// Unbind from connection state changes.
  ///
  /// [state]
  ///            The state to unbind from.
  /// [eventListener]
  ///            The listener to be unbound.
  /// return `true` if the unbind was successful, otherwise `false`
  bool unbind(ConnectionState state, ConnectionEventListener eventListener);

  /// Gets the current connection state.
  ConnectionState get state;

  /// Gets a unique connection ID.

  String get socketId;
}
