import 'dart:collection';

Map<String, V> toCaseInsensitiveKeyMap<V>([Map<String, V>? value]) {
  final map = LinkedHashMap<String, V>(
    equals: (key1, key2) => key1.toLowerCase() == key2.toLowerCase(),
    hashCode: (key) => key.toLowerCase().hashCode,
  );
  if (value?.isNotEmpty == true) map.addAll(value!);
  return map;
}
