import 'package:flutter/material.dart';
import 'package:investcow_app/services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/transactions_service.dart';

class TransaksiPage extends StatefulWidget {
  const TransaksiPage({super.key});

  @override
  State<TransaksiPage> createState() => _TransaksiPageState();
}

class _TransaksiPageState extends State<TransaksiPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _trxService = TransactionsService();
  
  // Data State
  List<Map<String, dynamic>> _investmentTrx = [];
  List<Map<String, dynamic>> _walletTrx = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch Investment History (Backend)
      final invRes = await _trxService.listAll();
      
      // 2. Fetch Wallet History (Local Storage from PembayaranPage)
      final prefs = await SharedPreferences.getInstance();
      final rawWallet = prefs.getString('kas_riwayat');
      List<Map<String, dynamic>> localWallet = [];
      if (rawWallet != null && rawWallet.isNotEmpty) {
        localWallet = (jsonDecode(rawWallet) as List).cast<Map<String, dynamic>>();
      }

      if (mounted) {
        setState(() {
          _investmentTrx = invRes;
          _walletTrx = localWallet;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F9),
      appBar: AppBar(
        title: const Text('Semua Transaksi'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Aset Sapi', icon: Icon(Icons.pets_outlined)),
            Tab(text: 'Dompet / Kas', icon: Icon(Icons.account_balance_wallet_outlined)),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildInvestmentList(),
              _buildWalletList(),
            ],
          ),
    );
  }

  Widget _buildInvestmentList() {
    if (_investmentTrx.isEmpty) {
      return const Center(child: Text('Belum ada transaksi aset sapi'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _investmentTrx.length,
      itemBuilder: (context, index) {
        final trx = _investmentTrx[index];
        final isBuy = trx['type'] == 'buy';
        final amount = _toDouble(trx['quantity']) * _toDouble(trx['price']);
        
        return _buildTransactionCard(
          title: '${isBuy ? 'Beli' : 'Jual'} ${trx['symbol']}',
          subtitle: _formatDateTime(trx['occurred_at']),
          amount: amount,
          isIncome: !isBuy,
          icon: isBuy ? Icons.add_business : Icons.sell,
          label: '${_toDouble(trx['quantity']).toStringAsFixed(2)} Ekor',
        );
      },
    );
  }

  Widget _buildWalletList() {
    if (_walletTrx.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Belum ada transaksi di dompet', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showTopUpDialog,
              icon: const Icon(Icons.add),
              label: const Text('Top Up Sekarang'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[700], foregroundColor: Colors.white),
            )
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _walletTrx.length,
      itemBuilder: (context, index) {
        final t = _walletTrx[index];
        final isIncome = t['jenis'] == 'Top Up';
        final date = t['tanggal'] is String ? DateTime.parse(t['tanggal']) : t['tanggal'];
        
        return _buildTransactionCard(
          title: t['jenis'] as String,
          subtitle: DateFormat('dd MMM yyyy, HH:mm').format(date),
          amount: _toDouble(t['nominal']),
          isIncome: isIncome,
          icon: isIncome ? Icons.account_balance : Icons.payment,
          label: t['metode'] ?? 'Sistem',
        );
      },
    );
  }

  Widget _buildTransactionCard({
    required String title,
    required String subtitle,
    required double amount,
    required bool isIncome,
    required IconData icon,
    required String label,
  }) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isIncome ? Colors.green[50] : Colors.red[50],
          child: Icon(icon, color: isIncome ? Colors.green : Colors.red, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isIncome ? '+' : '-'} ${_formatCurrency(amount)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isIncome ? Colors.green[700] : Colors.red[700],
              ),
            ),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double val) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(val);
  }

  String _formatDateTime(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy, HH:mm').format(dt);
    } catch (e) {
      return dateStr;
    }
  }

  void _showTopUpDialog() {
    final TextEditingController topUpCtrl = TextEditingController(text: '0');
    final authService = AuthService();
    String selectedMethod = 'BCA';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E222D),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.cyan.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.account_balance_wallet, color: Colors.cyan, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Text('Top Up Saldo', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 24),
                
                const Text('Masukkan Nominal', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 12),
                TextField(
                  controller: topUpCtrl,
                  keyboardType: TextInputType.number,
                  // Reusing CurrencyInputFormatter is not easy as it's defined in pasar_modal_page, 
                  // but we can just handle raw digits for now or define a simple one.
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    prefixText: 'Rp ',
                    prefixStyle: const TextStyle(color: Colors.grey, fontSize: 20),
                    enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white10), borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.cyan), borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.black26,
                  ),
                ),
                const SizedBox(height: 16),
                
                const Text('Nominal Cepat', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [50000, 100000, 200000, 500000, 1000000].map((amt) {
                    final formattedAmt = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(amt).trim();
                    return InkWell(
                      onTap: () => setModalState(() => topUpCtrl.text = formattedAmt),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: topUpCtrl.text == formattedAmt ? Colors.cyan.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                          border: Border.all(color: topUpCtrl.text == formattedAmt ? Colors.cyan : Colors.white10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_formatCurrency(amt.toDouble()), style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                
                const Text('Pilih Metode Pembayaran', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.2,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildPaymentItem('BCA', 'B', Colors.blue, selectedMethod, (val) => setModalState(() => selectedMethod = val)),
                    _buildPaymentItem('Mandiri', 'M', Colors.orange, selectedMethod, (val) => setModalState(() => selectedMethod = val)),
                    _buildPaymentItem('BNI', 'B', Colors.deepOrange, selectedMethod, (val) => setModalState(() => selectedMethod = val)),
                    _buildPaymentItem('Dana', 'D', Colors.blueAccent, selectedMethod, (val) => setModalState(() => selectedMethod = val)),
                    _buildPaymentItem('OVO', 'O', Colors.purple, selectedMethod, (val) => setModalState(() => selectedMethod = val)),
                    _buildPaymentItem('GoPay', 'G', Colors.green, selectedMethod, (val) => setModalState(() => selectedMethod = val)),
                  ],
                ),
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        final amtStr = topUpCtrl.text.replaceAll('.', '').replaceAll(',', '');
                        final amt = double.tryParse(amtStr) ?? 0;
                        if (amt <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Masukkan nominal yang valid')));
                          return;
                        }
                        await authService.topUp(amt);
                        if (!mounted) return;
                        Navigator.pop(context);
                        _fetchAllData();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Top Up ${_formatCurrency(amt)} via $selectedMethod Berhasil!'),
                          backgroundColor: Colors.green,
                        ));
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('Top Up Sekarang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentItem(String name, String initial, Color color, String current, Function(String) onSelect) {
    bool isSelected = current == name;
    return InkWell(
      onTap: () => onSelect(name),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.white.withOpacity(0.05),
          border: Border.all(color: isSelected ? color : Colors.white10, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
              child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 4),
            Text(name, style: TextStyle(color: isSelected ? Colors.white : Colors.white60, fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}
