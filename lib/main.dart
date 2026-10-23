import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DiverParkApp());
}

class DiverParkApp extends StatelessWidget {
  const DiverParkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DiverPark',
      home: WebAppView(),
    );
  }
}

class WebAppView extends StatefulWidget {
  const WebAppView({super.key});

  @override
  State<WebAppView> createState() => _WebAppViewState();
}

class _WebAppViewState extends State<WebAppView> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'AndroidAlarm',
        onMessageReceived: (JavaScriptMessage message) async {
          // Recibe las órdenes del HTML
          if (message.message == 'play') {
            // Suena la alarma nativa de Android en bucle infinito
            FlutterRingtonePlayer().playAlarm(
              looping: true,
              volume: 1.0,
              asAlarm: true,
            );
          } else if (message.message == 'stop') {
            // Detiene el sonido
            FlutterRingtonePlayer().stop();
          }
        },
      )
      ..clearCache()          // Borra la caché para que se vea el botón de Cierre de Caja
      ..clearLocalStorage()   // Borra la memoria local vieja
      ..loadRequest(Uri.parse('https://script.google.com/macros/s/AKfycbzf20CKhMmyuqVsebFAJH5NDlArRrH0URG1mbvj2Wd_zhg-BVrvEc3WsaEnLnf0zmQ47w/exec'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: WebViewWidget(controller: controller)),
    );
  }
}
