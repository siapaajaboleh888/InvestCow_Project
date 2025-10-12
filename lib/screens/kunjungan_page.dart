import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class KunjunganPage extends StatefulWidget {
  const KunjunganPage({super.key});

  @override
  State<KunjunganPage> createState() => _KunjunganPageState();
}

class _KunjunganPageState extends State<KunjunganPage> {
  // Koordinat lokasi kandang di Bagandan, Pamekasan
  final String lokasiKandang = "Bagandan, Pamekasan, Madura, Jawa Timur";
  final double latitude = -7.1686;
  final double longitude = 113.4747;

  // Fungsi untuk membuka Google Maps
  Future<void> _bukaGoogleMaps() async {
    final String googleMapsUrl =
        "https://www.google.com/maps/search/?api=1&query=$latitude,$longitude";
    final Uri url = Uri.parse(googleMapsUrl);

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak dapat membuka Google Maps')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // Fungsi untuk membuka dialog penjadwalan
  void _bukaDialogJadwal() {
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    final TextEditingController namaController = TextEditingController();
    final TextEditingController telpController = TextEditingController();
    final TextEditingController keteranganController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Jadwalkan Kunjungan'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: namaController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: telpController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'No. Telepon/WhatsApp',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Tanggal Kunjungan'),
                      subtitle: Text(
                        DateFormat('dd MMMM yyyy').format(selectedDate),
                      ),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 90),
                          ),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.access_time),
                      title: const Text('Waktu Kunjungan'),
                      subtitle: Text(selectedTime.format(context)),
                      onTap: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedTime = picked;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: keteranganController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Keperluan/Keterangan',
                        prefixIcon: Icon(Icons.notes),
                        border: OutlineInputBorder(),
                        hintText:
                            'Misal: Ingin melihat kambing, beli kambing, dll',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan[400],
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (namaController.text.isEmpty ||
                        telpController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Nama dan No. Telepon harus diisi'),
                        ),
                      );
                      return;
                    }

                    // Kirim konfirmasi via WhatsApp
                    _kirimKonfirmasiWhatsApp(
                      namaController.text,
                      telpController.text,
                      selectedDate,
                      selectedTime,
                      keteranganController.text,
                    );

                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Jadwal kunjungan berhasil dibuat!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: const Text('Konfirmasi'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Fungsi untuk mengirim konfirmasi via WhatsApp
  Future<void> _kirimKonfirmasiWhatsApp(
    String nama,
    String telp,
    DateTime tanggal,
    TimeOfDay waktu,
    String keterangan,
  ) async {
    // Ganti dengan nomor WhatsApp pemilik kandang
    const String nomorPemilik = '6281234567890';

    final String pesan =
        '''
Halo, saya ingin jadwalkan kunjungan:

Nama: $nama
No. Telepon: $telp
Tanggal: ${DateFormat('dd MMMM yyyy').format(tanggal)}
Waktu: ${waktu.format(context)}
Keperluan: ${keterangan.isEmpty ? '-' : keterangan}

Terima kasih.
    ''';

    final String whatsappUrl =
        "https://wa.me/$nomorPemilik?text=${Uri.encodeComponent(pesan)}";
    final Uri url = Uri.parse(whatsappUrl);

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error membuka WhatsApp: $e')));
      }
    }
  }

  // Fungsi untuk menelepon
  Future<void> _telepon(String nomor) async {
    final Uri url = Uri.parse('tel:$nomor');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error membuka telepon: $e')));
      }
    }
  }

  // Fungsi untuk membuka WhatsApp
  Future<void> _bukaWhatsApp(String nomor) async {
    final Uri url = Uri.parse('https://wa.me/$nomor');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error membuka WhatsApp: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kunjungan'),
        backgroundColor: Colors.cyan[400],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Informasi Lokasi
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.cyan[400],
                            size: 32,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Lokasi Kandang',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(lokasiKandang, style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _bukaGoogleMaps,
                          icon: const Icon(Icons.map),
                          label: const Text('Buka di Google Maps'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyan[400],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Card Penjadwalan
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.event, color: Colors.cyan[400], size: 32),
                          const SizedBox(width: 8),
                          const Text(
                            'Jadwalkan Kunjungan',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Atur jadwal kunjungan Anda untuk melihat kambing atau bertemu dengan pemilik kandang.',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _bukaDialogJadwal,
                          icon: const Icon(Icons.calendar_today),
                          label: const Text('Buat Jadwal Kunjungan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Card Informasi Jam Operasional
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: Colors.cyan[400],
                            size: 32,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Jam Operasional',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildJamOperasional(
                        'Senin - Jumat',
                        '08.00 - 17.00 WIB',
                      ),
                      _buildJamOperasional('Sabtu', '08.00 - 15.00 WIB'),
                      _buildJamOperasional('Minggu', 'Tutup'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Card Kontak
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.contact_phone,
                            color: Colors.cyan[400],
                            size: 32,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Hubungi Kami',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.phone, color: Colors.green),
                        title: const Text('Telepon'),
                        subtitle: const Text('+62 812-3456-7890'),
                        onTap: () => _telepon('+6281234567890'),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.chat, color: Colors.green),
                        title: const Text('WhatsApp'),
                        subtitle: const Text('+62 812-3456-7890'),
                        onTap: () => _bukaWhatsApp('6281234567890'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJamOperasional(String hari, String jam) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(hari, style: const TextStyle(fontSize: 16)),
          Text(
            jam,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: jam == 'Tutup' ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}
