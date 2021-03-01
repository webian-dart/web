// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'dart:io';

import 'package:test/test.dart';
import 'package:web/web.dart';

import 'utils.dart';

void main() {
  group('Web on download should', () {
    setUp(startServer);
    tearDown(stopServer);

    test('download a file to the specified path', () async {
      const savePath = '../_download_test.md';
      final web = Web()..options.baseUrl = serverUrl.toString();
      await web.download(
        '/download',
        savePath, // disable gzip
        onReceiveProgress: (received, total) {
          // ignore progress
        },
      );

      final f = File(savePath);
      expect(f.readAsStringSync(), equals('I am a text file'));
      f.deleteSync(recursive: false);
    });

    test('download a file with the specified uri to a path', () async {
      const savePath = '../_download_test.md';
      final web = Web()..options.baseUrl = serverUrl.toString();
      await web.downloadUri(
        serverUrl.replace(path: '/download'),
        (header) => savePath, // disable gzip
      );

      final f = File(savePath);
      expect(f.readAsStringSync(), equals('I am a text file'));
      f.deleteSync(recursive: false);
    });

    test('store the error as the failed response data', () async {
      const savePath = '../_download_test.md';
      final web = Web()..options.baseUrl = serverUrl.toString();
      final response =
          await web.download('/error', savePath).catchError((e) => e.response);
      expect(response.data, 'error');
    });

    test('not set the error as the response data', () async {
      const savePath = '../_download_test.md';
      final web = Web()..options.baseUrl = serverUrl.toString();
      final response = await web
          .download(
            '/error',
            savePath,
            options: Options(receiveDataWhenStatusError: false),
          )
          .catchError((e) => e.response);
      expect(response.data, null);
    });

    test('timeout', () async {
      const savePath = '../_download_test.md';
      final web = Web(BaseOptions(
        receiveTimeout: 100,
        baseUrl: serverUrl.toString(),
      ));
      expect(
          web.download('/download', savePath).catchError((e) => throw e.type),
          throwsA(FaultType.RECEIVE_TIMEOUT));
    });

    test('cancel the download', () async {
      const savePath = '../_download_test.md';
      final cancelToken = CancelToken();
      Future.delayed(Duration(milliseconds: 100), () {
        cancelToken.cancel();
      });
      expect(
        Web()
            .download(
              serverUrl.toString() + '/download',
              savePath,
              cancelToken: cancelToken,
            )
            .catchError((e) => throw e.type),
        throwsA(FaultType.CANCEL),
      );
      //print(r);
    });
  });
}
