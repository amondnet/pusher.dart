/// Subscriptions to [PrivateChannel] and
/// [PresenceChannel] channels need to
/// be authorized. This interface provides an {@link #authorize} as a mechanism
/// for doing this.
///
///
/// See the [HttpAuthorizer] as an
/// example.
///
abstract class Authorizer {
  /// Called when a channel is to be authenticated.
  ///
  /// [channelName]
  ///            The name of the channel to be authenticated.
  /// [socketId]
  ///            A unique socket connection ID to be used with the
  ///            authentication. This uniquely identifies the connection that
  ///            the subscription is being authenticated for.
  /// throws [AuthorizationFailureException]
  ///             if the authentication fails.
  Future<String> authorize(String channelName, String socketId);
}

/// Used to indicate an authorization failure.
class AuthorizationFailureException implements Exception {
  final Object cause;
  final StackTrace stackTrace;
  final String message;
  AuthorizationFailureException({this.message, this.cause, this.stackTrace});
}
