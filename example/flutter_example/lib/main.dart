import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:web/web.dart';

import 'http.dart'; // make web as global top-level variable
import 'routes/request.dart';

// Must be top-level function
void _parseAndDecode(String response) {
  return jsonDecode(response);
}

Future parseJson(String text) {
  return compute(_parseAndDecode, text);
}

void main() {
  // add interceptors
  //web.interceptors.add(CookieManager(WebCookies()));
  web.interceptors.add(LogInterceptor());
  //(web.transformer as DefaultTransformer).jsonDecodeCallback = parseJson;
  web.options.receiveTimeout = 15000;
//  (web.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
//      (client) {
//    client.findProxy = (uri) {
//      //proxy to my PC(charles)
//      return "PROXY 10.1.10.250:8888";
//    };
//  };
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title = ""}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _text = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Column(children: [
          ElevatedButton(
            child: Text("Request"),
            onPressed: () {
              web
                  .get<String>(
                      "https://www.thelotent.com/WSVistaWebClient/OData.svc/GetNowShowingSessions?\$format=json&\$filter=CinemaId+eq+%27100%27")
                  .then((r) {
                setState(() {
                  print(r.data);
                  _text = r.data?.replaceAll(RegExp(r"\s"), "") ?? "";
                });
              }).catchError((fault) {
                print(fault);
              });
            },
          ),
          ElevatedButton(
            child: Text("Open new page5"),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return RequestRoute();
              }));
            },
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Text(_text),
            ),
          )
        ]),
      ),
    );
  }
}
