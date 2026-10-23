import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const DiverParkApp());
}

class DiverParkApp extends StatelessWidget {
  const DiverParkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DiverPark',
      home: const WebAppView(),
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
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    
    // Configuramos el audio para que se repita infinitamente
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
    _audioPlayer.setVolume(1.0);

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'AndroidAlarm',
        onMessageReceived: (JavaScriptMessage message) {
          if (message.message == 'play') {
            _audioPlayer.play(UrlSource('https://actions.google.com/sounds/v1/alarms/alarm_clock.ogg'));
          } else if (message.message == 'stop') {
            _audioPlayer.stop();
          }
        },
      )
      ..loadRequest(Uri.parse('https://script.google.com/macros/s/AKfycbzf20CKhMmyuqVsebFAJH5NDlArRrH0URG1mbvj2Wd_zhg-BVrvEc3WsaEnLnf0zmQ47w/exec'));
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: WebViewWidget(controller: controller),
      ),
    );
  }
}
