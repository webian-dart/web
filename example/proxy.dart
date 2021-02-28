import 'dart:io';

import 'package:web/adapter.dart';
import 'package:web/web.dart';

void main() async {
  var web = Web();
  web.options.headers['user-agent'] = 'xxx';
  web.options.contentType = 'text';
  // web.options.connectTimeout = 2000;
  // More about HttpClient proxy topic please refer to Dart SDK doc.
  (web.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
      (HttpClient client) {
    client.findProxy = (uri) {
      //proxy all request to localhost:8888
      return 'PROXY localhost:8888';
    };
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
  };
  var dir = Directory('./cookies');
  await dir.create();
  Response<String> response;
  //response= await web.get('https://github.com/wendux/fly');
  response = await web.get('https://www.google.com');
  print(response.statusCode);
  response = await web.get('https://www.google.com');
  print(response.statusCode);
}
