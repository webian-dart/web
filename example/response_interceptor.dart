import 'package:web/web.dart';

void main() async {
  const URL_NOT_FIND = "https://wendux.github.io/xxxxx/";
  const URL_NOT_FIND_1 = URL_NOT_FIND + "1";
  const URL_NOT_FIND_2 = URL_NOT_FIND + "2";
  const URL_NOT_FIND_3 = URL_NOT_FIND + "3";
  final web = Web();
  web.options.baseUrl = "http://httpbin.org/";
  web.interceptors.add(InterceptorsWrapper(onResponse: (Response response) {
    return response.data["data"]; //
  }, onError: (Fault e) async {
    if (e.response != null) {
      switch (e.response!.request!.path) {
        case URL_NOT_FIND:
          return e;
        case URL_NOT_FIND_1:
          // you can also return a HttpError directly.
          return web.resolve("fake data");
        case URL_NOT_FIND_2:
          return Response(data: "fake data");
        case URL_NOT_FIND_3:
          return 'custom error info [${e.response!.statusCode}]';
      }
    }
    return e;
  }));

  Response response;
  response = await web.get("/get");
  assert(response.data["headers"] is Map);
  try {
    await web.get(URL_NOT_FIND);
  } on Fault catch (e) {
    assert(e.response!.statusCode == 404);
  }
  response = await web.get(URL_NOT_FIND + "1");
  assert(response.data == "fake data");
  response = await web.get(URL_NOT_FIND + "2");
  assert(response.data == "fake data");
  try {
    await web.get(URL_NOT_FIND + "3");
  } on Fault catch (e) {
    assert(e.message == 'custom error info [404]');
  }
}
