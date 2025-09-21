import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

class UpdateProductPage extends StatefulWidget {
  final RecordModel product;

  const UpdateProductPage({super.key, required this.product});

  @override
  State<UpdateProductPage> createState() => _UpdateProductPageState();
}

class _UpdateProductPageState extends State<UpdateProductPage> {
  final pb = PocketBase('http://127.0.0.1:8090');
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _imageController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.data["name"]);
    _priceController = TextEditingController(text: widget.product.data["price"].toString());
    _imageController = TextEditingController(text: widget.product.data["image_url"]);
  }

  Future<void> _updateProduct() async {
    try {
      final record = await pb.collection('product').update(widget.product.id, body: {
        "name": _nameController.text,
        "price": double.tryParse(_priceController.text) ?? 0,
        "image_url": _imageController.text,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Product updated successfully")),
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
      appBar: AppBar(title: const Text("Update Product")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Name")),
            TextField(controller: _priceController, decoration: const InputDecoration(labelText: "Price"), keyboardType: TextInputType.number),
            TextField(controller: _imageController, decoration: const InputDecoration(labelText: "Image URL")),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _updateProduct, child: const Text("Update")),
          ],
        ),
      ),
    );
  }
}