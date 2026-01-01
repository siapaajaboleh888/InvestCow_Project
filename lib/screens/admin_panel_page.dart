import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/api_client.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Produk'),
            Tab(text: 'User'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const _AdminProductsTab(),
          const _AdminUsersTab(),
        ],
      ),
    );
  }
}

class _AdminProductsTab extends StatefulWidget {
  const _AdminProductsTab({super.key});

  @override
  State<_AdminProductsTab> createState() => _AdminProductsTabState();
}

class _AdminProductsTabState extends State<_AdminProductsTab> {
  final _authService = AuthService();
  final _client = ApiClient();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await _authService.getToken();
      final uri = _client.uri('/admin/products');
      final res = await http.get(uri, headers: _client.jsonHeaders(token: token));
      if (res.statusCode != 200) {
        throw Exception('Gagal memuat produk (${res.statusCode})');
      }
      final data = jsonDecode(res.body) as List;
      setState(() {
        _products = data.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  String _formatCurrencyPrice(dynamic value) {
    if (value == null) return 'Rp 0';
    final n = double.tryParse(value.toString()) ?? 0.0;
    return 'Rp ${n.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  Future<String?> _uploadImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result == null || result.files.single.bytes == null) {
        return null;
      }

      final file = result.files.single;
      final token = await _authService.getToken();
      final uri = _client.uri('/admin/upload-image');

      final request = http.MultipartRequest('POST', uri);
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.files.add(http.MultipartFile.fromBytes(
        'image',
        file.bytes!,
        filename: file.name,
      ));

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode != 200) {
        throw Exception('Upload gagal (${response.statusCode})');
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['url']?.toString();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal upload gambar: $e')),
        );
      }
      return null;
    }
  }

  Future<void> _openProductDialog({Map<String, dynamic>? existing}) async {
    final formKey = GlobalKey<FormState>();
    final nameController =
        TextEditingController(text: existing != null ? existing['name']?.toString() : '');
    final tickerController =
        TextEditingController(text: existing != null ? existing['ticker_code']?.toString() : '');
    final descController = TextEditingController(
        text: existing != null ? existing['description']?.toString() : '');
    final priceController = TextEditingController(
        text: existing != null ? existing['price']?.toString() : '');
    final targetPriceController = TextEditingController(
        text: existing != null ? existing['target_price']?.toString() : '');
    final quotaController = TextEditingController(
        text: existing != null ? existing['quota']?.toString() : '');
    String? imageUrl = existing != null ? existing['image_url']?.toString() : null;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Text(existing == null ? 'Tambah Produk' : 'Edit Produk'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nama Produk'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Nama tidak boleh kosong' : null,
                  ),
                  TextFormField(
                    controller: tickerController,
                    decoration: const InputDecoration(labelText: 'Kode Saham (Ticker)'),
                    maxLength: 5,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Kode tidak boleh kosong' : null,
                  ),
                  TextFormField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Deskripsi'),
                    maxLines: 2,
                  ),
                  TextFormField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: 'Harga Saat Ini (Rp)',
                      helperText: 'Harga awal atau harga paksa saat ini',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Harga tidak boleh kosong' : null,
                  ),
                  TextFormField(
                    controller: targetPriceController,
                    decoration: const InputDecoration(
                      labelText: 'Target Harga (Rp)',
                      helperText: 'Sistem akan menggerakkan harga ke target ini',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  TextFormField(
                    controller: quotaController,
                    decoration: const InputDecoration(labelText: 'Kuota / Stok'),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Kuota tidak boleh kosong' : null,
                  ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              imageUrl != null
                                  ? 'Gambar terpilih'
                                  : 'Belum ada gambar',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              final url = await _uploadImage();
                              if (url != null) {
                                setStateDialog(() {
                                  imageUrl = url;
                                });
                              }
                            },
                            icon: const Icon(Icons.image_outlined),
                            label: const Text('Pilih Gambar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  final token = await _authService.getToken();
                  final body = {
                    'name': nameController.text.trim(),
                    'ticker_code': tickerController.text.trim().toUpperCase(),
                    'description': descController.text.trim().isEmpty
                        ? null
                        : descController.text.trim(),
                    'price': double.tryParse(priceController.text.trim()) ?? 0,
                    'target_price': targetPriceController.text.trim().isEmpty
                        ? null
                        : double.tryParse(targetPriceController.text.trim()),
                    'quota': int.tryParse(quotaController.text.trim()) ?? 0,
                    'image_url': imageUrl,
                  };


                  http.Response res;
                  if (existing == null) {
                    final uri = _client.uri('/admin/products');
                    res = await http.post(
                      uri,
                      headers: _client.jsonHeaders(token: token),
                      body: jsonEncode(body),
                    );
                  } else {
                    final id = existing['id'];
                    final uri = _client.uri('/admin/products/$id');
                    res = await http.put(
                      uri,
                      headers: _client.jsonHeaders(token: token),
                      body: jsonEncode(body),
                    );
                  }

                  if (res.statusCode != 200 && res.statusCode != 201) {
                    throw Exception('Gagal menyimpan produk (${res.statusCode})');
                  }

                  if (mounted) {
                    Navigator.pop(context);
                    await _loadProducts();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(existing == null
                            ? 'Produk berhasil ditambahkan'
                            : 'Produk berhasil diperbarui'),
                      ),
                    );
                  }
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menyimpan produk: $e')),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
          },
        );
      },
    );
  }

  Future<void> _deleteProduct(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Produk'),
          content: const Text('Yakin ingin menghapus produk ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final token = await _authService.getToken();
      final uri = _client.uri('/admin/products/$id');
      final res = await http.delete(uri, headers: _client.jsonHeaders(token: token));
      if (res.statusCode != 204) {
        throw Exception('Gagal menghapus produk (${res.statusCode})');
      }
      await _loadProducts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produk berhasil dihapus')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus produk: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadProducts,
        child: _products.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 80),
                  Center(
                      child: Text(
                          'Belum ada produk. Admin dapat menambah produk sapi dengan tombol + di bawah.')),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _products.length,
                itemBuilder: (context, index) {
                  final p = _products[index];
                  final name = p['name']?.toString() ?? 'Produk';
                  final price = p['price'];
                  final quota = p['quota'];
                  final imageUrl = p['image_url']?.toString();
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: imageUrl != null && imageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                imageUrl,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.storefront),
                              ),
                            )
                          : const Icon(Icons.storefront),
                      title: Text(name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Harga: ${_formatCurrencyPrice(price)}'),
                          if (p['target_price'] != null)
                             Text('Target: ${_formatCurrencyPrice(p['target_price'])}', style: const TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold)),
                          Text('Kuota: $quota'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.orange),
                            onPressed: () => _openProductDialog(existing: p),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteProduct(p['id'] as int),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openProductDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Produk'),
      ),
    );
  }
}

