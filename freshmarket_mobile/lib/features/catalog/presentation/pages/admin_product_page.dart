import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/service/database_helper.dart';
import '../../../auth/presentation/pages/login_page.dart';

class AdminProductPage extends StatefulWidget {
  const AdminProductPage({super.key});

  @override
  State<AdminProductPage> createState() => _AdminProductPageState();
}

class _AdminProductPageState extends State<AdminProductPage> {
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _vouchers = [];
  List<Map<String, dynamic>> _cashiers = [];
  bool _isLoading = true;
  String _adminEmail = 'admin@gmail.com';
  String _currentView = 'products'; // 'products', 'vouchers', atau 'cashiers'

  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _imageController = TextEditingController();

  final _codeController = TextEditingController();
  final _discountController = TextEditingController();

  final _cashierEmailController = TextEditingController();
  final _cashierPasswordController = TextEditingController();



  @override
  void initState() {
    super.initState();
    _refreshData();
    _loadAdminSession();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _imageController.dispose();
    _codeController.dispose();
    _discountController.dispose();
    _cashierEmailController.dispose();
    _cashierPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadAdminSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _adminEmail = prefs.getString('email') ?? 'admin@gmail.com';
      });
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    final db = await DatabaseHelper.instance.database;
    final productData = await db.query('products', orderBy: 'id DESC');
    final voucherData = await db.query('vouchers', orderBy: 'id DESC');
    final cashierData = await db.query('users', where: 'role = ?', whereArgs: ['kasir'], orderBy: 'id DESC');
    
    if (mounted) {
      setState(() {
        _products = productData;
        _vouchers = voucherData;
        _cashiers = cashierData;
        _isLoading = false;
      });
    }
  }

  Future<void> _addProduct(String type, String unit) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('products', {
      'name': _nameController.text.trim(),
      'price': int.parse(_priceController.text.trim()),
      'stock': int.parse(_stockController.text.trim()),
      'image': _imageController.text.trim().isNotEmpty
          ? _imageController.text.trim()
          : 'https://placehold.co/400x400.png?text=No+Image',
      'type': type,
      'unit': unit,
    });
    _nameController.clear();
    _priceController.clear();
    _stockController.clear();
    _imageController.clear();
    _refreshData();
  }

  Future<void> _updateProduct(int id, String type, String unit) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('products', {
      'name': _nameController.text.trim(),
      'price': int.parse(_priceController.text.trim()),
      'stock': int.parse(_stockController.text.trim()),
      'image': _imageController.text.trim().isNotEmpty
          ? _imageController.text.trim()
          : 'https://placehold.co/400x400.png?text=No+Image',
      'type': type,
      'unit': unit,
    }, where: 'id = ?', whereArgs: [id]);
    _nameController.clear();
    _priceController.clear();
    _stockController.clear();
    _imageController.clear();
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
      'code': _codeController.text.trim().toUpperCase(),
      'discount': int.parse(_discountController.text.trim()),
    });
    _codeController.clear();
    _discountController.clear();
    _refreshData();
  }

  Future<void> _updateVoucher(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('vouchers', {
      'code': _codeController.text.trim().toUpperCase(),
      'discount': int.parse(_discountController.text.trim()),
    }, where: 'id = ?', whereArgs: [id]);
    _codeController.clear();
    _discountController.clear();
    _refreshData();
  }

  Future<void> _deleteVoucher(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('vouchers', where: 'id = ?', whereArgs: [id]);
    _refreshData();
  }

  Future<void> _addCashier() async {
    final db = await DatabaseHelper.instance.database;
    final email = _cashierEmailController.text.trim();
    final password = _cashierPasswordController.text;

    final checkEmail = await db.query('users', where: 'email = ?', whereArgs: [email]);
    if (checkEmail.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Email sudah terdaftar.', style: GoogleFonts.poppins()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    await db.insert('users', {
      'email': email,
      'password': password,
      'role': 'kasir',
    });

    _cashierEmailController.clear();
    _cashierPasswordController.clear();
    _refreshData();
  }

  Future<void> _updateCashier(int id) async {
    final db = await DatabaseHelper.instance.database;
    final email = _cashierEmailController.text.trim();
    final password = _cashierPasswordController.text;

    await db.update('users', {
      'email': email,
      'password': password,
    }, where: 'id = ?', whereArgs: [id]);

    _cashierEmailController.clear();
    _cashierPasswordController.clear();
    _refreshData();
  }

  Future<void> _deleteCashier(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
    _refreshData();
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  void _showProductForm({Map<String, dynamic>? product}) {
    final isEditing = product != null;
    if (isEditing) {
      _nameController.text = product['name'];
      _priceController.text = product['price'].toString();
      _stockController.text = product['stock'].toString();
      _imageController.text = product['image'];
    } else {
      _nameController.clear();
      _priceController.clear();
      _stockController.clear();
      _imageController.clear();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        String selectedType = isEditing ? (product['type'] ?? 'Lokal') : 'Lokal';
        String selectedUnit = isEditing ? (product['unit'] ?? 'kg') : 'kg';
        final productFormKey = GlobalKey<FormState>();
        
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          title: Text(
            isEditing ? 'EDIT PRODUK' : 'TAMBAH PRODUK',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 0.5,
              color: const Color(0xFF0F172A),
            ),
          ),
          content: Form(
            key: productFormKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nama Barang',
                      hintText: 'Masukkan nama barang',
                      prefixIcon: const Icon(Icons.shopping_bag_outlined, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nama barang tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Harga (Rp)',
                      hintText: 'Contoh: 15000',
                      prefixIcon: const Icon(Icons.attach_money_rounded, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Harga tidak boleh kosong';
                      }
                      final price = int.tryParse(value.trim());
                      if (price == null || price <= 0) {
                        return 'Harga harus berupa angka positif';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _stockController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Stok',
                      hintText: 'Contoh: 100',
                      prefixIcon: const Icon(Icons.inventory_2_outlined, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Stok tidak boleh kosong';
                      }
                      final stock = int.tryParse(value.trim());
                      if (stock == null || stock < 0) {
                        return 'Stok tidak boleh kurang dari 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _imageController,
                    decoration: InputDecoration(
                      labelText: 'Link Gambar (URL)',
                      hintText: 'https://...',
                      prefixIcon: const Icon(Icons.image_outlined, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    validator: (value) {
                      if (value != null && value.trim().isNotEmpty) {
                        if (!value.trim().startsWith('http://') && !value.trim().startsWith('https://')) {
                          return 'Link harus diawali dengan http:// atau https://';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    decoration: InputDecoration(
                      labelText: 'Tipe Buah',
                      prefixIcon: const Icon(Icons.category_outlined, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Lokal', child: Text('Buah Lokal')),
                      DropdownMenuItem(value: 'Impor', child: Text('Buah Impor')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setStateDialog(() {
                          selectedType = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedUnit,
                    decoration: InputDecoration(
                      labelText: 'Tipe Penjualan (Satuan)',
                      prefixIcon: const Icon(Icons.scale_outlined, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'kg', child: Text('Per Kg')),
                      DropdownMenuItem(value: 'buah', child: Text('Per Buah / Biji')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setStateDialog(() {
                          selectedUnit = value;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'BATAL',
                style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () {
                if (productFormKey.currentState!.validate()) {
                  if (isEditing) {
                    _updateProduct(product['id'], selectedType, selectedUnit);
                  } else {
                    _addProduct(selectedType, selectedUnit);
                  }
                  Navigator.pop(context);
                }
              },
              child: Text(
                'SIMPAN',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
          },
        );
      },
    );
  }

  void _showVoucherForm({Map<String, dynamic>? voucher}) {
    final isEditing = voucher != null;
    if (isEditing) {
      _codeController.text = voucher['code'];
      _discountController.text = voucher['discount'].toString();
    } else {
      _codeController.clear();
      _discountController.clear();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final voucherFormKey = GlobalKey<FormState>();
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          title: Text(
            isEditing ? 'EDIT VOUCHER' : 'TAMBAH VOUCHER',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 0.5,
              color: const Color(0xFF0F172A),
            ),
          ),
          content: Form(
            key: voucherFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Kode Voucher',
                    hintText: 'Contoh: DISKON10',
                    prefixIcon: const Icon(Icons.local_offer_outlined, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Kode voucher tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _discountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Nominal Potongan (Rp)',
                    hintText: 'Contoh: 10000',
                    prefixIcon: const Icon(Icons.attach_money_rounded, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Potongan tidak boleh kosong';
                    }
                    final discount = int.tryParse(value.trim());
                    if (discount == null || discount <= 0) {
                      return 'Potongan harus berupa angka positif';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'BATAL',
                style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () {
                if (voucherFormKey.currentState!.validate()) {
                  if (isEditing) {
                    _updateVoucher(voucher['id']);
                  } else {
                    _addVoucher();
                  }
                  Navigator.pop(context);
                }
              },
              child: Text(
                'SIMPAN',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCashierForm({Map<String, dynamic>? cashier}) {
    final isEditing = cashier != null;
    if (isEditing) {
      _cashierEmailController.text = cashier['email'];
      _cashierPasswordController.text = cashier['password'];
    } else {
      _cashierEmailController.clear();
      _cashierPasswordController.clear();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final cashierFormKey = GlobalKey<FormState>();
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          title: Text(
            isEditing ? 'EDIT AKUN KASIR' : 'TAMBAH AKUN KASIR',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 0.5,
              color: const Color(0xFF0F172A),
            ),
          ),
          content: Form(
            key: cashierFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _cashierEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email Kasir',
                    hintText: 'Contoh: kasir2@gmail.com',
                    prefixIcon: const Icon(Icons.email_outlined, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email tidak boleh kosong';
                    }
                    if (!value.contains('@')) {
                      return 'Email tidak valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cashierPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Masukkan password',
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Password tidak boleh kosong';
                    }
                    if (value.length < 4) {
                      return 'Password minimal 4 karakter';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'BATAL',
                style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () {
                if (cashierFormKey.currentState!.validate()) {
                  if (isEditing) {
                    _updateCashier(cashier['id']);
                  } else {
                    _addCashier();
                  }
                  Navigator.pop(context);
                }
              },
              child: Text(
                'SIMPAN',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteProductConfirmation(int id, String name) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          title: Text(
            'HAPUS PRODUK',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.redAccent),
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus produk "$name"?',
            style: GoogleFonts.poppins(color: const Color(0xFF334155)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('BATAL', style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              onPressed: () {
                _deleteProduct(id);
                Navigator.pop(context);
              },
              child: Text('HAPUS', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteVoucherConfirmation(int id, String code) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          title: Text(
            'HAPUS VOUCHER',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.redAccent),
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus voucher "$code"?',
            style: GoogleFonts.poppins(color: const Color(0xFF334155)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('BATAL', style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              onPressed: () {
                _deleteVoucher(id);
                Navigator.pop(context);
              },
              child: Text('HAPUS', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteCashierConfirmation(int id, String email) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          title: Text(
            'HAPUS AKUN KASIR',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.redAccent),
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus akun kasir "$email"?',
            style: GoogleFonts.poppins(color: const Color(0xFF334155)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('BATAL', style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              onPressed: () {
                _deleteCashier(id);
                Navigator.pop(context);
              },
              child: Text('HAPUS', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }



  Widget _buildProductsView() {
    if (_products.isEmpty) {
      return Center(
        child: Text(
          'Belum ada produk.',
          style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final item = _products[index];
        return Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    item['image'],
                    width: 76,
                    height: 76,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      width: 76,
                      height: 76,
                      color: const Color(0xFFF1F5F9),
                      child: const Icon(Icons.broken_image, color: Color(0xFF94A3B8)),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Rp ${item['price']} / ${item['unit'] ?? 'kg'}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tipe: ${item['type'] ?? 'Lokal'} • Stok: ${item['stock']} unit',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Color(0xFF3B82F6)),
                      onPressed: () => _showProductForm(product: item),
                      tooltip: 'Edit Produk',
                      splashRadius: 20,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () => _showDeleteProductConfirmation(item['id'], item['name']),
                      tooltip: 'Hapus Produk',
                      splashRadius: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVouchersView() {
    if (_vouchers.isEmpty) {
      return Center(
        child: Text(
          'Belum ada voucher.',
          style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      itemCount: _vouchers.length,
      itemBuilder: (context, index) {
        final item = _vouchers[index];
        return Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item['code'],
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 0.5,
                      color: const Color(0xFF334155),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nominal Potongan',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rp ${item['discount']}',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Color(0xFF3B82F6)),
                      onPressed: () => _showVoucherForm(voucher: item),
                      tooltip: 'Edit Voucher',
                      splashRadius: 20,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () => _showDeleteVoucherConfirmation(item['id'], item['code']),
                      tooltip: 'Hapus Voucher',
                      splashRadius: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCashiersView() {
    if (_cashiers.isEmpty) {
      return Center(
        child: Text(
          'Belum ada akun kasir.',
          style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      itemCount: _cashiers.length,
      itemBuilder: (context, index) {
        final item = _cashiers[index];
        return Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    shape: BoxShape.rectangle,
                  ),
                  child: const Icon(Icons.person_outline, color: Color(0xFF64748B), size: 24),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['email'],
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Password: ${item['password']}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Color(0xFF3B82F6)),
                      onPressed: () => _showCashierForm(cashier: item),
                      tooltip: 'Edit Kasir',
                      splashRadius: 20,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () => _showDeleteCashierConfirmation(item['id'], item['email']),
                      tooltip: 'Hapus Kasir',
                      splashRadius: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _currentView == 'products'
              ? 'KELOLA PRODUK'
              : _currentView == 'vouchers'
                  ? 'KELOLA VOUCHER'
                  : 'KELOLA KASIR',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            letterSpacing: 1.0,
            color: const Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      drawer: Drawer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
              ),
              currentAccountPicture: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF1E293B),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF10B981), size: 36),
              ),
              accountName: Text(
                'Administrator',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
              ),
              accountEmail: Text(
                _adminEmail,
                style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),

            ListTile(
              leading: Icon(
                Icons.inventory_2_outlined,
                color: _currentView == 'products' ? const Color(0xFF10B981) : const Color(0xFF64748B),
              ),
              title: Text(
                'Kelola Produk',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: _currentView == 'products' ? const Color(0xFF10B981) : const Color(0xFF334155),
                ),
              ),
              selected: _currentView == 'products',
              selectedTileColor: const Color(0xFFF1F5F9),
              onTap: () {
                setState(() {
                  _currentView = 'products';
                });
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
            ListTile(
              leading: Icon(
                Icons.local_offer_outlined,
                color: _currentView == 'vouchers' ? const Color(0xFF10B981) : const Color(0xFF64748B),
              ),
              title: Text(
                'Kelola Voucher',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: _currentView == 'vouchers' ? const Color(0xFF10B981) : const Color(0xFF334155),
                ),
              ),
              selected: _currentView == 'vouchers',
              selectedTileColor: const Color(0xFFF1F5F9),
              onTap: () {
                setState(() {
                  _currentView = 'vouchers';
                });
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
            ListTile(
              leading: Icon(
                Icons.people_alt_outlined,
                color: _currentView == 'cashiers' ? const Color(0xFF10B981) : const Color(0xFF64748B),
              ),
              title: Text(
                'Kelola Kasir',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: _currentView == 'cashiers' ? const Color(0xFF10B981) : const Color(0xFF334155),
                ),
              ),
              selected: _currentView == 'cashiers',
              selectedTileColor: const Color(0xFFF1F5F9),
              onTap: () {
                setState(() {
                  _currentView = 'cashiers';
                });
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
            const Divider(height: 24, thickness: 1, color: Color(0xFFE2E8F0)),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: Text(
                'Keluar',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.redAccent),
              ),
              onTap: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
                _logout();
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_currentView == 'products') {
            _showProductForm();
          } else if (_currentView == 'vouchers') {
            _showVoucherForm();
          } else {
            _showCashierForm();
          }
        },
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        icon: const Icon(Icons.add, size: 20),
        label: Text(
          _currentView == 'products'
              ? 'TAMBAH PRODUK'
              : _currentView == 'vouchers'
                  ? 'TAMBAH VOUCHER'
                  : 'TAMBAH KASIR',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, letterSpacing: 0.5, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_currentView == 'products') {
      return _buildProductsView();
    } else if (_currentView == 'vouchers') {
      return _buildVouchersView();
    } else {
      return _buildCashiersView();
    }
  }
}