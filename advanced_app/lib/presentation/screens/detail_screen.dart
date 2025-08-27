// import 'package:flutter/material.dart';

// class DetailScreen extends StatelessWidget {
//   const DetailScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Detail")),
//       body: Center(
//         child: Hero(
//           tag: 'plus-hero', // 🔑 ต้องตรงกับ HomeScreen
//           child: SizedBox(
//             width: 120,
//             height: 120,
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(24),
//               child: Image.asset(
//                 'assets/images/plus.jpg',
//                 fit: BoxFit.cover,
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';

class Detail extends StatefulWidget {
  const Detail({super.key});

  @override
  State<Detail> createState() => _DetailState();
}

class _DetailState extends State<Detail> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Page'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('This is the detail page'),
            Hero(
              tag: 'logoHero',
              child: Image(image: AssetImage('images/logo.jpg'), width: 200, height: 200),
            )
          ],
        )
      ),
    );
  }
}