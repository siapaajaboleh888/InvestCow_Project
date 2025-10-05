import 'package:flutter/material.dart';

class PasarModalPage extends StatelessWidget {
  const PasarModalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pasar Modal'),
        backgroundColor: Colors.cyan[400],
        foregroundColor: Colors.white,
      ),
      body: const Center(child: Text('Ini adalah halaman Pasar Modal')),
    );
  }
}
