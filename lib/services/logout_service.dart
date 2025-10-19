import 'package:flutter/material.dart';
import 'auth_service.dart';
import '../screens/login_page.dart'; // Nanti akan dibuat di Tahap 3

/// Service untuk handle proses logout
class LogoutService {
  final AuthService _authService = AuthService();

  /// Tampilkan dialog konfirmasi logout
  Future<void> showLogoutDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.exit_to_app, color: Colors.red[700]),
              const SizedBox(width: 8),
              const Text('Konfirmasi Keluar'),
            ],
          ),
          content: const Text(
            'Apakah Anda yakin ingin keluar dari aplikasi?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            // Tombol Batal
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Batal',
                style: TextStyle(color: Colors.grey[700], fontSize: 16),
              ),
            ),
            // Tombol Keluar
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Close dialog
                await _performLogout(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Keluar', style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  /// Proses logout sebenarnya
  Future<void> _performLogout(BuildContext context) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Simulasi delay (hapus di production jika tidak perlu)
      await Future.delayed(const Duration(milliseconds: 500));

      // Hapus semua data auth
      await _authService.logout();

      if (!context.mounted) return;

      // Close loading dialog
      Navigator.of(context).pop();

      // Navigate ke login page dan hapus semua route sebelumnya
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );

      // Show success message
      Future.delayed(const Duration(milliseconds: 300), () {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Anda telah keluar'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      });
    } catch (e) {
      if (!context.mounted) return;

      // Close loading dialog
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal keluar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Logout langsung tanpa konfirmasi (jika diperlukan)
  Future<void> logoutDirect(BuildContext context) async {
    await _performLogout(context);
  }
}
