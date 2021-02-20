import 'package:test/test.dart';
import 'package:web/web.dart';
import 'package:web_http2_adapter/web_http2_adapter.dart';

void main() {
  test('adds one to input values', () async {
    var web = Web()
      ..options.baseUrl = "https://www.google.com/"
      ..interceptors.add(LogInterceptor())
      ..httpClientAdapter = Http2Adapter(
        ConnectionManager(
          idleTimeout: 10,
          onClientCreate: (_, config) => config.onBadCertificate = (_) => true,
        ),
      );

    Response<String> response;
    response = await web.get("?xx=6");
    assert(response.statusCode == 200);
    response = await web.get(
      "nkjnjknjn.html",
      options: Options(validateStatus: (status) => true),
    );
    assert(response.statusCode == 404);
  });

  test("request with payload", () async {
    final web = Web()
      ..options.baseUrl = "https://postman-echo.com/"
      ..httpClientAdapter = Http2Adapter(ConnectionManager(
        idleTimeout: 10,
      ));

    final res = await web.post("post", data: "TEST");
    assert(res.data["data"] == "TEST");
  });
}
