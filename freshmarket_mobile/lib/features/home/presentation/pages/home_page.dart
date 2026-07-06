import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../auth/presentation/pages/login_page.dart';
// Tambahkan import database kita di sini
import '../../../../core/service/database_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final PageController _pageController;
  late final Timer _timer;
  int _currentPage = 0;

  // Variabel untuk menampung data produk dari SQLite
  List<Map<String, dynamic>> _products = [];
  bool _isLoadingProducts = true;

  final List<Map<String, String>> _bannerItems = [
    {
      'image': 'https://images.unsplash.com/photo-1550258987-190a2d41a8ba?q=80&w=600&auto=format&fit=crop',
      'title': 'Nanas Madu',
    },
    {
      'image': 'https://images.unsplash.com/photo-1611080626919-7cf5a9dbab5b?q=80&w=600&auto=format&fit=crop',
      'title': 'Jeruk Sunkist',
    },
    {
      'image': 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?q=80&w=600&auto=format&fit=crop',
      'title': 'Apel Merah',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts(); // Panggil data dari database saat halaman dibuka

    _pageController = PageController(initialPage: 0);
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        int nextPage = _currentPage + 1;
        if (nextPage >= _bannerItems.length) {
          nextPage = 0;
        }
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  // Fungsi untuk mengambil data barang yang diinput admin
  Future<void> _loadProducts() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final data = await db.query('products', orderBy: 'id DESC');
      if (mounted) {
        setState(() {
          _products = data;
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingProducts = false);
      }
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            // Sticky Navbar (Z-Index 999 style - stays fixed at the top)
            _buildStickyNavbar(),
            const Divider(color: Color(0xFFE5E7EB), height: 1, thickness: 1),
            
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. HERO SECTION & AUTO-SLIDING BANNER
                    _buildHeroSection(),
                    
                    const SizedBox(height: 36),

                    // ==========================================
                    // SEKSI BARU: KATALOG PRODUK DARI SQLITE
                    // ==========================================
                    _buildProductsSection(),
                    
                    const SizedBox(height: 36),
                    
                    // 2. SEKSI TUJUAN UTAMA KAMI (Wrapped in a Card, Title Centered)
                    _buildOurGoalCardSection(),
                    
                    const SizedBox(height: 36),
                    
                    // 3. SEKSI CARA BELANJA
                    _buildHowToShopSection(),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickyNavbar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Pojok Atas Kiri: Logo Fresh Market & Teman Sehatmu
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              RichText(
                text: TextSpan(
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                  children: const [
                    TextSpan(
                      text: 'Fresh ',
                      style: TextStyle(color: Color(0xFFFF6347)), // Tomato Red
                    ),
                    TextSpan(
                      text: 'Market',
                      style: TextStyle(color: Color(0xFF4ADE80)), // Light/medium green
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Teman Sehatmu',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          
          // Pojok Atas Kanan: Button Login (White 3D button, thick, with person/profile icon)
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFFD1D5DB), // 3D shadow color
                    offset: Offset(0, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.person_rounded,
                    color: Color(0xFF22C55E),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Masuk',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Headline Kiri Atas
        RichText(
          textAlign: TextAlign.left,
          text: TextSpan(
            style: GoogleFonts.poppins(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF111827),
              height: 1.25,
            ),
            children: const [
              TextSpan(text: 'Akses Mudah\n'),
              TextSpan(
                text: 'Buah Lokal\n',
                style: TextStyle(color: Color(0xFF22C55E)),
              ),
              TextSpan(text: 'Indonesia'),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Wadah Gambar Utama - Auto-sliding PageView
        Container(
          height: 340,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Banner PageView
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _bannerItems.length,
                  itemBuilder: (context, index) {
                    final item = _bannerItems[index];
                    return Stack(
                      children: [
                        Image.network(
                          item['image']!,
                          height: 340,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: const Color(0xFFE5E7EB),
                              alignment: Alignment.center,
                              child: const CircularProgressIndicator(
                                color: Color(0xFF22C55E),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: const Color(0xFFE5E7EB),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.broken_image_outlined,
                                size: 48,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                        // Dark overlay at the bottom for readability
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withValues(alpha: 0.45),
                                  Colors.transparent,
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                stops: const [0.0, 0.4],
                              ),
                            ),
                          ),
                        ),
                        // Teks melayang putih
                        Positioned(
                          left: 20,
                          bottom: 20,
                          child: Text(
                            item['title']!,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              shadows: [
                                Shadow(
                                  offset: const Offset(0, 2),
                                  blurRadius: 4,
                                  color: Colors.black.withValues(alpha: 0.3),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                // Slide dot indicators
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      _bannerItems.length,
                      (index) => Container(
                        margin: const EdgeInsets.only(left: 6),
                        width: _currentPage == index ? 16 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? const Color(0xFF22C55E)
                              : Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Tombol Utama (Belanja Sekarang)
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              elevation: 0,
              shape: const StadiumBorder(),
            ),
            child: Text(
              'Belanja Sekarang',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Tautan Navigasi "Cara Kerja" - White background, black border
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(color: Colors.black, width: 1.5),
              shape: const StadiumBorder(),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Cara Kerja',
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.black,
                  size: 12,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // =======================================================
  // WIDGET BARU: MENAMPILKAN PRODUK DARI SQLITE (ADMIN)
  // =======================================================
  Widget _buildProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111827),
              ),
              children: const [
                TextSpan(text: 'Produk '),
                TextSpan(
                  text: 'Terbaru',
                  style: TextStyle(color: Color(0xFF22C55E)),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        _isLoadingProducts
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF22C55E)),
              )
            : _products.isEmpty
                ? Center(
                    child: Text(
                      'Katalog masih kosong.\nTunggu admin menambahkan buah baru!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                        height: 1.4,
                      ),
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true, // Penting agar bisa di-scroll di dalam SingleChildScrollView
                    physics: const NeverScrollableScrollPhysics(), // Penting
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72, // Menyesuaikan tinggi kartu
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final item = _products[index];
                      return _buildProductCard(item);
                    },
                  ),
      ],
    );
  }

  // Desain Kartu Produk menyesuaikan tema UI yang sudah ada
  Widget _buildProductCard(Map<String, dynamic> item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar / Ikon Dummy (Warna senada dengan tema hijau)
         Expanded(
  child: ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: Image.network(
      item['image'],
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: const Color(0xFFE8F5E9),
        child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
      ),
    ),
  ),
),
          const SizedBox(height: 12),
          // Nama Produk
          Text(
            item['name'],
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: const Color(0xFF111827),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // Harga Produk
          Text(
            'Rp ${item['price']}',
            style: GoogleFonts.poppins(
              color: const Color(0xFF22C55E),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          // Tombol Beli Kecil
          SizedBox(
            width: double.infinity,
            height: 36,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Dimasukkan ke keranjang!'),
                    backgroundColor: Color(0xFF22C55E),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Beli',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOurGoalCardSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Judul Seksi (Centered)
          Center(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF111827),
                ),
                children: const [
                  TextSpan(text: 'Tujuan '),
                  TextSpan(
                    text: 'Utama Kami',
                    style: TextStyle(color: Color(0xFF22C55E)),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Daftar Poin Belanja (3 baris poin deskripsi statis)
          _buildGoalItem('Menyediakan buah-buahan lokal segar pilihan langsung dari petani terbaik di Indonesia.'),
          const SizedBox(height: 14),
          _buildGoalItem('Menjaga standar kualitas dan higienitas pangan yang tinggi dari pemetikan hingga pengantaran.'),
          const SizedBox(height: 14),
          _buildGoalItem('Mempermudah akses masyarakat untuk hidup sehat dengan harga buah yang terjangkau.'),
        ],
      ),
    );
  }

  Widget _buildGoalItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Green check circle icon (anti-kaku daripada menggunakan bullet list)
        const Icon(
          Icons.check_circle_rounded,
          color: Color(0xFF22C55E),
          size: 20,
        ),
        const SizedBox(width: 12),
        // Deskripsi teks
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF4B5563),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHowToShopSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Judul Tengah
        Center(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111827),
              ),
              children: const [
                TextSpan(text: 'Cara '),
                TextSpan(
                  text: 'Belanja',
                  style: TextStyle(color: Color(0xFF22C55E)),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 6),
        
        // Deskripsi Pendek di bawah judul
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Ikuti 4 langkah mudah berikut untuk memesan buah lokal segar pilihan Anda.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF6B7280),
                height: 1.4,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Sistem Kartu Horizontal 4 Langkah
        _buildStepCard(
          step: 1,
          title: 'Pilih Buah',
          description: 'Cari dan tentukan buah segar lokal favorit yang ingin Anda beli dari katalog kami.',
          icon: Icons.shopping_bag_rounded,
          boxColor: const Color(0xFFE8F5E9), // hijau muda pastel
          iconColor: const Color(0xFF22C55E), // hijau solid
        ),
        
        const SizedBox(height: 14),
        
        _buildStepCard(
          step: 2,
          title: 'Checkout',
          description: 'Masukkan alamat pengiriman lengkap dan pilih metode pembayaran pilihan Anda.',
          icon: Icons.credit_card_rounded,
          boxColor: const Color(0xFFE3F2FD), // biru muda pastel
          iconColor: Colors.blue.shade600, // biru solid
        ),
        
        const SizedBox(height: 14),
        
        _buildStepCard(
          step: 3,
          title: 'Diproses',
          description: 'Pesanan Anda disiapkan secara higienis oleh tim kami untuk menjaga kualitas buah.',
          icon: Icons.inventory_2, // solid box/paket
          boxColor: const Color(0xFFFFF8E1), // kuning/oranye muda pastel
          iconColor: Colors.orange.shade700, // oranye solid
        ),
        
        const SizedBox(height: 14),
        
        _buildStepCard(
          step: 4,
          title: 'Lacak & Terima',
          description: 'Kurir kami mengantarkan pesanan dengan cepat. Pantau pengiriman langsung di aplikasi.',
          icon: Icons.local_shipping_rounded, // truk pengantar
          boxColor: const Color(0xFFFFEBEE), // merah muda pastel
          iconColor: Colors.red.shade600, // merah solid
        ),
      ],
    );
  }

  Widget _buildStepCard({
    required int step,
    required String title,
    required String description,
    required IconData icon,
    required Color boxColor,
    required Color iconColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Sisi Kiri: Kotak wadah ikon berbentuk persegi tumpul (circular 12)
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: boxColor,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Sisi Kanan: Judul langkah & deskripsi
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Langkah $step: $title',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}