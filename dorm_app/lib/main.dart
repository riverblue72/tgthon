import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bluetooth RFID Reader',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const BluetoothPage(),
    );
  }
}

class BluetoothPage extends StatefulWidget {
  const BluetoothPage({super.key});

  @override
  _BluetoothPageState createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  List<BluetoothDevice> devicesList = [];

  @override
  void initState() {
    super.initState();
    // Bluetooth 장치 검색 시작
    flutterBlue.scan().listen((scanResult) {
      setState(() {
        if (!devicesList.contains(scanResult.device)) {
          devicesList.add(scanResult.device);
        }
      });
    });
  }

  void connectToDevice(BluetoothDevice device) async {
    await device.connect();
    // RFID 카드 읽기 로직 추가
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth RFID Reader'),
      ),
      body: ListView.builder(
        itemCount: devicesList.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(devicesList[index].name.isNotEmpty
                ? devicesList[index].name
                : 'Unknown device'),
            subtitle: Text(devicesList[index].id.toString()),
            onTap: () => connectToDevice(devicesList[index]),
          );
        },
      ),
    );
  }
}