import 'package:flutter/material.dart';

class KunjunganPage extends StatelessWidget {
  const KunjunganPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kunjungan'),
        backgroundColor: Colors.cyan[400],
        foregroundColor: Colors.white,
      ),
      body: const Center(child: Text('Ini adalah halaman Kunjungan')),
    );
  }
}
