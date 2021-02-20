import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:web/web.dart';

main() async {
  var web = Web(BaseOptions(connectTimeout: 5000));
  web.interceptors.add(LogInterceptor(responseBody: true));

  var imgFile = File("");
  String savePath = "";
  String token = "xxxxx";

  // Sending stream
  await web.post(
    "https://www.googleapis.com/upload/storage/v1/b/opine-world/o?uploadType=media&name=$savePath",
    data: imgFile.openRead(), // Post with Stream<List<int>>
    options: Options(
      headers: {
        HttpHeaders.contentTypeHeader: ContentType.text,
        HttpHeaders.contentLengthHeader: imgFile.lengthSync(),
        HttpHeaders.authorizationHeader: "Bearer $token",
      },
    ),
  );

  // Sending bytes(Just an example, you can send json(Map) directly in action)
  List<int> postData = utf8.encode('{"userName":"wendux"}');
  await web.post(
    "http://www.dtworkroom.com/doris/1/2.0.0/test",
    data: Stream.fromIterable(postData.map((e) => [e])),
    options: Options(
      headers: {
        HttpHeaders.contentLengthHeader: postData.length, // Set content-length
      },
    ),
  );
}
