import 'package:flutter/material.dart';

class CctvPage extends StatelessWidget {
  const CctvPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CCTV Kandang')),
      body: const Center(
        child: Text(
          'Streaming CCTV akan ditambahkan di sini.\nSementara ini adalah placeholder.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
