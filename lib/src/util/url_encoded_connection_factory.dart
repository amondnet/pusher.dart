import 'dart:convert';

import 'connection_factory.dart';

/// Form URL-Encoded Connection Factory
///
/// Allows HttpAuthorizer to write URL parameters to the connection
class UrlEncodedConnectionFactory extends ConnectionFactory {
  final Map<String, String> mQueryStringParameters;

  /// Create a Form URL-encoded factory
  ///
  /// [queryStringParameters] extra parameters that need to be added to query string.
  UrlEncodedConnectionFactory([final Map<String, String> queryStringParameters])
      : mQueryStringParameters = queryStringParameters ?? {};

  @override
  String get body {
    final urlParameters = StringBuffer();
    try {
      urlParameters
        ..write('channel_name=')
        ..write(Uri.encodeQueryComponent(channelName,
            encoding: Encoding.getByName(charset)));
      urlParameters
        ..write('&socket_id=')
        ..write(Uri.encodeQueryComponent(socketId,
            encoding: Encoding.getByName(charset)));

      // Adding extra parameters supplied to be added to query string.
      for (final parameterName in mQueryStringParameters.keys) {
        urlParameters..write("&")..write(parameterName)..write("=");
        urlParameters
          ..write(Uri.encodeQueryComponent(
              mQueryStringParameters[parameterName],
              encoding: Encoding.getByName(charset)));
      }
    } catch (e, s) {
      // e.printStackTrace();
      print(e);
    }
    return urlParameters.toString();
  }

  @override
  final String charset = 'UTF-8';

  @override
  final String contentType = 'application/x-www-form-urlencoded';
}
