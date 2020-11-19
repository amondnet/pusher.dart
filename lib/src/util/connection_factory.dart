/// Abstract factory to be used for
/// building HttpAuthorizer connections
abstract class ConnectionFactory {
  String channelName;
  String socketId;

  String get body;

  String get charset;

  String get contentType;
}
