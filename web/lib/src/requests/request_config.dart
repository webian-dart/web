import '../../Web.dart';
import '../headers.dart';
import 'requests.dart';

/// The [RequestConfig] class describes the http request information and configuration.
class RequestConfig {
  RequestConfig({
    this.method,
    this.receiveTimeout,
    this.sendTimeout,
    Map<String, dynamic>? extra,
    Map<String, dynamic>? headers,
    String? contentType,
    this.responseType,
    this.validateStatus,
    this.receiveDataWhenStatusError = true,
    this.followRedirects = true,
    this.maxRedirects = 5,
    this.requestEncoder,
    this.responseDecoder,
  })  : headers = headers ?? {},
        extra = extra ?? {} {
    this.contentType = contentType;
  }

  /// Http method.
  String? method;

  /// Http request headers. The keys of initial headers will be converted to lowercase,
  /// for example 'Content-Type' will be converted to 'content-type'.
  ///
  /// You should use lowercase as the key name when you need to set the request header.
  Map<String, dynamic> headers;

  /// Timeout in milliseconds for sending data.
  /// [Web] will throw the [WebError] with [WebErrorType.SEND_TIMEOUT] type
  ///  when time out.
  int? sendTimeout;

  ///  Timeout in milliseconds for receiving data.
  ///  [Web] will throw the [WebError] with [WebErrorType.RECEIVE_TIMEOUT] type
  ///  when time out.
  ///
  /// [0] meanings no timeout limit.
  int? receiveTimeout;

  /// The request Content-Type. The default value is [ContentType.json].
  /// If you want to encode request body with 'application/x-www-form-urlencoded',
  /// you can set `ContentType.parse('application/x-www-form-urlencoded')`, and [Web]
  /// will automatically encode the request body.
  set contentType(String? contentType) {
    headers[Headers.contentTypeHeader] = contentType?.trim();
  }

  String? get contentType => headers[Headers.contentTypeHeader];

  /// [responseType] indicates the type of data that the server will respond with
  /// options which defined in [ResponseType] are `json`, `stream`, `plain`.
  ///
  /// The default value is `json`, Web will parse response string to json object automatically
  /// when the content-type of response is 'application/json'.
  ///
  /// If you want to receive response data with binary bytes, for example,
  /// downloading a image, use `stream`.
  ///
  /// If you want to receive the response data with String, use `plain`.
  ///
  /// If you want to receive the response data with  original bytes,
  /// that's to say the type of [Response.data] will be List<int>, use `bytes`
  ResponseType? responseType;

  /// `validateStatus` defines whether the request is successful for a given
  /// HTTP response status code. If `validateStatus` returns `true` ,
  /// the request will be perceived as successful; otherwise, considered as failed.
  ValidateStatus? validateStatus;

  /// Whether receiving response data when http status code is not successful.
  bool? receiveDataWhenStatusError;

  /// Custom field that you can retrieve it later in [Interceptor]、[Transformer] and the [Response] object.
  Map<String, dynamic> extra;

  /// see [HttpClientRequest.followRedirects]
  bool? followRedirects;

  /// Set this property to the maximum number of redirects to follow
  /// when [followRedirects] is `true`. If this number is exceeded
  /// an error event will be added with a [RedirectException].
  ///
  /// The default value is 5.
  int? maxRedirects;

  /// The default request encoder is utf8encoder, you can set custom
  /// encoder by this option.
  RequestEncoder? requestEncoder;

  /// The default response decoder is utf8decoder, you can set custom
  /// decoder by this option, it will be used in [Transformer].
  ResponseDecoder? responseDecoder;
}
