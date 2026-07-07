import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/service/database_helper.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = true;
  String _userEmail = '';
  int _discount = 0;
  String _appliedVoucherCode = '';
  final _voucherController = TextEditingController();
  
  String _selectedPayment = 'Transfer Bank';
  final List<String> _paymentOptions = [
    'Transfer Bank',
    'Gopay / E-Wallet',
    'OVO / Dana',
    'COD (Bayar di Tempat)',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserSessionAndCart();
  }

  @override
  void dispose() {
    _voucherController.dispose();
    super.dispose();
  }

  Future<void> _loadUserSessionAndCart() async {
    final prefs = await SharedPreferences.getInstance();
    _userEmail = prefs.getString('email') ?? 'user@gmail.com';
    await _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() => _isLoading = true);
    try {
      final db = await DatabaseHelper.instance.database;
      // Join cart items with product details
      final data = await db.rawQuery('''
        SELECT cart.id as cart_id, cart.quantity, products.id as product_id, 
               products.name, products.price, products.stock, products.image 
        FROM cart 
        INNER JOIN products ON cart.product_id = products.id
      ''');
      setState(() {
        _cartItems = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateQuantity(int cartId, int newQty) async {
    if (newQty <= 0) {
      // Remove from cart
      await _deleteCartItem(cartId);
      return;
    }
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'cart',
      {'quantity': newQty},
      where: 'id = ?',
      whereArgs: [cartId],
    );
    await _loadCart();
  }

  Future<void> _deleteCartItem(int cartId) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'cart',
      where: 'id = ?',
      whereArgs: [cartId],
    );
    await _loadCart();
  }

  Future<void> _applyVoucher() async {
    final code = _voucherController.text.trim();
    if (code.isEmpty) return;

    final db = await DatabaseHelper.instance.database;
    final res = await db.query(
      'vouchers',
      where: 'code = ?',
      whereArgs: [code],
    );

    if (res.isNotEmpty) {
      final discVal = int.tryParse(res.first['discount'].toString()) ?? 0;
      setState(() {
        _discount = discVal;
        _appliedVoucherCode = code;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voucher "$code" berhasil digunakan! Potongan Rp $discVal'),
            backgroundColor: const Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kode voucher tidak valid!'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  int get _subtotal {
    int total = 0;
    for (var item in _cartItems) {
      final price = int.tryParse(item['price'].toString()) ?? 0;
      final qty = int.tryParse(item['quantity'].toString()) ?? 0;
      total += price * qty;
    }
    return total;
  }

  int get _finalTotal {
    final total = _subtotal - _discount;
    return total < 0 ? 0 : total;
  }

  void _processCheckout() {
    if (_cartItems.isEmpty) return;

    // Show simulated gateway processing popup
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Color(0xFF22C55E)),
                const SizedBox(height: 24),
                Text(
                  'Memproses Pembayaran...',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Menghubungkan ke gateway $_selectedPayment',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    // After 1.5 seconds delay, write to DB
    Future.delayed(const Duration(milliseconds: 1500), () async {
      try {
        final db = await DatabaseHelper.instance.database;

        // 1. Decrease Stock for products
        for (var item in _cartItems) {
          final prodId = item['product_id'] as int;
          final purchaseQty = item['quantity'] as int;
          final currentStock = item['stock'] as int;
          
          final newStock = currentStock - purchaseQty;
          await db.update(
            'products',
            {'stock': newStock < 0 ? 0 : newStock},
            where: 'id = ?',
            whereArgs: [prodId],
          );
        }

        // 2. Prepare items json representation
        final List<Map<String, dynamic>> itemsList = _cartItems.map((e) => {
          'product_id': e['product_id'],
          'name': e['name'],
          'price': e['price'],
          'quantity': e['quantity'],
          'image': e['image'],
        }).toList();
        final itemsJson = jsonEncode(itemsList);

        // 3. Insert into orders table
        await db.insert('orders', {
          'user_email': _userEmail,
          'total_price': _finalTotal,
          'payment_method': _selectedPayment,
          'status': 'Menunggu Respon',
          'date': DateTime.now().toIso8601String().split('T')[0],
          'items_json': itemsJson,
        });

        // 4. Insert into transactions table for Admin statistics
        await db.insert('transactions', {
          'total_price': _finalTotal,
          'discount': _discount,
          'date': DateTime.now().toIso8601String().split('T')[0],
        });

        // 5. Clear cart
        await db.delete('cart');

        if (!mounted) return;
        Navigator.pop(context); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pembayaran Berhasil! Pesanan dibuat via $_selectedPayment.'),
            backgroundColor: const Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Go back to Home Layout and switch to Orders tab
        Navigator.pop(context); // Close CartPage
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal melakukan checkout: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Keranjang Belanja',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 16,
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF22C55E)))
          : _cartItems.isEmpty
              ? _buildEmptyCart()
              : _buildCartContent(),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                size: 64,
                color: Color(0xFF22C55E),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Keranjang Belanja Kosong',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Masukkan buah segar atau sayuran ke keranjang untuk melakukan pembelian.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              height: 44,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  'Mulai Belanja',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCartContent() {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _cartItems.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = _cartItems[index];
              final cartId = item['cart_id'] as int;
              final qty = item['quantity'] as int;
              final price = item['price'] as int;
              final name = item['name'].toString();
              
              final imageUrl = (item['image'] != null && item['image'].toString().trim().isNotEmpty)
                  ? item['image'].toString().trim()
                  : 'https://placehold.co/400x400.png?text=No+Image';

              return Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrl,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(
                            width: 64,
                            height: 64,
                            color: const Color(0xFFF1F5F9),
                            child: const Icon(Icons.broken_image, color: Color(0xFF94A3B8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rp $price',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF22C55E),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF64748B), size: 20),
                            onPressed: () => _updateQuantity(cartId, qty - 1),
                          ),
                          Text(
                            qty.toString(),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF22C55E), size: 20),
                            onPressed: () => _updateQuantity(cartId, qty + 1),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        
        // Checkout & Voucher details panel at bottom
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Voucher Input Box
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _voucherController,
                          style: GoogleFonts.poppins(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Masukkan kode voucher (e.g. DISKON20)',
                            hintStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 11),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _applyVoucher,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: Text(
                          'Gunakan',
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Display Voucher details if applied
                if (_appliedVoucherCode.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Voucher "$_appliedVoucherCode" berhasil dipasang: -Rp $_discount',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF22C55E),
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                
                // Payment Method Selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Metode Pembayaran:',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    DropdownButton<String>(
                      value: _selectedPayment,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF0F172A),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      underline: Container(),
                      onChanged: (String? val) {
                        if (val != null) {
                          setState(() => _selectedPayment = val);
                        }
                      },
                      items: _paymentOptions.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const Divider(height: 24, thickness: 1, color: Color(0xFFF1F5F9)),

                // Total details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Pembayaran',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF64748B),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Rp $_finalTotal',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF22C55E),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: 160,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _processCheckout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF22C55E),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                          'Bayar Sekarang',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
