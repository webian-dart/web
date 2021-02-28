import 'package:web/web.dart';
import 'package:web_http2_adapter/web_http2_adapter.dart';

void main() async {
  var web = Web()
    ..options.baseUrl = 'https://google.com'
    ..interceptors.add(LogInterceptor())
    ..httpClientAdapter = Http2Adapter(
      ConnectionManager(
        idleTimeout: 10000,
        // Ignore bad certificate
        onClientCreate: (_, config) => config.onBadCertificate = (_) => true,
      ),
    );

  Response<String> response;

  response = await web.get('/?xx=6');
  print(response.data!.length);
  print(response.redirects.length);
  print(response.data);
}
