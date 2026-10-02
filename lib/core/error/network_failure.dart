import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Whether [error] means the server could not be reached: no internet, a
/// connection that dropped, or one that never answered. A phone that shows a
/// signal but passes no data fails this way too.
///
/// A server that answered with an error status is not a network failure.
bool isNetworkFailure(Object error) =>
    error is SocketException ||
    error is http.ClientException ||
    error is TimeoutException ||
    error is HandshakeException;
