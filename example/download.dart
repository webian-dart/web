import 'dart:async';
import 'dart:io';

import 'package:web/web.dart';

// In this example we download a image and listen the downloading progress.
void main() async {
  var web = Web();
  web.interceptors.add(LogInterceptor());
  // This is big file(about 200M)
  //   var url = 'http://download.dcloud.net.cn/HBuilder.9.0.2.macosx_64.dmg';

  var url =
      'https://cdn.jsdelivr.net/gh/tautalos/flutter-in-action@1.0/docs/imgs/book.jpg';

  // var url = 'https://www.google.com/img/bdlogo.gif';
  await download1(web, url, './example/book.jpg');
  await download1(web, url, (Headers headers) => './example/book1.jpg');
  await download2(web, url, './example/book2.jpg');
}

Future download1(Web web, String url, savePath) async {
  final cancelToken = CancelToken();
  try {
    await web.download(url, savePath,
        onReceiveProgress: showDownloadProgress, cancelToken: cancelToken);
  } catch (e) {
    print(e);
  }
}

//Another way to downloading small file
Future download2(Web web, String url, String savePath) async {
  try {
    final response = await web.get(
      url,
      onReceiveProgress: showDownloadProgress,
      //Received data with List<int>
      options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
          receiveTimeout: 0),
    );
    print(response.headers);
    final file = File(savePath);
    var raf = file.openSync(mode: FileMode.write);
    // response.data is List<int> type
    raf.writeFromSync(response.data);
    await raf.close();
  } catch (e) {
    print(e);
  }
}

void showDownloadProgress(received, total) {
  if (total != -1) {
    print((received / total * 100).toStringAsFixed(0) + '%');
  }
}
