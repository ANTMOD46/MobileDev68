import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

class CreateProductPage extends StatefulWidget {
  const CreateProductPage({super.key});

  @override
  State<CreateProductPage> createState() => _CreateProductPageState();
}

class _CreateProductPageState extends State<CreateProductPage> {
  final pb = PocketBase('http://127.0.0.1:8090');
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageController = TextEditingController();

  Future<void> _createProduct() async {
    try {
      final record = await pb.collection('product').create(body: {
        "name": _nameController.text.trim(),
        "price": double.tryParse(_priceController.text.trim()) ?? 0,
        "imageUrl": _imageController.text.trim(), // ✅ เปลี่ยนตรงนี้
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Product created successfully")),
      );

      Navigator.pop(context, record);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Product")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: "Price"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _imageController,
              decoration: const InputDecoration(labelText: "Image URL"), // ✅ label ก็ให้ตรง
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _createProduct,
              child: const Text("Create"),
            ),
          ],
        ),
      ),
    );
  }
}
