import 'package:flutter/material.dart';

class KandangPage extends StatelessWidget {
  const KandangPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        backgroundColor: Colors.brown[400],
        foregroundColor: Colors.white,
        title: const Text(
          'Manajemen Kandang',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [Colors.brown[400]!, Colors.brown[600]!],
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.pets, color: Colors.white, size: 60),
                      const SizedBox(height: 12),
                      const Text(
                        'Total Sapi',
                        style: TextStyle(fontSize: 20, color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '48',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ekor Sapi',
                        style: TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.home,
                              color: Colors.brown[700],
                              size: 40,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Kandang',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Text(
                              '6',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Icon(Icons.grass, color: Colors.green, size: 40),
                            const SizedBox(height: 8),
                            const Text(
                              'Pakan (kg)',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Text(
                              '850',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Daftar Kandang',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 6,
                itemBuilder: (context, index) {
                  final sapiCount = [8, 10, 7, 9, 6, 8][index];
                  final capacity = [10, 12, 10, 10, 8, 10][index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: Colors.brown[100],
                        radius: 30,
                        child: Icon(
                          Icons.home,
                          color: Colors.brown[700],
                          size: 30,
                        ),
                      ),
                      title: Text(
                        'Kandang ${String.fromCharCode(65 + index)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Isi: $sapiCount/$capacity ekor'),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: sapiCount / capacity,
                            backgroundColor: Colors.grey[300],
                            color: Colors.brown[400],
                          ),
                        ],
                      ),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.brown[400],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
