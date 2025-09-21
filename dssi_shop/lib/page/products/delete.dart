// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:pocketbase/pocketbase.dart';

// class DeleteProductPage extends StatefulWidget {
//   final RecordModel product;
  
//   const DeleteProductPage({super.key, required this.product});

//   @override
//   _DeleteProductPageState createState() => _DeleteProductPageState();
// }

// class _DeleteProductPageState extends State<DeleteProductPage> {
//   final pb = PocketBase('http://127.0.0.1:8090');
//   bool _isDeleting = false;
//   bool _isDeleted = false;
//   UnsubscribeFunc? _unsubscribeRealtime;

//   @override
//   void initState() {
//     super.initState();
//     _setupRealtimeListener();
//   }

//   void _setupRealtimeListener() {
//     // รอให้ widget mount เสร็จก่อน
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (mounted) {
//         pb.realtime.subscribe("collections.Product.records", (msg) {
//           try {
//             print("=== DELETE PAGE REALTIME MESSAGE ===");
//             print("Raw message: ${msg.data}");
            
//             final data = jsonDecode(msg.data);
//             final action = data["action"];
//             final record = RecordModel.fromJson(data["record"]);

//             // เช็คว่าเป็น product ที่เราจะลบหรือไม่
//             if (record.id == widget.product.id && action == "delete") {
//               print("🗑️ Product ${record.id} was deleted via realtime");
              
//               if (mounted && !_isDeleted) {
//                 setState(() {
//                   _isDeleted = true;
//                 });
                
//                 // แสดง success message และปิด dialog
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(
//                     content: Row(
//                       children: [
//                         const Icon(Icons.check_circle, color: Colors.white),
//                         const SizedBox(width: 8),
//                         Text(
//                           "✅ สินค้า '${widget.product.data['name']}' ถูกลบแล้ว",
//                           style: GoogleFonts.prompt(),
//                         ),
//                       ],
//                     ),
//                     backgroundColor: const Color(0xFF4CAF50),
//                     behavior: SnackBarBehavior.floating,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     duration: const Duration(seconds: 2),
//                   ),
//                 );
                
//                 // ปิด dialog หลังจาก delay เล็กน้อย
//                 Future.delayed(const Duration(milliseconds: 500), () {
//                   if (mounted) {
//                     Navigator.pop(context, true);
//                   }
//                 });
//               }
//             }
//           } catch (e) {
//             print("❌ Delete page realtime parsing error: $e");
//           }
//         }).then((unsubscribe) {
//           if (mounted) {
//             _unsubscribeRealtime = unsubscribe;
//             print("🔔 Delete page realtime subscription established");
//           } else {
//             unsubscribe.call();
//           }
//         }).catchError((error) {
//           print("❌ Failed to establish delete page realtime subscription: $error");
//         });
//       }
//     });
//   }

//   Future<void> _deleteProduct() async {
//     if (_isDeleting || _isDeleted) return;
    
//     setState(() {
//       _isDeleting = true;
//     });

//     try {
//       print("🗑️ Attempting to delete product: ${widget.product.id}");
//       await pb.collection('Product').delete(widget.product.id);
//       print("✅ Delete API call successful");
      
//       // Realtime จะจัดการ UI update ให้เอง
//       // ไม่ต้องทำอะไรเพิ่มเติมที่นี่
//     } catch (e) {
//       print("❌ Delete error: $e");
//       setState(() {
//         _isDeleting = false;
//       });
      
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Row(
//               children: [
//                 const Icon(Icons.error, color: Colors.white),
//                 const SizedBox(width: 8),
//                 Text(
//                   "❌ เกิดข้อผิดพลาด: $e",
//                   style: GoogleFonts.prompt(),
//                 ),
//               ],
//             ),
//             backgroundColor: const Color(0xFFFF1493),
//             behavior: SnackBarBehavior.floating,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//             duration: const Duration(seconds: 3),
//           ),
//         );
//       }
//     }
//   }

//   @override
//   void dispose() {
//     print("🔄 Disposing DeleteProductPage, unsubscribing from realtime...");
//     _unsubscribeRealtime?.call();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(20),
//       ),
//       title: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: const Color(0xFFFF69B4).withOpacity(0.2),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Icon(
//               _isDeleted ? Icons.check_circle : Icons.delete_outline,
//               color: _isDeleted ? const Color(0xFF4CAF50) : const Color(0xFFFF1493),
//               size: 20,
//             ),
//           ),
//           const SizedBox(width: 12),
//           Text(
//             _isDeleted ? 'ลบสำเร็จ!' : 'ยืนยันการลบ',
//             style: GoogleFonts.prompt(
//               color: _isDeleted ? const Color(0xFF4CAF50) : const Color(0xFFFF1493),
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//       content: _isDeleted 
//         ? Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Icon(
//                 Icons.check_circle,
//                 color: Color(0xFF4CAF50),
//                 size: 48,
//               ),
//               const SizedBox(height: 12),
//               Text(
//                 'สินค้าถูกลบเรียบร้อยแล้ว',
//                 style: GoogleFonts.prompt(
//                   color: const Color(0xFF4CAF50),
//                   fontWeight: FontWeight.w600,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//             ],
//           )
//         : Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(
//                 'คุณต้องการลบสินค้า "${widget.product.data['name']}" หรือไม่?',
//                 style: GoogleFonts.prompt(
//                   color: const Color(0xFF8B5A83),
//                 ),
//               ),
//               if (_isDeleting) ...[
//                 const SizedBox(height: 16),
//                 const CircularProgressIndicator(
//                   valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF69B4)),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   'กำลังลบ...',
//                   style: GoogleFonts.prompt(
//                     color: const Color(0xFF8B5A83),
//                     fontSize: 12,
//                   ),
//                 ),
//               ],
//             ],
//           ),
//       actions: _isDeleted 
//         ? [] // ไม่แสดงปุ่มเมื่อลบเสร็จแล้ว
//         : [
//             TextButton(
//               onPressed: _isDeleting ? null : () => Navigator.of(context).pop(false),
//               style: TextButton.styleFrom(
//                 foregroundColor: const Color(0xFF8B5A83),
//               ),
//               child: Text(
//                 'ยกเลิก',
//                 style: GoogleFonts.prompt(),
//               ),
//             ),
//             ElevatedButton(
//               onPressed: _isDeleting ? null : _deleteProduct,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: _isDeleting 
//                   ? const Color(0xFF8B5A83).withOpacity(0.5)
//                   : const Color(0xFFFF1493),
//                 foregroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//               child: _isDeleting
//                 ? const SizedBox(
//                     width: 16,
//                     height: 16,
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2,
//                       valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                     ),
//                   )
//                 : Text(
//                     'ลบ',
//                     style: GoogleFonts.prompt(
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//             ),
//           ],
//     );
//   }
// }