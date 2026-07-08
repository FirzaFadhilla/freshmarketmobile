import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/service/database_helper.dart';
import '../../../cart/presentation/pages/cart_page.dart';
import '../../../auth/presentation/pages/login_page.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  bool _isLoggedIn = false;

  final List<String> _categories = ['Semua', 'Buah Lokal', 'Buah Impor'];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadLoginSession();
  }

  Future<void> _loadLoginSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      });
    }
  }

  void _showLoginRequiredDialog(String action) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Perlu Masuk Akun',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Silakan masuk ke akun Anda terlebih dahulu untuk dapat $action.',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Batal',
                style: GoogleFonts.poppins(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                ).then((_) => _loadLoginSession()); // Refresh login session when coming back
              },
              child: Text(
                'Masuk',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF22C55E),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadProducts() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final data = await db.query('products', orderBy: 'id DESC');
      if (mounted) {
        setState(() {
          _allProducts = data;
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> temp = List.from(_allProducts);

    // Filter berdasarkan kategori (menggunakan kolom database 'type')
    if (_selectedCategory != 'Semua') {
      if (_selectedCategory == 'Buah Lokal') {
        temp = temp.where((p) => (p['type']?.toString().toLowerCase() ?? 'lokal') == 'lokal').toList();
      } else if (_selectedCategory == 'Buah Impor') {
        temp = temp.where((p) => (p['type']?.toString().toLowerCase() ?? 'lokal') == 'impor').toList();
      }
    }

    // Filter berdasarkan query pencarian
    if (_searchQuery.trim().isNotEmpty) {
      temp = temp.where((p) => p['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    setState(() {
      _filteredProducts = temp;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Katalog FreshMarket',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.normal,
            fontSize: 18,
            letterSpacing: 0.5,
            color: const Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF22C55E)),
            tooltip: 'Keranjang Belanja',
            onPressed: () {
              if (!_isLoggedIn) {
                _showLoginRequiredDialog('melihat keranjang belanja');
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartPage()),
                ).then((_) => _loadProducts());
              }
            },
          ),
        ],
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF22C55E)))
          : Column(
              children: [
                // Bagian Filter & Pencarian
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    children: [
                      // Search Bar & Filter Button
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextField(
                                onChanged: (val) {
                                  setState(() {
                                    _searchQuery = val;
                                    _applyFilters();
                                  });
                                },
                                decoration: InputDecoration(
                                  hintText: 'Cari buah segar, sayuran...',
                                  hintStyle: GoogleFonts.poppins(
                                    color: const Color(0xFF94A3B8),
                                    fontSize: 13,
                                  ),
                                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Horizontal Category Chips List
                      SizedBox(
                        height: 38,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final cat = _categories[index];
                            final isSelected = _selectedCategory == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedCategory = cat;
                                    _applyFilters();
                                  });
                                },
                                borderRadius: BorderRadius.circular(30),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF22C55E) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF22C55E) : const Color(0xFFE2E8F0),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    cat,
                                    style: GoogleFonts.poppins(
                                      color: isSelected ? Colors.white : const Color(0xFF475569),
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Main Product Catalog List
                Expanded(
                  child: _filteredProducts.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF1F5F9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF94A3B8)),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Produk Tidak Ditemukan',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF334155),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Coba cari dengan kata kunci lain atau pilih kategori yang berbeda.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.65, // Adjusted to fit details comfortably
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final item = _filteredProducts[index];
                            return _buildPremiumProductCard(item);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Future<void> _addToCart(int productId, String name) async {
    if (!_isLoggedIn) {
      _showLoginRequiredDialog('menambahkan produk ke keranjang');
      return;
    }
    try {
      final db = await DatabaseHelper.instance.database;
      final existing = await db.query(
        'cart',
        where: 'product_id = ?',
        whereArgs: [productId],
      );

      if (existing.isNotEmpty) {
        final currentQty = existing.first['quantity'] as int;
        await db.update(
          'cart',
          {'quantity': currentQty + 1},
          where: 'product_id = ?',
          whereArgs: [productId],
        );
      } else {
        await db.insert('cart', {
          'product_id': productId,
          'quantity': 1,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name dimasukkan ke keranjang!'),
            backgroundColor: const Color(0xFF22C55E),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambah ke keranjang: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildPremiumProductCard(Map<String, dynamic> item) {
    // Mock calculations to look premium
    final price = item['price'] as int;
    final name = item['name'];
    final mockRating = 4.7 + (price % 3) * 0.1; // stable rating like 4.7, 4.8, 4.9
    final mockReviews = 15 + (price % 40);
    final stock = item['stock'] ?? 0;
    final isLowStock = stock > 0 && stock <= 10;
    final isOutOfStock = stock == 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF1F5F9),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      item['image'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFFE8F5E9),
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image_rounded, color: Colors.grey, size: 36),
                      ),
                    ),
                  ),
                ),
                // Stock Warning Badge (Top Right)
                if (isOutOfStock)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF64748B),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'HABIS',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                else if (isLowStock)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'LIMIT',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Product Info Section
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Star Rating & Review count
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      mockRating.toStringAsFixed(1),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '($mockReviews)',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Product Name
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // Stock Text Info
                const SizedBox(height: 2),
                Text(
                  isOutOfStock
                      ? 'Stok kosong'
                      : isLowStock
                          ? 'Sisa $stock unit segera habis!'
                          : 'Stok tersedia',
                  style: GoogleFonts.poppins(
                    color: isOutOfStock
                        ? const Color(0xFFEF4444)
                        : isLowStock
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF22C55E),
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 10),
                // Pricing & Action Button Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Actual price
                          // Current Promo Price
                          Text(
                            'Rp $price / ${item['unit'] ?? 'kg'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF22C55E),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Action add Button
                    SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        onPressed: isOutOfStock
                            ? null
                            : () => _addToCart(item['id'], name),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF22C55E),
                          disabledBackgroundColor: const Color(0xFFE2E8F0),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          '+ Tambah',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
