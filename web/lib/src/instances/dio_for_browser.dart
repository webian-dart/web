import 'package:Web/Web.dart';

import '../Web.dart';
import '../client_adapters/browser_http_client_adapter.dart';
import '../options/options.dart';

Web createWeb([BaseOptions? options]) => WebForBrowser(options);

class WebForBrowser with WebMixin implements Web {
  /// Create Web instance with default [Options].
  /// It's mostly just one Web instance in your application.
  WebForBrowser([BaseOptions? options]) {
    this.options = options ?? BaseOptions();
    httpClientAdapter = BrowserHttpClientAdapter();
  }
}
