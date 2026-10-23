import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:alarm_plus/alarm_plus.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const DiverParkApp());
}

class DiverParkApp extends StatelessWidget {
  const DiverParkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DiverPark',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primaryColor: const Color(0xFF00CC6A),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final String apiUrl = 'https://script.google.com/macros/s/AKfycbyIBpYEYrLQyoETOcpvquyRtqLPDKLyHNxnROJx6xRaEduddkcsTrshdreawhYcNQiNMw/exec';
  List<dynamic> juegos = [];
  List<dynamic> activos = [];
  Timer? _timer;
  final Set<String> _alarmasActivas = {};

  @override
  void initState() {
    super.initState();
    _inicializarApp();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _actualizarTiempos());
  }

  Future<void> _inicializarApp() async {
    await AlarmPlus.initialize();
    await _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'action': 'obtenerDatos'}),
      );
      final data = jsonDecode(response.body);
      if (data['success']) {
        setState(() {
          juegos = data['data']['juegos'];
          activos = data['data']['activos'];
        });
      }
    } catch (e) {
      debugPrint('Error cargando datos: $e');
    }
  }

  void _actualizarTiempos() {
    final ahora = DateTime.now().millisecondsSinceEpoch;
    for (var item in activos) {
      final fin = item['tiempo_fin'] as int;
      final restante = ((fin - ahora) / 1000).ceil();
      if (restante <= 0 && !_alarmasActivas.contains(item['id'])) {
        _alarmasActivas.add(item['id']);
        _dispararAlarma(item);
      }
    }
    setState(() {});
  }

  Future<void> _dispararAlarma(Map<String, dynamic> item) async {
    try {
      await AlarmPlus.schedule(
        id: item['id'].toString(),
        time: DateTime.now().add(const Duration(seconds: 1)),
        data: {
          'id': item['id'],
          'nombre': item['nino_nombre'],
          'juego': item['juego_nombre'],
        },
        notificationSettings: AlarmSettings(
          id: item['id'].hashCode,
          dateTime: DateTime.now().add(const Duration(seconds: 1)),
          assetAudioPath: 'assets/alarm.mp3',
          loopAudio: true,
          vibrate: true,
          volume: 1.0,
          notificationTitle: '¡Tiempo Cumplido!',
          notificationBody: '${item['nino_nombre']} terminó en ${item['juego_nombre']}',
        ),
      );
    } catch (e) {
      debugPrint("Error en alarma: $e");
    }
  }

  Future<void> _registrarIngreso(Map<String, dynamic> juego, String nombre, String desc, String padre) async {
    final nuevoActivo = {
      'id': 'ACT-${DateTime.now().millisecondsSinceEpoch}',
      'juego_id': juego['id'],
      'juego_nombre': juego['nombre'],
      'nino_nombre': nombre,
      'nino_desc': desc,
      'padre': padre,
      'tiempo_fin': DateTime.now().add(Duration(minutes: juego['minutos'])).millisecondsSinceEpoch,
    };
    try {
      await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'action': 'registrarIngreso', 'data': nuevoActivo}),
      );
      await _cargarDatos();
    } catch (e) {
      debugPrint('Error registrando: $e');
    }
  }

  Future<void> _finalizarTurno(Map<String, dynamic> item, double valor, String metodo) async {
    if (valor > 0) {
      final tx = {
        'id': 'TXP-${DateTime.now().millisecondsSinceEpoch}',
        'fecha': DateFormat('HH:mm:ss').format(DateTime.now()),
        'juego': item['juego_nombre'],
        'nino': item['nino_nombre'],
        'padre': item['padre'],
        'metodo': metodo,
        'total': valor,
      };
      await http.post(Uri.parse(apiUrl), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'action': 'guardarTransaccion', 'data': tx}));
    }
    await http.post(Uri.parse(apiUrl), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'action': 'eliminarActivo', 'data': {'id': item['id']}}));
    
    await AlarmPlus.stop();
    
    _alarmasActivas.remove(item['id']);
    await _cargarDatos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DiverPark'), backgroundColor: const Color(0xFF1E293B)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFormulario(),
            const SizedBox(height: 20),
            ..._buildListaJuegos(),
          ],
        ),
      ),
    );
  }

  Widget _buildFormulario() {
    final nombreCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final padreCtrl = TextEditingController();
    String? juegoSeleccionado = juegos.isNotEmpty ? juegos[0]['id'] : null;

    return Card(
      color: const Color(0xFF1E293B),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: juegoSeleccionado,
              items: juegos.map((j) => DropdownMenuItem<String>(value: j['id'], child: Text('${j['nombre']} (${j['minutos']} min)'))).toList(),
              onChanged: (v) => juegoSeleccionado = v,
              decoration: const InputDecoration(labelText: 'Juego'),
            ),
            TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre del Niño')),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Ropa')),
            TextField(controller: padreCtrl, decoration: const InputDecoration(labelText: 'Padre')),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                final juego = juegos.firstWhere((j) => j['id'] == juegoSeleccionado);
                _registrarIngreso(juego, nombreCtrl.text, descCtrl.text, padreCtrl.text);
                nombreCtrl.clear(); descCtrl.clear(); padreCtrl.clear();
              },
              child: const Text('Iniciar Cronómetro'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildListaJuegos() {
    final agrupados = <String, List<dynamic>>{};
    for (var a in activos) {
      agrupados.putIfAbsent(a['juego_nombre'], () => []).add(a);
    }
    return agrupados.entries.map((entry) {
      return Card(
        color: const Color(0xFF1E293B),
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.key, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
              const Divider(),
              ...entry.value.map((item) {
                final restante = ((item['tiempo_fin'] - DateTime.now().millisecondsSinceEpoch) / 1000).ceil().clamp(0, 9999);
                final mins = (restante ~/ 60).toString().padLeft(2, '0');
                final secs = (restante % 60).toString().padLeft(2, '0');
                return ListTile(
                  title: Text(item['nino_nombre']),
                  subtitle: Text('Padre: ${item['padre']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$mins:$secs', style: TextStyle(fontSize: 20, color: restante <= 0 ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.amber),
                        onPressed: () => _finalizarTurno(item, 10000, 'Efectivo'),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      );
    }).toList();
  }
}
