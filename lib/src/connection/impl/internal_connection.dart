import 'package:pusher_websocket/src/connection/connection.dart';

abstract class InternalConnection extends Connection {
  void sendMessage(String message);

  void disconnect();
}
