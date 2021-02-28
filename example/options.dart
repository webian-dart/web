import 'dart:io';

import 'package:web/web.dart';

void main() async {
  var web = Web(BaseOptions(
    baseUrl: 'http://httpbin.org/',
    connectTimeout: 5000,
    receiveTimeout: 100000,
    // 5s
    headers: {
      HttpHeaders.userAgentHeader: 'web',
      'api': '1.0.0',
    },
    contentType: Headers.jsonContentType,
    // Transform the response data to a String encoded with UTF8.
    // The default value is [ResponseType.JSON].
    responseType: ResponseType.plain,
  ));

  Response response;

  response = await web.get('/get');
  print(response.data);

  final responseMap = await web.get(
    '/get',
    // Transform response data to Json Map
    options: Options(responseType: ResponseType.json),
  );
  print(responseMap.data);
  response = await web.post(
    '/post',
    data: {
      'id': 8,
      'info': {'name': 'wendux', 'age': 25}
    },
    // Send data with 'application/x-www-form-urlencoded' format
    options: Options(
      contentType: Headers.formUrlEncodedContentType,
    ),
  );
  print(response.data);

  response = await web.request(
    '/',
    options: RequestOptions(baseUrl: 'https://google.com'),
  );
  print(response.data);
}
