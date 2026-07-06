import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Untuk Logout
import '../../../../core/service/database_helper.dart';
import '../../../main/presentation/pages/main_layout.dart';
import '../../../auth/presentation/pages/login_page.dart'; // Import Halaman Login

class AdminProductPage extends StatefulWidget {
  const AdminProductPage({super.key});

  @override
  State<AdminProductPage> createState() => _AdminProductPageState();
}

class _AdminProductPageState extends State<AdminProductPage> {
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _vouchers = [];
  bool _isLoading = true;

  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _imageController = TextEditingController(); // Controller Gambar Baru

  final _codeController = TextEditingController();
  final _discountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    final db = await DatabaseHelper.instance.database;
    final productData = await db.query('products', orderBy: 'id DESC');
    final voucherData = await db.query('vouchers', orderBy: 'id DESC');
    
    setState(() {
      _products = productData;
      _vouchers = voucherData;
      _isLoading = false;
    });
  }

  Future<void> _addProduct() async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('products', {
      'name': _nameController.text,
      'price': int.parse(_priceController.text),
      'stock': int.parse(_stockController.text),
      'image': _imageController.text.isNotEmpty ? _imageController.text : 'https://placehold.co/400x400.png?text=No+Image', // Default image jika kosong
    });
    _nameController.clear(); _priceController.clear(); _stockController.clear(); _imageController.clear();
    _refreshData();
  }

  Future<void> _deleteProduct(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
    _refreshData();
  }

  Future<void> _addVoucher() async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('vouchers', {
      'code': _codeController.text.toUpperCase(),
      'discount': int.parse(_discountController.text),
    });
    _codeController.clear(); _discountController.clear();
    _refreshData();
  }

  Future<void> _deleteVoucher(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('vouchers', where: 'id = ?', whereArgs: [id]);
    _refreshData();
  }

  // --- FUNGSI LOGOUT ---
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Hapus sesi
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  void _showProductForm() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tambah Produk'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _nameController, decoration: const InputDecoration(hintText: 'Nama Barang')),
              TextField(controller: _priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Harga (Rp)')),
              TextField(controller: _stockController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Stok')),
              TextField(controller: _imageController, decoration: const InputDecoration(hintText: 'Link Gambar (URL https://...)')), // Input URL
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (_nameController.text.isNotEmpty) {
                _addProduct();
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showVoucherForm() {
    // ... [Isi fungsi _showVoucherForm sama seperti sebelumnya]
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tambah Voucher'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _codeController, decoration: const InputDecoration(hintText: 'Kode Voucher (Contoh: DISKON10)')),
            TextField(controller: _discountController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Nominal Potongan (Rp)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (_codeController.text.isNotEmpty) {
                _addVoucher();
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Dashboard Admin', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF22C55E),
          foregroundColor: Colors.white,
          actions: [
            // TOMBOL LOGOUT
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Keluar',
              onPressed: _logout,
            )
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Produk'),
              Tab(icon: Icon(Icons.local_offer_outlined), text: 'Voucher'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _products.isEmpty
                      ? const Center(child: Text('Belum ada produk.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _products.length,
                          itemBuilder: (context, index) {
                            final item = _products[index];
                            return Card(
                              child: ListTile(
                                // Menampilkan Gambar Kecil di Samping Kiri
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    item['image'],
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => const Icon(Icons.broken_image),
                                  ),
                                ),
                                title: Text(item['name'], style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                                subtitle: Text('Harga: Rp ${item['price']} | Stok: ${item['stock']}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteProduct(item['id']),
                                ),
                              ),
                            );
                          },
                        ),
                  _vouchers.isEmpty
                      ? const Center(child: Text('Belum ada voucher.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _vouchers.length,
                          itemBuilder: (context, index) {
                            final item = _vouchers[index];
                            return Card(
                              child: ListTile(
                                title: Text(item['code'], style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.green)),
                                subtitle: Text('Potongan: Rp ${item['discount']}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteVoucher(item['id']),
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
        floatingActionButton: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'produk') _showProductForm();
            if (value == 'voucher') _showVoucherForm();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'produk', child: Text('Tambah Produk')),
            const PopupMenuItem(value: 'voucher', child: Text('Tambah Voucher')),
          ],
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle),
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}