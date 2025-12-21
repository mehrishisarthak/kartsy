import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class ModelViewerScreen extends StatelessWidget {
  final String localFilePath;

  const ModelViewerScreen({super.key, required this.localFilePath});

  @override
  Widget build(BuildContext context) {
    final String src = 'file://$localFilePath';

    return Scaffold(
      appBar: AppBar(
        title: const Text("3D View"),
        backgroundColor: Colors.transparent,
      ),
      body: ModelViewer(
        src: src,
        alt: "A 3D model of the product",
        ar: true, // Enables AR mode on supported devices
        autoRotate: true,
        cameraControls: true,
        backgroundColor: Colors.white,
      ),
    );
  }
}