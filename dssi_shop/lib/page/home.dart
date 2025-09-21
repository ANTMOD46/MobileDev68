import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketbase/pocketbase.dart';
import 'products/list.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final pb = PocketBase('http://127.0.0.1:8090');
  late final RecordService _service;
  final ScrollController _scrollController = ScrollController();
  final List<RecordModel> _topProducts = [];
  bool _isLoading = false;
  UnsubscribeFunc? _unsubscribeRealtime;

  @override
  void initState() {
    super.initState();
    _service = pb.collection('product');
    _fetchTopProducts();

    // subscribe realtime
    pb.realtime.subscribe("collections.product.records", (msg) {
      try {
        final data = jsonDecode(msg.data);
        final action = data["action"];
        final record = RecordModel.fromJson(data["record"]);

        setState(() {
          if (action == "create") {
            _topProducts.insert(0, record);
          } else if (action == "update") {
            final index = _topProducts.indexWhere((p) => p.id == record.id);
            if (index != -1) {
              _topProducts[index] = record;
            }
          } else if (action == "delete") {
            _topProducts.removeWhere((p) => p.id == record.id);
          }

          // sort ใหม่ล่าสุดอยู่บน
          _topProducts.sort((a, b) =>
              (b.updated ?? b.created).compareTo(a.updated ?? a.created));
        });
      } catch (e) {
        print("Home realtime error: $e");
      }
    }).then((unsubscribe) {
      _unsubscribeRealtime = unsubscribe;
    });
  }

  Future<void> _fetchTopProducts() async {
    if (_isLoading) return;
    _isLoading = true;
    try {
      final result =
          await _service.getList(page: 1, perPage: 10, sort: "-created");
      setState(() {
        _topProducts
          ..clear()
          ..addAll(result.items);
      });
    } catch (e) {
      print("Error fetching top products: $e");
    }
    _isLoading = false;
  }

  @override
  void dispose() {
    _unsubscribeRealtime?.call();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollLeft() {
    _scrollController.animateTo(
      _scrollController.offset - 200,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _scrollRight() {
    _scrollController.animateTo(
      _scrollController.offset + 200,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5), // Lavender Blush background
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.favorite,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'DSSiShop Modsty ',
              style: GoogleFonts.prompt(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFFF69B4), // Hot Pink
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFF1493), // Deep Pink
                Color(0xFFFF69B4), // Hot Pink
                Color(0xFFFFB6C1), // Light Pink
              ],
            ),
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => ProductListPage()),
                );
              },
              icon: const Icon(Icons.apps, color: Color(0xFFFF1493)),
              label: Text(
                'All Products',
                style: GoogleFonts.prompt(
                  color: const Color(0xFFFF1493),
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFFF1493),
                elevation: 4,
                shadowColor: Colors.pink.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF0F5), // Lavender Blush
              Color(0xFFFDF2F8), // Very light pink
              Color(0xFFFFE4E6), // Misty Rose
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 0 : width * 0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                
                // Welcome section
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFFE4E6), // Light pink
                        Color(0xFFFFF0F5), // Lavender blush
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pink.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF69B4).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.shopping_bag,
                          color: Color(0xFFFF1493),
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ยินดีต้อนรับ! 💕',
                              style: GoogleFonts.prompt(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFFF1493),
                              ),
                            ),
                            Text(
                              'พบสินค้าน่ารักๆ ที่คุณชื่นชอบ',
                              style: GoogleFonts.prompt(
                                fontSize: 14,
                                color: const Color(0xFF8B5A83),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Top Products
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 30, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF69B4).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.star,
                              color: Color(0xFFFF1493),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'สินค้ายอดนิยม',
                            style: GoogleFonts.prompt(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFF1493),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.pink.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back_ios,
                                color: Color(0xFFFF69B4),
                                size: 18,
                              ),
                              onPressed: _scrollLeft,
                              style: IconButton.styleFrom(
                                padding: const EdgeInsets.all(8),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_forward_ios,
                                color: Color(0xFFFF69B4),
                                size: 18,
                              ),
                              onPressed: _scrollRight,
                              style: IconButton.styleFrom(
                                padding: const EdgeInsets.all(8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(
                  height: isMobile ? 200 : 220,
                  child: _isLoading
                      ? Center(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.pink.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFFF69B4),
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _topProducts.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 16),
                          itemBuilder: (context, index) {
                            final product = _topProducts[index];
                            return Container(
                              width: isMobile ? 140 : 160,
                              child: Card(
                                elevation: 8,
                                shadowColor: Colors.pink.withOpacity(0.2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    gradient: const LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.white,
                                        Color(0xFFFFF8FA),
                                      ],
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        height: isMobile ? 90 : 110,
                                        decoration: const BoxDecoration(
                                          borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(20)),
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Color(0xFFFFE4E6),
                                              Color(0xFFFFF0F5),
                                            ],
                                          ),
                                        ),
                                        child: Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius: const BorderRadius.vertical(
                                                  top: Radius.circular(20)),
                                              child: Image.network(
                                                product.data['imageUrl'] ?? '',
                                                height: double.infinity,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            Positioned(
                                              top: 8,
                                              right: 8,
                                              child: Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.9),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: const Icon(
                                                  Icons.favorite_border,
                                                  color: Color(0xFFFF69B4),
                                                  size: 16,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product.data['name'] ?? '',
                                              style: GoogleFonts.prompt(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: const Color(0xFF2D1B2E),
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFF69B4).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                '฿${product.data['price']}',
                                                style: GoogleFonts.prompt(
                                                  color: const Color(0xFFFF1493),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}