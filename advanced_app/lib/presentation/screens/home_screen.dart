// import 'package:flutter/material.dart';
// import 'package:get_it/get_it.dart';
// import '../../core/services/counter_service.dart';
// import 'detail_screen.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   late final CounterService counterService;

//   @override
//   void initState() {
//     super.initState();
//     counterService = GetIt.instance<CounterService>();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           // ✅ ตัวเลขกลางจอ
//           Center(
//             child: Text(
//               'Count: ${counterService.value}',
//               style: const TextStyle(
//                 fontSize: 32,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),

//           // ✅ ปุ่มบวก Hero
//           SafeArea(
//             child: Align(
//               alignment: Alignment.bottomRight,
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: GestureDetector(
//                   onTap: () {
//                     counterService.increment();
//                     setState(() {});
//                     Navigator.of(context).push(
//                       MaterialPageRoute(builder: (_) => const DetailScreen()),
//                     );
//                   },
//                   child: Hero(
//                     tag: 'plus-hero', // 🔑 ต้องตรงกันกับ DetailScreen
//                     child: SizedBox(
//                       width: 64,
//                       height: 64,
//                       child: ClipRRect(
//                         borderRadius: BorderRadius.circular(12),
//                         child: Image.asset(
//                           'assets/images/plus.jpg',
//                           fit: BoxFit.cover,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }




// import 'package:flutter/material.dart';
// import 'playerselection.dart'; // ชื่อไฟล์ต้องตรงจริง ๆ

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   Map<String, dynamic>? teamData; // เปลี่ยนจาก List<String> เป็น Map เพราะ TeamBuilder return team data

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Flutter Demo')),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             if (teamData != null) ...[
//               Text(
//                 "ทีม: ${teamData!['teamName']}",
//                 style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 10),
//               Text(
//                 "สมาชิก: ${(teamData!['members'] as List).map((m) => m['name']).join(', ')}",
//                 textAlign: TextAlign.center,
//               ),
//             ],
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () async {
//                 final result = await Navigator.push<Map<String, dynamic>>(
//                   context,
//                   MaterialPageRoute(builder: (_) => const TeamBuilder()), // เปลี่ยนเป็น TeamBuilder
//                 );
//                 if (!mounted) return;
//                 if (result != null) {
//                   setState(() => teamData = result);
//                 }
//               },
//               child: const Text('สร้างทีม'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'playerselection.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ข้อความเกี่ยวกับโปเกมอน
            const Text(
              'เลือกโปเกมอนคู่หูของคุณ!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 50),

            // ปุ่ม "สร้างทีม"
            SizedBox(
              width: 250, // กำหนดความกว้างของปุ่ม
              height: 60, // กำหนดความสูงของปุ่ม
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TeamBuilder()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600], // สีพื้นหลังปุ่ม
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // ขอบโค้ง
                  ),
                ),
                child: const Text(
                  'สร้างทีมใหม่',
                  style: TextStyle(fontSize: 22, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ข้อความธรรมดา "โปเกมอนดิวะ" ที่มีขนาดใหญ่
            const Text(
              'โปเกมอนดิวะ',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}




