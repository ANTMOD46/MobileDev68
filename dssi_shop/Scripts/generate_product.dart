// import 'dart:async';
// import 'dart:math';
// import 'package:pocketbase/pocketbase.dart';

// final pb = PocketBase('http://127.0.0.1:8090');

// void main() async {
//   try {
//     // 1. Authenticate with PocketBase as a regular user
//     // (ใช้สำหรับการล็อกอินผู้ใช้ทั่วไป)
//   final authResult = await pb.collection('users').authWithPassword(
//     'chantima.ju.65@ubu.ac.th',
//     'Mod0625703684', // ใช้รหัสผ่านที่ถูกต้องสำหรับผู้ใช้ทั่วไป
//   );
//     final adminEmail = authResult.record?.data['email'] ?? 'ผู้ดูแลระบบ';
//     print('✅ การยืนยันตัวตนสำเร็จ! ผู้ดูแลระบบ: $adminEmail');

//     // 2. Clear existing records to avoid duplicates
//     print('⏳ กำลังดึงข้อมูลเดิมจาก DssiShop...');
//     final existingRecords = await pb.collection('DssiShop').getFullList();
//     if (existingRecords.isNotEmpty) {
//       print('🗑️ กำลังลบข้อมูลเดิม ${existingRecords.length} รายการ...');
//       for (var record in existingRecords) {
//         await pb.collection('DssiShop').delete(record.id);
//       }
//       print('✅ ลบข้อมูลเดิมทั้งหมดเรียบร้อยแล้ว');
//     } else {
//       print('ℹ️ ไม่พบข้อมูลเดิม กำลังดำเนินการต่อ...');
//     }

//     // 3. Generate and create 100 random products
//     final int numberOfProducts = 100;
//     final List<Future<RecordModel>> creationFutures = [];
    
//     print('🚀 กำลังสร้างผลิตภัณฑ์แบบสุ่ม $numberOfProducts รายการ...');

//     for (int i = 1; i <= numberOfProducts; i++) {
//       final product = _generateRandomProduct(i);
      
//       creationFutures.add(pb.collection('DssiShop').create(body: product));
//     }

//     // Wait for all product creation futures to complete
//     await Future.wait(creationFutures);

//     print('🎉 สร้างผลิตภัณฑ์แบบสุ่ม $numberOfProducts รายการสำเร็จแล้ว!');

//   } on ClientException catch (e) {
//     print('❌ เกิดข้อผิดพลาดจาก PocketBase: ${e.response}');
//   } catch (e) {
//     print('❌ เกิดข้อผิดพลาดที่ไม่คาดคิด: $e');
//   }
// }

// Map<String, dynamic> _generateRandomProduct(int index) {
//   final random = Random();
//   final productName = 'สินค้าสุ่ม ${index.toString().padLeft(3, '0')}';
//   final price = (random.nextInt(100) * 100) + 1000;
//   final imagePlaceholderId = random.nextInt(1000) + 1; // Example placeholder image
//   final imageUrl = 'https://picsum.photos/id/$imagePlaceholderId/300/300';

//   return {
//     'name': productName,
//     'price': price,
//     'imageURL': imageUrl,
//   };
// }

import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:pocketbase/pocketbase.dart';
import 'package:faker/faker.dart';

Future<void> main() async {
  final pb = PocketBase('http://127.0.0.1:8090');
  final faker = Faker();
  final random = Random();

  try {
    // Authenticate as admin
    await pb.admins
        .authWithPassword('chantima.ju.65@ubu.ac.th', 'Mod0625703684');
    print('Connected as admin');
  } catch (e) {
    print('Failed to authenticate admin: $e');
    return;
  }

  for (int i = 0; i < 100; i++) {
    final name = faker.food.dish(); // ชื่ออาหารแบบสุ่ม
    final price = (random.nextDouble() * 500 + 50).toStringAsFixed(2);

    // เรียก API จาก Foodish
    String imageUrl = '';
    try {
      final res = await http.get(Uri.parse('https://foodish-api.com/api/'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        imageUrl = data['image'];
      } else {
        imageUrl = 'https://via.placeholder.com/200'; // fallback
      }
    } catch (e) {
      imageUrl = 'https://via.placeholder.com/200'; // fallback
    }

    try {
      final record = await pb.collection('product').create(body: {
        'name': name,
        'price': double.parse(price),
        'imageUrl': imageUrl,
      });
      print('Created: ${record.id} - $name');
    } catch (e, st) {
      print('Error creating $name: $e');
      print(st);
    }
  }

  print('Finished generating 100 food products into PocketBase.');
}




