import 'dart:async';

import 'package:web/web.dart';

/// If the request data is a `List` type, the [DefaultTransformer] will send data
/// by calling its `toString()` method. However, normally the List object is
/// not expected for request data( mostly need Map ). So we provide a custom
/// [Transformer] that will throw error when request data is a `List` type.

class MyTransformer extends DefaultTransformer {
  @override
  Future<String> transformRequest(RequestOptions options) async {
    if (options.data is List<String>) {
      throw Fault(error: "Can't send List to sever directly");
    } else {
      return super.transformRequest(options);
    }
  }

  /// The [Options] doesn't contain the cookie info. we add the cookie
  /// info to [Options.extra], and you can retrieve it in [ResponseInterceptor]
  /// and [Response] with `response.request.extra['cookies']`.
  @override
  Future transformResponse(
      RequestOptions options, ResponseBody response) async {
    options.extra['self'] = 'XX';
    return super.transformResponse(options, response);
  }
}

void main() async {
  var web = Web();
  // Use custom Transformer
  web.transformer = MyTransformer();

  final response = await web.get('https://www.google.com');
  print(response.request!.extra['self']);

  try {
    await web.post('https://www.google.com', data: ['1', '2']);
  } catch (e) {
    print(e);
  }
  print('xxx');
}
