import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'logo_painter.dart';

class ExportLogoScreen extends StatefulWidget {
  const ExportLogoScreen({super.key});
  @override
  State<ExportLogoScreen> createState() => _ExportLogoScreenState();
}

class _ExportLogoScreenState extends State<ExportLogoScreen> {
  final GlobalKey _key = GlobalKey();
  String _status = 'Premi il pulsante per esportare';

  Future<void> _export() async {
    try {
      final boundary = _key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 4.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/ghamma_icon.png');
      await file.writeAsBytes(bytes);
      setState(() => _status = 'Salvato in:\n${file.path}');
    } catch (e) {
      setState(() => _status = 'Errore: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RepaintBoundary(
              key: _key,
              child: const SizedBox(
                width: 256,
                height: 256,
                child: GhammaLogo(size: 256, opacity: 1.0),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _export,
              child: const Text('Esporta PNG 1024x1024'),
            ),
            const SizedBox(height: 16),
            Text(
              _status,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
