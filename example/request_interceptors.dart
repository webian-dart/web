import 'package:web/web.dart';

void main() async {
  final web = Web();
  web.options.baseUrl = "http://httpbin.org/";
  web.options.connectTimeout = 5000;
  web.interceptors
      .add(InterceptorsWrapper(onRequest: (RequestOptions options) async {
    print(options.connectTimeout);
    switch (options.path) {
      case "/fakepath1":
        return web.resolve("fake data");
      case "/fakepath2":
        return web.get("/get");
      case "/fakepath3":
        // You can also return a HttpError directly.
        return web.reject("test error");
      case "/fakepath4":
        // Here is equivalent to call web.reject("test error")
        return WebError(error: "test error");
      default:
        return options; //continue
    }
  }));
  Response response;
  response = await web.get("/fakepath1");
  assert(response.data == "fake data");
  response = await web.get("/fakepath2");
  assert(response.data["headers"] is Map);
  try {
    response = await web.get("/fakepath3");
  } on WebError catch (e) {
    assert(e.message == "test error");
    assert(e.response == null);
  }
  try {
    response = await web.get("/fakepath4");
  } on WebError catch (e) {
    print(e);
    assert(e.message == "test error");
    assert(e.response == null);
  }
  response = await web.get("/get");
  assert(response.data["headers"] is Map);
  try {
    await web.get("xsddddd");
  } on WebError catch (e) {
    assert(e.response!.statusCode == 404);
  }
}
