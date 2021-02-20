import 'package:web/web.dart';

/// More examples see https://github.com/tautalos/Web/tree/master/example
void main() async {
  var web = Web();
  final response = await web.get('https://google.com');
  print(response.data);
}
