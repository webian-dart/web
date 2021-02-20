import 'package:web/web.dart';

void main() async {
  final web = Web(
    BaseOptions(
      baseUrl: "http://httpbin.org/",
      method: "GET",
    ),
  );

  Response response;
  // No generic type, the ResponseType will work.
  response = await web.get("/get");
  print(response.data is Map);
  // Specify the generic type(Map)
  response = await web.get<Map>("/get");
  print(response.data is Map);

  // Specify the generic type(String)
  response = await web.get<String>("/get");
  print(response.data is String);
  // Specify the ResponseType as ResponseType.plain
  response =
      await web.get("/get", options: Options(responseType: ResponseType.plain));
  print(response.data is String);

  // the content of "https://google.com" is a html file, So it can't be convert to Map type,
  // it will cause a FormatException.
  response = await web.get<Map>("https://google.com").catchError(print);

  // This works well.
  response = await web.get("https://google.com");
  print("done");
  // This works well too.
  response = await web.get<String>("https://google.com");
  print("done");
  // This is the recommended way.
  var r = await web.get<String>("https://google.com");
  print(r.data!.length);
}
