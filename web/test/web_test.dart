// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('vm')
import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';
import 'package:web/web.dart';

void main() {
  group('Web should ', () {
    test('throw an error when trying to Get with an invalid URL', () {
      expect(Web().get('http://http.invalid').catchError((e) => throw e.error),
          throwsA(const TypeMatcher<SocketException>()));
    });

    test('cancel the request', () async {
      var web = Web();
      final token = CancelToken();
      Timer(Duration(milliseconds: 10), () {
        token.cancel('cancelled');
        web.httpClientAdapter.close(force: true);
      });

      var url = 'https://accounts.google.com';
      expect(
          web
              .get(url, cancelToken: token)
              .catchError((e) => throw CancelToken.isCancel(e)),
          throwsA(isTrue));
    });
  });
}
