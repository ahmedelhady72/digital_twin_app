import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_gauges/gauges.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark(),
    home: const DigitalTwinDashboard(),
  );
}

class DigitalTwinDashboard extends StatefulWidget {
  const DigitalTwinDashboard({super.key});
  @override
  _DigitalTwinDashboardState createState() => _DigitalTwinDashboardState();
}

class _DigitalTwinDashboardState extends State<DigitalTwinDashboard> {
  late MqttServerClient client;
  List<List<double>> timeSeriesBuffer = [];
  double engineRUL = 0;
  bool isConnected = false;
  int totalPackets = 0;
  
  // قيم الحساسات الحالية من الـ Schema
  double temp = 0;     // s_2 (Inlet Temperature)
  double pressure = 0; // s_3 (HPC Pressure)
  double speed = 0;    // s_4 (LPC Pressure / Speed)

  final String backendUrl = "http://192.168.1.4:8000/predict";

  @override
  void initState() {
    super.initState();
    connectMQTT();
  }

  Future<void> connectMQTT() async {
    // تصحيح الخطأ: millisecondsSinceEpoch
    String clientId = 'client_${DateTime.now().millisecondsSinceEpoch}';
    client = MqttServerClient('broker.hivemq.com', clientId);
    client.port = 1883;
    client.keepAlivePeriod = 20;

    try {
      await client.connect();
      setState(() => isConnected = true);
      client.subscribe('ahmed/elhadyy/engine1', MqttQos.atMostOnce);
      
      client.updates!.listen((c) {
        final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
        final String pt = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        onMessageReceived(pt);
      });
    } catch (e) {
      print("MQTT Connection Error: $e");
    }
  }

  void onMessageReceived(String payload) {
    try {
      final Map<String, dynamic> data = jsonDecode(payload);
      
      setState(() {
        totalPackets++;
        // تحديث قيم العدادات فوراً بناءً على الـ Schema
        temp = (data["s_2"] ?? 0).toDouble();
        pressure = (data["s_3"] ?? 0).toDouble();
        speed = (data["s_4"] ?? 0).toDouble();

        // منطق الـ Sliding Window (أحدث 30 قراءة)
        if (timeSeriesBuffer.length >= 30) {
          timeSeriesBuffer.removeAt(0);
        }
        timeSeriesBuffer.add(parsePayload(data));
      });

      // الإرسال للسيرفر بمجرد اكتمال أول 30 قراءة، ثم مع كل قراءة جديدة
      if (timeSeriesBuffer.length == 30) {
        sendToBackend(timeSeriesBuffer);
      }
    } catch (e) {
      print("Payload Error: $e");
    }
  }

  List<double> parsePayload(Map<String, dynamic> data) {
    return [
      (data["setting_1"] ?? 0).toDouble(),
      (data["setting_2"] ?? 0).toDouble(),
      (data["s_2"] ?? 0).toDouble(),
      (data["s_3"] ?? 0).toDouble(),
      (data["s_4"] ?? 0).toDouble(),
      (data["s_7"] ?? 0).toDouble(),
      (data["s_8"] ?? 0).toDouble(),
      (data["s_9"] ?? 0).toDouble(),
      (data["s_11"] ?? 0).toDouble(),
      (data["s_12"] ?? 0).toDouble(),
      (data["s_13"] ?? 0).toDouble(),
      (data["s_14"] ?? 0).toDouble(),
      (data["s_15"] ?? 0).toDouble(),
      (data["s_17"] ?? 0).toDouble(),
      (data["s_20"] ?? 0).toDouble(),
      (data["s_21"] ?? 0).toDouble(),
    ];
  }

  Future<void> sendToBackend(List<List<double>> seriesData) async {
    try {
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"series_data": seriesData}),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          engineRUL = (result["prediction"] as num).toDouble();
        });
      }
    } catch (e) {
      print("Backend Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ENGINE 34 DIGITAL TWIN"),
        centerTitle: true,
        actions: [
          Icon(Icons.circle, color: isConnected ? Colors.green : Colors.red, size: 12),
          const SizedBox(width: 15),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            children: [
              // 1. عداد الـ RUL الرئيسي
              _buildMainRULGauge(),
              
              const SizedBox(height: 10),
              Text("Total Messages: $totalPackets", style: const TextStyle(color: Colors.grey)),
              const Divider(height: 40),

              // 2. صف الحساسات الحية (Real-time Sensors)
              const Text("LIVE TELEMETRY", style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSensorGauge("TEMP (s2)", temp, 600, 650, Colors.orange),
                  _buildSensorGauge("PRESS (s3)", pressure, 1550, 1610, Colors.blue),
                  _buildSensorGauge("SPEED (s4)", speed, 1350, 1450, Colors.purple),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainRULGauge() {
    return SizedBox(
      height: 250,
      child: SfRadialGauge(axes: <RadialAxis>[
        RadialAxis(
          minimum: 0, maximum: 250,
          ranges: <GaugeRange>[
            GaugeRange(startValue: 0, endValue: 70, color: Colors.red, startWidth: 10, endWidth: 10),
            GaugeRange(startValue: 70, endValue: 150, color: Colors.orange, startWidth: 10, endWidth: 10),
            GaugeRange(startValue: 150, endValue: 250, color: Colors.green, startWidth: 10, endWidth: 10),
          ],
          pointers: <GaugePointer>[
            NeedlePointer(value: engineRUL, needleColor: Colors.white, knobStyle: const KnobStyle(color: Colors.blue))
          ],
          annotations: <GaugeAnnotation>[
            GaugeAnnotation(
              widget: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(engineRUL.toStringAsFixed(1), style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
                  const Text("REMAINING LIFE", style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              angle: 90, positionFactor: 0.8,
            )
          ],
        )
      ]),
    );
  }

  Widget _buildSensorGauge(String title, double value, double min, double max, Color color) {
    return Column(
      children: [
        SizedBox(
          height: 90, width: 90,
          child: SfRadialGauge(axes: <RadialAxis>[
            RadialAxis(
              showLabels: false, showTicks: false, minimum: min, maximum: max,
              axisLineStyle: const AxisLineStyle(thickness: 0.15, cornerStyle: CornerStyle.bothCurve, thicknessUnit: GaugeSizeUnit.factor),
              pointers: <GaugePointer>[
                RangePointer(value: value, width: 0.15, sizeUnit: GaugeSizeUnit.factor, color: color, cornerStyle: CornerStyle.bothCurve)
              ],
              annotations: <GaugeAnnotation>[
                GaugeAnnotation(widget: Text(value.toStringAsFixed(1), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)))
              ],
            )
          ]),
        ),
        const SizedBox(height: 5),
        Text(title, style: const TextStyle(fontSize: 10, color: Colors.blueGrey)),
      ],
    );
  }
}