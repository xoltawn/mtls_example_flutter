import 'dart:io';

import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart' as dioPlugin;

import 'package:http/io_client.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo For Using mTLS',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Demo For mTLS'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late IOClient client;
  late Dio dio = Dio();

  Future<List<int>> getKeyBytes() async {
    return (await rootBundle.load('assets/keys/private.key'))
        .buffer
        .asInt8List();
  }

  Future<List<int>> getCertificateChainBytes() async {
    return (await rootBundle.load('assets/keys/certificate.crt'))
        .buffer
        .asInt8List();
  }

  Future<SecurityContext> get globalContext async {
    List<int> keyBytes = await getKeyBytes();
    List<int> certificateChainBytes = await getCertificateChainBytes();

    SecurityContext sc = SecurityContext(withTrustedRoots: false);
    sc.usePrivateKeyBytes(keyBytes);
    sc.useCertificateChainBytes(certificateChainBytes);
    return sc;
  }

  void _initHttpClient() async {
    HttpClient _httpClient = HttpClient(context: await globalContext);
    _httpClient.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    client = IOClient(_httpClient);
  }


  void _initDioClient() async {
    List<int> keyBytes = await getKeyBytes();
    List<int> certificateChainBytes = await getCertificateChainBytes();



    (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
        (client) {
      SecurityContext sc = SecurityContext(withTrustedRoots: true);
      sc.useCertificateChainBytes(certificateChainBytes);
      sc.usePrivateKeyBytes(keyBytes);
      HttpClient httpClient = HttpClient(context: sc);
      httpClient.badCertificateCallback =
          (X509Certificate cert, String host, int port) {
        return true;
      };
      return httpClient;
    };
  }

  @override
  void initState() {
    _initHttpClient();
    _initDioClient();
    super.initState();
  }

  String endpoint = 'YOUR_URL';

  Future<void> _makeHttpRequest() async {
    http.Response response = await client.get(Uri.parse("$endpoint/ROUTE"),
        headers: {'Accept': 'application/json'});
    print(response.body);
  }

  Future<void> _makeDioRequest() async {
    dioPlugin.Response response = await dio.get("$endpoint/ROUTE");
    print(response.data);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Row(
            children: [
              Expanded(
                  child: OutlinedButton(
                    onPressed: _makeHttpRequest,
                    child: Row(
                      children: [Text('http')],
                    ),
                  )),
              const SizedBox(
                width: 16,
              ),
              Expanded(
                  child: OutlinedButton(
                    onPressed: _makeDioRequest,
                    child: Row(
                      children: [Text('dio')],
                    ),
                  )),
            ],
          ),
        ],
      ),
    );
  }
}
