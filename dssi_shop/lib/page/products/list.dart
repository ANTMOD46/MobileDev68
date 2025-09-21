import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketbase/pocketbase.dart';
import 'create.dart';
import 'update.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  _ProductListPageState createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final pb = PocketBase('http://127.0.0.1:8090');
  final ScrollController _scrollController = ScrollController();
  final List<RecordModel> _products = [];

  final int _pageSize = 20;
  int _page = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  
  // เก็บ unsubscribe function
  UnsubscribeFunc? _unsubscribeRealtime;

  @override
  void initState() {
    super.initState();
    _fetchProducts(reset: true);

    // ใช้วิธีเดียวกันกับ HomePage ทุกอย่าง
    pb.realtime.subscribe("collections.Product.records", (msg) {
      try {
        print("=== ProductList REALTIME MESSAGE ===");
        print("Message data: ${msg.data}");
        
        final data = jsonDecode(msg.data);
        final action = data["action"];
        final record = RecordModel.fromJson(data["record"]);

        print("Action: $action, Product: ${record.data['name']}");

        setState(() {
          if (action == "create") {
            _products.insert(0, record);
            print("✅ CREATED: Added to ProductList");
          } else if (action == "update") {
            final index = _products.indexWhere((p) => p.id == record.id);
            if (index != -1) {
              _products[index] = record;
              print("✅ UPDATED: Updated in ProductList");
            }
          } else if (action == "delete") {
            final beforeCount = _products.length;
            _products.removeWhere((p) => p.id == record.id);
            print("✅ DELETED: Removed from ProductList (${beforeCount} → ${_products.length})");
          }

          // sort ใหม่ล่าสุดอยู่บน (เหมือน HomePage)
          _products.sort((a, b) =>
              (b.updated ?? b.created).compareTo(a.updated ?? a.created));
        });
      } catch (e) {
        print("ProductList realtime error: $e");
      }
    }).then((unsubscribe) {
      _unsubscribeRealtime = unsubscribe;
      print("🔔 ProductList realtime subscription ready");
    });

    _scrollController.addListener(_onScroll);
  }

  Future<void> _fetchProducts({bool reset = false}) async {
    if (_isLoading) return;
    _isLoading = true;

    if (reset) {
      _products.clear();
      _page = 1;
      _hasMore = true;
    }

    try {
      // ใช้ collection name ที่ถูกต้อง - ต้องตรงกับ PocketBase
      final result = await pb.collection('Product').getList(
            page: _page,
            perPage: _pageSize,
            sort: "-created",
          );

      setState(() {
        _products.addAll(result.items);
        if (result.items.length < _pageSize) _hasMore = false;
      });
    } catch (e) {
      print("Error fetching products: $e");
    }

    _isLoading = false;
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        _hasMore &&
        !_isLoading) {
      _page++;
      _fetchProducts();
    }
  }

 Future<void> _deleteProduct(RecordModel product) async {
  // Show confirmation dialog
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF69B4).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.delete_outline,
                color: Color(0xFFFF1493),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'ยืนยันการลบ',
              style: GoogleFonts.prompt(
                color: const Color(0xFFFF1493),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'คุณต้องการลบสินค้า "${product.data['name']}" หรือไม่?',
          style: GoogleFonts.prompt(
            color: const Color(0xFF8B5A83),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF8B5A83),
            ),
            child: Text(
              'ยกเลิก',
              style: GoogleFonts.prompt(),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF1493),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'ลบ',
              style: GoogleFonts.prompt(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    },
  );

  if (confirmed == true) {
    try {
      // ✅ 1. ลบข้อมูลออกจาก UI ทันที
      setState(() {
        _products.removeWhere((p) => p.id == product.id);
      });

      // ✅ 2. ลบข้อมูลจากฐานข้อมูล
      await pb.collection('Product').delete(product.id);
      
      // แสดงข้อความสำเร็จ
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  "ลบสินค้า: ${product.data['name']} เรียบร้อยแล้ว",
                  style: GoogleFonts.prompt(),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  "เกิดข้อผิดพลาดในการลบ: $e",
                  style: GoogleFonts.prompt(),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFFF1493),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      // ✅ 3. หากล้มเหลว ให้ดึงข้อมูลใหม่เพื่อคืนค่าสินค้าที่ถูกลบไป
      _fetchProducts(reset: true);
    }
  }
}

  @override
  void dispose() {
    print("🔄 Disposing ProductListPage, unsubscribing from realtime...");
    _unsubscribeRealtime?.call();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5), // Lavender Blush background
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.list_alt,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'รายการสินค้า',
              style: GoogleFonts.prompt(
                fontWeight: FontWeight.bold,
                fontSize: 20,
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
              onPressed: () async {
                final created = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateProductPage()),
                );
                if (created != null) {
                  _fetchProducts(reset: true);
                }
              },
              icon: const Icon(Icons.add, color: Color(0xFFFF1493)),
              label: Text(
                'เพิ่มสินค้า',
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
        child: _products.isEmpty && _isLoading
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFFF69B4),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'กำลังโหลดสินค้า...',
                        style: GoogleFonts.prompt(
                          color: const Color(0xFF8B5A83),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Column(
                children: [
                  // Header info
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFFE4E6),
                          Color(0xFFFFF0F5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.pink.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF69B4).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.inventory_2,
                            color: Color(0xFFFF1493),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'จำนวนสินค้าทั้งหมด',
                                style: GoogleFonts.prompt(
                                  fontSize: 14,
                                  color: const Color(0xFF8B5A83),
                                ),
                              ),
                              Text(
                                '${_products.length} รายการ',
                                style: GoogleFonts.prompt(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFFF1493),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Product list
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _products.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _products.length) {
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.pink.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFFFF69B4),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  'กำลังโหลดเพิ่มเติม...',
                                  style: GoogleFonts.prompt(
                                    color: const Color(0xFF8B5A83),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        final product = _products[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Card(
                            elevation: 6,
                            shadowColor: Colors.pink.withOpacity(0.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white,
                                    Color(0xFFFFF8FA),
                                  ],
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFFFFE4E6),
                                        Color(0xFFFFF0F5),
                                      ],
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(
                                      product.data['imageUrl'] ?? '',
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFE4E6),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: const Icon(
                                            Icons.image_not_supported,
                                            color: Color(0xFFFF69B4),
                                            size: 32,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                title: Text(
                                  product.data['name'] ?? '',
                                  style: GoogleFonts.prompt(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2D1B2E),
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF69B4).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '฿${(product.data['price'] ?? 0).toString()}',
                                    style: GoogleFonts.prompt(
                                      color: const Color(0xFFFF1493),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                trailing: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFE4E6),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Color(0xFFFF69B4),
                                          size: 20,
                                        ),
                                        onPressed: () async {
                                          final updated = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  UpdateProductPage(product: product),
                                            ),
                                          );
                                          if (updated != null) {
                                            _fetchProducts(reset: true);
                                          }
                                        },
                                        style: IconButton.styleFrom(
                                          backgroundColor: Colors.white.withOpacity(0.7),
                                          padding: const EdgeInsets.all(8),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Color(0xFFFF1493),
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          _deleteProduct(product);
                                        },
                                        style: IconButton.styleFrom(
                                          backgroundColor: Colors.white.withOpacity(0.7),
                                          padding: const EdgeInsets.all(8),
                                        ),
                                      ),
                                    ],
                                  ),
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
    );
  }
}