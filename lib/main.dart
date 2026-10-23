import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:alarm_plus/alarm_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Alarm.init();
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
          final data = jsonDecode(message.message);
          
          if (data['action'] == 'schedule') {
            await Alarm.set(
              alarmSettings: AlarmSettings(
                id: data['id'].hashCode,
                dateTime: DateTime.fromMillisecondsSinceEpoch(data['endTime']),
                assetAudioPath: 'assets/alarm.mp3',
                loopAudio: true,
                vibrate: true,
                volume: 1.0,
                notificationTitle: data['titulo'],
                notificationBody: data['mensaje'],
              ),
            );
          } else if (data['action'] == 'cancel') {
            await Alarm.stop(data['id'].hashCode);
          }
        },
      )
      ..loadRequest(Uri.parse('https://script.google.com/macros/s/AKfycbzf20CKhMmyuqVsebFAJH5NDlArRrH0URG1mbvj2Wd_zhg-BVrvEc3WsaEnLnf0zmQ47w/exec'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: WebViewWidget(controller: controller)),
    );
  }
}
