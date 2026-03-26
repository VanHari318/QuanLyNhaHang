import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/menu_provider.dart';
import '../models/food_item.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/cloudinary_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  final _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final menuProvider = Provider.of<MenuProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Menu Management')),
      body: ListView.builder(
        itemCount: menuProvider.items.length,
        itemBuilder: (context, index) {
          final item = menuProvider.items[index];
          return ListTile(
            leading: item.imageUrl.isNotEmpty && !item.imageUrl.startsWith('/')
              ? Image.network(item.imageUrl, width: 50, height: 50, fit: BoxFit.cover)
              : const Icon(Icons.fastfood, size: 50),
            title: Text(item.name),
            subtitle: Text('${item.price.toStringAsFixed(0)}đ - ${item.category}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showFoodItemDialog(item: item),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => menuProvider.deleteItem(item.id),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFoodItemDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showFoodItemDialog({FoodItem? item}) {
    final nameController = TextEditingController(text: item?.name);
    final descController = TextEditingController(text: item?.description);
    final priceController = TextEditingController(text: item?.price.toString());
    final catController = TextEditingController(text: item?.category);
    
    File? localImage;
    XFile? localWebImage;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(item == null ? 'Add Food Item' : 'Edit Food Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
                TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
                TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
                TextField(controller: catController, decoration: const InputDecoration(labelText: 'Category')),
                const SizedBox(height: 10),
                if (localImage != null || localWebImage != null)
                  Image(
                    image: kIsWeb ? NetworkImage(localWebImage!.path) : FileImage(localImage!) as ImageProvider,
                    height: 100,
                    width: 100,
                    fit: BoxFit.cover,
                  )
                else if (item?.imageUrl != null && item!.imageUrl.isNotEmpty)
                  Image.network(item.imageUrl, height: 100, width: 100, fit: BoxFit.cover),
                
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () async {
                    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      setDialogState(() {
                        if (kIsWeb) {
                          localWebImage = image;
                        } else {
                          localImage = File(image.path);
                        }
                      });
                    }
                  },
                  icon: const Icon(Icons.image),
                  label: const Text('Pick Image'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            isUploading 
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: () async {
                    setDialogState(() => isUploading = true);
                    
                    String finalImageUrl = item?.imageUrl ?? '';
                    
                    if (localImage != null || localWebImage != null) {
                      finalImageUrl = await CloudinaryService.uploadImage(
                        imageFile: localImage,
                        webImage: localWebImage,
                        preset: CloudinaryService.foodPreset,
                        folder: CloudinaryService.foodFolder,
                      );
                    }

                    final newItem = FoodItem(
                      id: item?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameController.text,
                      description: descController.text,
                      price: double.tryParse(priceController.text) ?? 0.0,
                      imageUrl: finalImageUrl,
                      category: catController.text,
                    );
                    
                    if (item == null) {
                      await Provider.of<MenuProvider>(context, listen: false).addItem(newItem);
                    } else {
                      await Provider.of<MenuProvider>(context, listen: false).updateItem(newItem);
                    }
                    
                    Navigator.pop(context);
                  },
                  child: Text(item == null ? 'Add' : 'Save'),
                ),
          ],
        ),
      ),
    );
  }
}
