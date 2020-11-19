abstract class WebSocketListener {
  void onMessage(String message);

  /*
   * If this stream closes and sends a done event, the [onDone] handler is
   * called. If [onDone] is `null`, nothing happens.
   */
  void onClose(final int code, final String reason, final bool remote);

  /*
   * The [onError] callback must be of type `void onError(Object error)` or
   * `void onError(Object error, StackTrace stackTrace)`. If [onError] accepts
   * two arguments it is called with the error object and the stack trace
   * (which could be `null` if this stream itself received an error without
   * stack trace).
   * Otherwise it is called with just the error object.
   * If [onError] is omitted, any errors on this stream are considered unhandled,
   * and will be passed to the current [Zone]'s error handler.
   * By default unhandled async errors are treated
   * as if they were uncaught top-level errors.
   */
  void onError(Object error, [StackTrace stackTrace]);
}
