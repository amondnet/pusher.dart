import 'package:logging/logging.dart';

import 'connection_state.dart';

final _logger = Logger('ConnectionStateChange');

/// Represents a change in connection state.
class ConnectionStateChange {
  final ConnectionState previousState;
  final ConnectionState currentState;

  /// Used within the library to create a connection state change. Not be used
  /// used as part of the API.
  ///
  /// [previousState] The previous connection state
  /// [currentState] The current connection state
  ConnectionStateChange(this.previousState, this.currentState) {
    if (previousState == currentState) {
      _logger.fine(
          'Attempted to create an connection state update where both previous and current state are: $currentState');
    }
  }

  /// The previous connections state. The state the connection has transitioned
  /// from.
  ConnectionState getPreviousState() {
    return previousState;
  }

  /// The current connection state. The state the connection has transitioned
  /// to.
  ConnectionState getCurrentState() {
    return currentState;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectionStateChange &&
          runtimeType == other.runtimeType &&
          previousState == other.previousState &&
          currentState == other.currentState;

  @override
  int get hashCode => previousState.hashCode ^ currentState.hashCode;
}
