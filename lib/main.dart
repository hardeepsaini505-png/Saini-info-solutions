import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const SainiApp());
}

// =====================================================
// STORE / LOCAL DATABASE
// =====================================================

class Store {
  static final Store instance = Store._();
  Store._();

  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> customers = [];
  List<Map<String, dynamic>> bills = [];

  int billNo = 1;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    products = _decode(prefs.getString('products'));
    customers = _decode(prefs.getString('customers'));
    bills = _decode(prefs.getString('bills'));
    billNo = prefs.getInt('billNo') ?? 1;
  }

  List<Map<String, dynamic>> _decode(String? data) {
    if (data == null || data.isEmpty) return [];

    try {
      final value = jsonDecode(data);
      if (value is! List) return [];

      return value
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('products', jsonEncode(products));
    await prefs.setString('customers', jsonEncode(customers));
    await prefs.setString('bills', jsonEncode(bills));
    await prefs.setInt('billNo', billNo);
  }
}

// =====================================================
// APP
// =====================================================

class SainiApp extends StatelessWidget {
  const SainiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Saini Info Solutions',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const HomePage(),
    );
  }
}

// =====================================================
// HOME
// =====================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadStore();
  }

  Future<void> _loadStore() async {
    await Store.instance.load();

    if (!mounted) return;

    setState(() {
      loading = false;
    });
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final pages = [
      Dashboard(onRefresh: refresh),
      ProductsPage(onRefresh: refresh),
      CustomersPage(onRefresh: refresh),
      BillsPage(onRefresh: refresh),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saini Info Solutions'),
      ),
      body: pages[index],
      floatingActionButton: index == 1
          ? FloatingActionButton.extended(
              onPressed: _addProduct,
              icon: const Icon(Icons.add),
              label: const Text('Product'),
            )
          : index == 2
              ? FloatingActionButton.extended(
                  onPressed: _addCustomer,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Customer'),
                )
              : index == 3
                  ? FloatingActionButton.extended(
                      onPressed: _addBill,
                      icon: const Icon(Icons.receipt_long),
                      label: const Text('Bill'),
                    )
                  : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) {
          setState(() => index = value);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2),
            label: 'Stock',
          ),
          NavigationDestination(
            icon: Icon(Icons.people),
            label: 'Customers',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long),
            label: 'Bills',
          ),
        ],
      ),
    );
  }

  // ===================================================
  // ADD PRODUCT
  // ===================================================

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
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Opening stock',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: lowController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Low stock limit',
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
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;
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
      refresh();
    }

    nameController.dispose();
    qtyController.dispose();
    priceController.dispose();
    lowController.dispose();
  }

  // ===================================================
  // ADD CUSTOMER
  // ===================================================

  Future<void> _addCustomer() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Customer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Customer name',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile number',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      Store.instance.customers.add({
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'balance': 0.0,
      });

      await Store.instance.save();
      refresh();
    }

    nameController.dispose();
    phoneController.dispose();
  }

  // ===================================================
  // ADD BILL
  // ===================================================

  Future<void> _addBill() async {
    if (Store.instance.products.isEmpty) {
      await _showMessage('Add a product first.');
      return;
    }

    if (Store.instance.customers.isEmpty) {
      await _showMessage('Add a customer first.');
      return;
    }

    String? selectedProduct;
    String? selectedCustomer;
    final qtyController = TextEditingController(text: '1');

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Create Sale Bill'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedProduct,
                      decoration: const InputDecoration(
                        labelText: 'Product',
                      ),
                      items: Store.instance.products.map((product) {
                        final name = product['name'].toString();
                        final stock = _toInt(product['qty']);
                        return DropdownMenuItem<String>(
                          value: name,
                          child: Text('$name (Stock: $stock)'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() => selectedProduct = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCustomer,
                      decoration: const InputDecoration(
                        labelText: 'Customer',
                      ),
                      items: Store.instance.customers.map((customer) {
                        final name = customer['name'].toString();
                        return DropdownMenuItem<String>(
                          value: name,
                          child: Text(name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() => selectedCustomer = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: qtyController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedProduct == null ||
                        selectedCustomer == null) {
                      return;
                    }
                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      final qty = int.tryParse(qtyController.text.trim()) ?? 0;

      if (qty <= 0 || selectedProduct == null || selectedCustomer == null) {
        await _showMessage('Enter a valid quantity.');
      } else {
        final productIndex = Store.instance.products.indexWhere(
          (p) => p['name'].toString() == selectedProduct,
        );

        if (productIndex < 0) {
          await _showMessage('Product not found.');
        } else {
          final product = Store.instance.products[productIndex];
          final stock = _toInt(product['qty']);

          if (qty > stock) {
            await _showMessage('Not enough stock. Available: $stock');
          } else {
            final price = _toDouble(product['price']);
            final total = price * qty;

            product['qty'] = stock - qty;

            final customerIndex = Store.instance.customers.indexWhere(
              (c) => c['name'].toString() == selectedCustomer,
            );

            if (customerIndex >= 0) {
              final customer = Store.instance.customers[customerIndex];
              customer['balance'] =
                  _toDouble(customer['balance']) + total;
            }

            Store.instance.bills.add({
              'billNo': Store.instance.billNo,
              'date': DateTime.now().toIso8601String(),
              'product': selectedProduct,
              'customer': selectedCustomer,
              'qty': qty,
              'price': price,
              'total': total,
            });

            Store.instance.billNo++;
            await Store.instance.save();
            refresh();
          }
        }
      }
    }

    qtyController.dispose();
  }

  Future<void> _showMessage(String message) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Saini Info Solutions'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// DASHBOARD
// =====================================================

class Dashboard extends StatelessWidget {
  final VoidCallback onRefresh;

  const Dashboard({
    super.key,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final products = Store.instance.products;
    final customers = Store.instance.customers;
    final bills = Store.instance.bills;

    final lowStock = products.where((p) {
      return _toInt(p['qty']) <= _toInt(p['low'], 2);
    }).length;

    final totalSales = bills.fold<double>(
      0,
      (sum, bill) => sum + _toDouble(bill['total']),
    );

    return RefreshIndicator(
      onRefresh: () async {
        await Store.instance.load();
        onRefresh();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _DashboardCard(
            title: 'Total Products',
            value: products.length.toString(),
            icon: Icons.inventory_2,
          ),
          _DashboardCard(
            title: 'Low / Nil Stock',
            value: lowStock.toString(),
            icon: Icons.warning_amber,
          ),
          _DashboardCard(
            title: 'Customers',
            value: customers.length.toString(),
            icon: Icons.people,
          ),
          _DashboardCard(
            title: 'Total Sales',
            value: '₹${totalSales.toStringAsFixed(2)}',
            icon: Icons.currency_rupee,
          ),
          _DashboardCard(
            title: 'Bills',
            value: bills.length.toString(),
            icon: Icons.receipt_long,
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _DashboardCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// =====================================================
// PRODUCTS
// =====================================================

class ProductsPage extends StatelessWidget {
  final VoidCallback onRefresh;

  const ProductsPage({
    super.key,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final products = Store.instance.products;

    if (products.isEmpty) {
      return const Center(
        child: Text('No products added yet.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final qty = _toInt(product['qty']);
        final low = _toInt(product['low'], 2);
        final isLow = qty <= low;

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Text(qty.toString()),
            ),
            title: Text(product['name'].toString()),
            subtitle: Text(
              'Sale price: ₹${_toDouble(product['price']).toStringAsFixed(2)}'
              '\nLow limit: $low',
            ),
            isThreeLine: true,
            trailing: isLow
                ? const Chip(
                    label: Text('LOW'),
                  )
                : const Icon(Icons.check_circle_outline),
            onLongPress: () async {
              Store.instance.products.removeAt(index);
              await Store.instance.save();
              onRefresh();
            },
          ),
        );
      },
    );
  }
}

// =====================================================
// CUSTOMERS
// =====================================================

class CustomersPage extends StatelessWidget {
  final VoidCallback onRefresh;

  const CustomersPage({
    super.key,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final customers = Store.instance.customers;

    if (customers.isEmpty) {
      return const Center(
        child: Text('No customers added yet.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: customers.length,
      itemBuilder: (context, index) {
        final customer = customers[index];
        final balance = _toDouble(customer['balance']);

        return Card(
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.person),
            ),
            title: Text(customer['name'].toString()),
            subtitle: Text(
              '${customer['phone']}\nBalance: ₹${balance.toStringAsFixed(2)}',
            ),
            isThreeLine: true,
            onLongPress: () async {
              Store.instance.customers.removeAt(index);
              await Store.instance.save();
              onRefresh();
            },
          ),
        );
      },
    );
  }
}

// =====================================================
// BILLS
// =====================================================

class BillsPage extends StatelessWidget {
  final VoidCallback onRefresh;

  const BillsPage({
    super.key,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final bills = Store.instance.bills;

    if (bills.isEmpty) {
      return const Center(
        child: Text('No bills created yet.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: bills.length,
      itemBuilder: (context, index) {
        final bill = bills[index];
        final date = DateTime.tryParse(
          bill['date']?.toString() ?? '',
        );

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Text(
                bill['billNo'].toString(),
              ),
            ),
            title: Text(
              'Bill #${bill['billNo']} - ${bill['customer']}',
            ),
            subtitle: Text(
              '${bill['product']} × ${bill['qty']}'
              '\n${date == null ? '' : _formatDate(date)}',
            ),
            isThreeLine: true,
            trailing: Text(
              '₹${_toDouble(bill['total']).toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}

// =====================================================
// HELPERS
// =====================================================

int _toInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String _formatDate(DateTime date) {
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  return '$d-$m-${date.year}';
}
