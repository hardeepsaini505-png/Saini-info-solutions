  Future<void> _addProduct() async {
    final nameController = TextEditingController();
    final qtyController = TextEditingController();
    final priceController = TextEditingController();
    final lowController = TextEditingController(text: '2');

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Product name',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Opening stock',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: lowController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Low stock limit',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Sale price',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  return;
                }

                Navigator.pop(dialogContext, true);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      final name = nameController.text.trim();
      final qty = int.tryParse(qtyController.text.trim()) ?? 0;
      final price = double.tryParse(priceController.text.trim()) ?? 0;
      final low = int.tryParse(lowController.text.trim()) ?? 2;

      Store.instance.products.add({
        'name': name,
        'qty': qty,
        'price': price,
        'low': low,
      });

      await Store.instance.save();

      if (mounted) {
        setState(() {});
      }
    }

    nameController.dispose();
    qtyController.dispose();
    priceController.dispose();
    lowController.dispose();
  }
