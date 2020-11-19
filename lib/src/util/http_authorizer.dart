import 'dart:convert';

import 'package:http/http.dart';
import 'package:pusher_websocket/src/util/url_encoded_connection_factory.dart';

import '../authorizer.dart';
import 'connection_factory.dart';

/// Used to authenticate a [PrivateChannel] or [PresenceChannel]
/// channel subscription.
///
///
/// Makes an HTTP request to a defined HTTP endpoint. Expects an authentication
/// token to be returned.
///
///
///
/// For more information see the
/// [http://pusher.com/docs/authenticating_users](Authenticating Users
/// documentation).
class HttpAuthorizer implements Authorizer {
  final Uri endPoint;
  final ConnectionFactory _connectionFactory;
  Map<String, String> _headers = {};

  /// Creates a new authorizer.
  ///
  /// [endPoint] The endpoint to be called when authenticating.
  /// [connectionFactory] a custom connection factory to be used for building the connection
  HttpAuthorizer(String endPoint, {ConnectionFactory connectionFactory})
      : endPoint = Uri.parse(endPoint),
        _connectionFactory = connectionFactory ?? UrlEncodedConnectionFactory();

  @override
  Future<String> authorize(String channelName, String socketId) async {
    try {
      _connectionFactory.channelName = channelName;
      _connectionFactory.socketId = socketId;
      final body = _connectionFactory.body;
      final defaultHeaders = <String, String>{};
      defaultHeaders['Content-Type'] = _connectionFactory.contentType;
      defaultHeaders['charset'] = _connectionFactory.charset;
      // Add in the user defined headers
      defaultHeaders.addAll(_headers);
      // Add in the Content-Length, so it can't be overwritten by _headers
      defaultHeaders['Content-Length'] = utf8.encode(body).length.toString();

      final response = await post(endPoint,
          body: body,
          headers: defaultHeaders,
          encoding: Encoding.getByName(_connectionFactory.charset));

      final responseHttpStatus = response.statusCode;
      if (responseHttpStatus != 200 && responseHttpStatus != 201) {
        throw AuthorizationFailureException(message: response.toString());
      }
      return response.body;
    } catch (e, s) {
      throw AuthorizationFailureException(cause: e, stackTrace: s);
    }
  }

  /// Set additional headers to be sent as part of the request.
  set headers(final Map<String, String> headers) {
    _headers = headers;
  }

  /// Identifies if the HTTP request will be sent over HTTPS.
  bool isSSL() {
    return endPoint.scheme == 'https';
  }
}
