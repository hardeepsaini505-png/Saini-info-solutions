import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() {
  runApp(const SainiApp());
}

// =====================================================
// STORE
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

  List<Map<String, dynamic>> _decode(String? value) {
    if (value == null || value.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(value);

      if (decoded is! List) {
        return [];
      }

      return decoded
          .map<Map<String, dynamic>>(
            (e) => Map<String, dynamic>.from(e as Map),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'products',
      jsonEncode(products),
    );

    await prefs.setString(
      'customers',
      jsonEncode(customers),
    );

    await prefs.setString(
      'bills',
      jsonEncode(bills),
    );

    await prefs.setInt(
      'billNo',
      billNo,
    );
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

  final List<Widget> pages = const [
    Dashboard(),
    ProductsPage(),
    CustomersPage(),
    BillsPage(),
  ];

  @override
  void initState() {
    super.initState();

    Store.instance.load().then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Saini Info Solutions',
        ),
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
              : null,

      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) {
          setState(() {
            index = value;
          });
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
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 10),

                TextField(
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Opening stock',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 10),

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

                const SizedBox(height: 10),

                TextField(
                  controller: lowController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Low stock limit',
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

            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == true &&
        nameController.text.trim().isNotEmpty) {
      Store.instance.products.add({
        'name': nameController.text.trim(),
        'qty': int.tryParse(qtyController.text.trim()) ?? 0,
        'price': double.tryParse(
              priceController.text.trim(),
            ) ??
            0.0,
        'low': int.tryParse(lowController.text.trim()) ?? 2,
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
                  labelText: 'Customer / Party name',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile number',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),

            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == true &&
        nameController.text.trim().isNotEmpty) {
      Store.instance.customers.add({
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'balance': 0.0,
      });

      await Store.instance.save();

      if (mounted) {
        setState(() {});
      }
    }

    nameController.dispose();
    phoneController.dispose();
  }
}

// =====================================================
// DASHBOARD
// =====================================================

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Store.instance;

    final lowStock = store.products.where((product) {
      final qty = _toInt(product['qty']);
      final low = _toInt(product['low']);

      return qty > 0 && qty <= low;
    }).length;

    final nilStock = store.products.where((product) {
      return _toInt(product['qty']) <= 0;
    }).length;

    final today =
        DateFormat('dd-MM-yyyy').format(DateTime.now());

    double todaySales = 0;

    for (final bill in store.bills) {
      if (bill['date'] == today) {
        todaySales += _toDouble(bill['total']);
      }
    }

    return RefreshIndicator(
      onRefresh: () async {
        await store.load();

        if (context.mounted) {
          // Dashboard refresh handled by parent on next rebuild.
        }
      },

      child: ListView(
        padding: const EdgeInsets.all(16),

        children: [
          Text(
            'Welcome to Saini Info Solutions',
            style: Theme.of(context)
                .textTheme
                .headlineSmall,
          ),

          const SizedBox(height: 20),

          Wrap(
            spacing: 12,
            runSpacing: 12,

            children: [
              _dashboardCard(
                context,
                'Products',
                store.products.length.toString(),
                Icons.inventory_2,
              ),

              _dashboardCard(
                context,
                'Low Stock',
                lowStock.toString(),
                Icons.warning,
              ),

              _dashboardCard(
                context,
                'Nil Stock',
                nilStock.toString(),
                Icons.remove_shopping_cart,
              ),

              _dashboardCard(
                context,
                'Customers',
                store.customers.length.toString(),
                Icons.people,
              ),

              _dashboardCard(
                context,
                "Today's Sales",
                '₹${todaySales.toStringAsFixed(2)}',
                Icons.currency_rupee,
              ),

              _dashboardCard(
                context,
                'Bills',
                store.bills.length.toString(),
                Icons.receipt_long,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dashboardCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    return SizedBox(
      width: 160,
      height: 125,

      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Icon(icon),

              const SizedBox(height: 6),

              Text(title),

              const SizedBox(height: 4),

              Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================
// PRODUCTS
// =====================================================

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() =>
      _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  @override
  Widget build(BuildContext context) {
    final products = Store.instance.products;

    if (products.isEmpty) {
      return const Center(
        child: Text(
          'No products added yet',
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: products.length,

      itemBuilder: (context, index) {
        final product = products[index];

        final name =
            product['name']?.toString() ?? '';

        final qty =
            _toInt(product['qty']);

        final price =
            _toDouble(product['price']);

        final low =
            _toInt(product['low']);

        String status;

        if (qty <= 0) {
          status = 'NIL';
        } else if (qty <= low) {
          status = 'LOW';
        } else {
          status = 'OK';
        }

        return Card(
          child: ListTile(
            leading: const Icon(
              Icons.inventory_2,
            ),

            title: Text(name),

            subtitle: Text(
              'Sale: ₹${price.toStringAsFixed(2)}'
              '  |  Stock: $qty',
            ),

            trailing: Chip(
              label: Text(status),
            ),
          ),
        );
      },
    );
  }
}

// =====================================================
// CUSTOMERS
// =====================================================

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() =>
      _CustomersPageState();
}

class _CustomersPageState
    extends State<CustomersPage> {
  @override
  Widget build(BuildContext context) {
    final customers =
        Store.instance.customers;

    if (customers.isEmpty) {
      return const Center(
        child: Text(
          'No customers added yet',
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: customers.length,

      itemBuilder: (context, index) {
        final customer = customers[index];

        final name =
            customer['name']?.toString() ?? '';

        final phone =
            customer['phone']?.toString() ?? '';

        final balance =
            _toDouble(customer['balance']);

        return Card(
          child: ListTile(
            leading: const Icon(
              Icons.person,
            ),

            title: Text(name),

            subtitle: Text(phone),

            trailing: Text(
              '₹${balance.toStringAsFixed(2)}',
            ),
          ),
        );
      },
    );
  }
}

// =====================================================
// BILLS
// =====================================================

class BillsPage extends StatefulWidget {
  const BillsPage({super.key});

  @override
  State<BillsPage> createState() =>
      _BillsPageState();
}

class _BillsPageState
    extends State<BillsPage> {

  @override
  Widget build(BuildContext context) {
    final bills =
        Store.instance.bills.reversed.toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),

          child: SizedBox(
            width: double.infinity,

            child: FilledButton.icon(
              onPressed: _newBill,

              icon: const Icon(
               
