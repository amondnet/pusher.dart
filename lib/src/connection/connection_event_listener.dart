import 'connection_state_change.dart';

/// Client applications should implement this interface if they wish to receive
/// notifications when the state of a [Connection] changes or an error is
/// thrown.
///
///
/// Implementations of this interface can be bound to the connection by calling
/// [Connection.bind(ConnectionState, ConnectionEventListener)]. The
/// connection itself can be retrieved from the [Pusher]
/// object by calling [Pusher.getConnection].
///
///
///
/// Alternatively, you can bind your implementation of the interface and connect
/// at the same time by calling
/// [Pusher.connect(ConnectionEventListener, ConnectionState...)]
/// .
abstract class ConnectionEventListener {
  /// Callback that is fired whenever the [ConnectionState] of the
  /// [Connection] changes. The state typically changes during connection
  /// to Pusher and during disconnection and reconnection.
  ///
  //
  //  This callback is only fired if the [ConnectionEventListener]
  /// has been bound to the new state by calling
  /// [Connection.bind(ConnectionState, ConnectionEventListener)] with
  /// either the new state or [ConnectionState.ALL].
  ///
  ///
  /// [change] An object that contains the previous state of the connection
  ///            and the new state. The new state can be retrieved by calling
  ///            [ConnectionStateChange.getCurrentState].
  void onConnectionStateChange(ConnectionStateChange change);

  /// Callback that indicates either:
  ///
  /// * An error message has been received from Pusher, or
  /// * An error has occurred in the client library.
  ///
  ///
  ///
  /// All [ConnectionEventListener]s that have been registered by
  /// calling [Connection.bind(ConnectionState, ConnectionEventListener)]
  /// will receive this callback, even if the
  /// [ConnectionEventListener] is only bound to specific connection
  /// status changes.
  ///
  ///
  /// [message]
  ///            A message indicating the cause of the error.
  /// [code]
  ///            The error code for the message. Can be null.
  /// [e]
  ///            The exception that was thrown, if any. Can be null.
  void onError(String message, String code, Exception e);
}
