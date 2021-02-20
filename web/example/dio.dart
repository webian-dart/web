import 'package:Web/Web.dart';

/// More examples see https://github.com/tautalos/Web/tree/master/example
void main() async {
  var Web = Web();
  final response = await Web.get('https://google.com');
  print(response.data);
}
