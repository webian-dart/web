import 'package:web/web.dart';

Future getHttp() async {
  var web = Web();
  web.interceptors.add(LogInterceptor(responseBody: true));
  web.options.baseUrl = 'http://httpbin.org';
  web.options.headers = {'Authorization': 'Bearer '};
  //web.options.baseUrl = 'http://localhost:3000';
  var response = await web.post('/post',
      data: null,
      options: Options(
          contentType: HeaderType.jsonContent,
          headers: {'Content-Type': 'application/json'}));
  print(response);
}

void main() async {
  await getHttp();

//  var response = await Web().get('http://tautalos.club');
//  print(response.isRedirect);

//  var t = await MultipartFile.fromBytes([5]);
//  print(t);
}
