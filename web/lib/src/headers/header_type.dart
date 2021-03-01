import 'package:http_parser/http_parser.dart';

class HeaderType {
  HeaderType._();

  // Header field name
  static const accept = 'accept';
  static const contentEncoding = 'content-encoding';
  static const contentLength = 'content-length';
  static const contentType = 'content-type';
  static const wwwAuthenticate = 'www-authenticate';

  // Header field value
  static const jsonContent = 'application/json; charset=utf-8';
  static const formUrlEncodedContent = 'application/x-www-form-urlencoded';

  static final jsonMimeType = MediaType.parse(jsonContent);
}