class _AdminUsersTab extends StatefulWidget {
  const _AdminUsersTab({super.key});

  @override
  State<_AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<_AdminUsersTab> {
  final _authService = AuthService();
  final _client = ApiClient();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await _authService.getToken();
      final uri = _client.uri('/admin/users');
      final res = await http.get(uri, headers: _client.jsonHeaders(token: token));
      if (res.statusCode != 200) {
        throw Exception('Gagal memuat user (${res.statusCode})');
      }
      final data = jsonDecode(res.body) as List;
      setState(() {
        _users = data.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _deleteUser(int id, String email) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus User'),
          content: Text('Yakin ingin menghapus user "$email"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final token = await _authService.getToken();
      final uri = _client.uri('/admin/users/$id');
      final res = await http.delete(uri, headers: _client.jsonHeaders(token: token));
      if (res.statusCode != 204) {
        throw Exception('Gagal menghapus user (${res.statusCode})');
      }
      await _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User $email berhasil dihapus')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus user: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }
    if (_users.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 80),
          Center(
            child: Text(
              'Belum ada user terdaftar selain admin.',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final u = _users[index];
          final id = u['id'] as int;
          final email = u['email']?.toString() ?? '-';
          final role = u['role']?.toString() ?? '-';
          final createdAt = u['created_at']?.toString() ?? '';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: role == 'admin' ? Colors.orange[100] : Colors.blue[100],
                child: Icon(
                  role == 'admin' ? Icons.admin_panel_settings : Icons.person,
                  color: role == 'admin' ? Colors.orange[700] : Colors.blue[700],
                ),
              ),
              title: Text(email),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Role: $role'),
                  if (createdAt.isNotEmpty)
                    Text(
                      'Dibuat: $createdAt',
                      style: const TextStyle(fontSize: 12),
                    ),
                ],
              ),
              trailing: role == 'admin'
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteUser(id, email),
                    ),
            ),
          );
        },
      ),
    );
  }
}
