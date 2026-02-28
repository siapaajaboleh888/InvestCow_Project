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
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch ALL transactions from backend
      final allTrx = await _trxService.listAll(limit: 200);
      
      final List<Map<String, dynamic>> investment = [];
      final List<Map<String, dynamic>> wallet = [];

      for (var t in allTrx) {
        final type = t['type'].toString().toUpperCase();
        if (type == 'BUY' || type == 'SELL') {
          investment.add(t);
        } else if (type == 'TOPUP' || type == 'WITHDRAW' || t['symbol'] == 'CASH') {
          wallet.add(t);
        } else {
          // Fallback
          investment.add(t);
        }
      }

      if (mounted) {
        setState(() {
          _investmentTrx = investment;
          _walletTrx = wallet;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat data: ${e.toString()}';
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAllData,
          )
        ],
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
        : _error != null
          ? _buildErrorPlaceholder()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildInvestmentList(),
                _buildWalletList(),
              ],
            ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _fetchAllData, child: const Text('Coba Lagi')),
          ],
        ),
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
        final type = trx['type'].toString().toLowerCase();
        
        final isBuy = type == 'buy';
        final isSell = type == 'sell';

        String title = '';
        bool isIncome = false;
        IconData icon = Icons.help_outline;
        double amount = 0;
        String label = '';

        if (isBuy) {
          title = 'Beli ${trx['symbol']}';
          isIncome = false;
          icon = Icons.add_business;
          amount = _toDouble(trx['amount']);
          if (amount == 0) amount = _toDouble(trx['quantity']) * _toDouble(trx['price']);
          label = '${_toDouble(trx['quantity']).toStringAsFixed(2)} Ekor';
        } else if (isSell) {
          title = 'Jual ${trx['symbol']}';
          isIncome = true;
          icon = Icons.sell;
          amount = _toDouble(trx['amount']);
          if (amount == 0) amount = _toDouble(trx['quantity']) * _toDouble(trx['price']);
          label = '${_toDouble(trx['quantity']).toStringAsFixed(2)} Ekor';
        } else {
          title = '${trx['type']} ${trx['symbol']}';
          isIncome = trx['type'].toString().contains('UP') || trx['type'].toString().contains('TOP');
          amount = _toDouble(trx['amount']);
          label = trx['symbol'] == 'CASH' ? 'Tunai' : '${_toDouble(trx['quantity']).toStringAsFixed(2)} Ekor';
        }
        
        return _buildTransactionCard(
          title: title,
          subtitle: _formatDateTime(trx['occurred_at']),
          amount: amount,
          isIncome: isIncome,
          icon: icon,
          label: label,
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
        final type = t['type'].toString().toUpperCase();
        final isIncome = type == 'TOPUP';
        
        return _buildTransactionCard(
          title: type == 'TOPUP' ? 'Top Up Saldo' : (type == 'WITHDRAW' ? 'Tarik Saldo' : type),
          subtitle: _formatDateTime(t['occurred_at']),
          amount: _toDouble(t['amount']),
          isIncome: isIncome,
          icon: isIncome ? Icons.account_balance : Icons.payment,
          label: t['note'] ?? 'Sistem',
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
      elevation: 0.5,
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

  String _formatDateTime(dynamic occurredAt) {
    if (occurredAt == null) return '-';
    try {
      final DateTime dt = occurredAt is DateTime 
          ? occurredAt 
          : DateTime.parse(occurredAt.toString());
      return DateFormat('dd MMM yyyy, HH:mm').format(dt);
    } catch (e) {
      return occurredAt.toString();
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
                        await authService.topUp(amt, method: selectedMethod);
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
