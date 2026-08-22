import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() {
  runApp(const SainiApp());
}

// ================= STORE =================

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
    if (data == null || data.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(data);

    if (decoded is! List) {
      return [];
    }

    return decoded
        .map<Map<String, dynamic>>(
          (e) => Map<String, dynamic>.from(e as Map),
        )
        .toList();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('products', jsonEncode(products));
    await prefs.setString('customers', jsonEncode(customers));
    await prefs.setString('bills', jsonEncode(bills));
    await prefs.setInt('billNo', billNo);
  }
}

// ================= APP =================

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

// ================= HOME =================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;

  final pages = const [
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
              : null,

      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          setState(() {
            index = i;
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

  // ================= ADD PRODUCT =================

  Future<void> _addProduct() async {
    final name = TextEditingController();
    final qty = TextEditingController();
    final price = TextEditingController();
    final low = TextEditingController(text: '2');

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Add Product'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'Product name',
                ),
              ),
              TextField(
                controller: qty,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Opening stock',
                ),
              ),
              TextField(
                controller: price,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Sale price',
                ),
              ),
              TextField(
                controller: low,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Low stock limit',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (ok == true && name.text.trim().isNotEmpty) {
      Store.instance.products.add({
        'name': name.text.trim(),
        'qty': int.tryParse(qty.text) ?? 0,
        'price': double.tryParse(price.text) ?? 0,
        'low': int.tryParse(low.text) ?? 2,
      });

      await Store.instance.save();

      if (mounted) {
        setState(() {});
      }
    }
  }

  // ================= ADD CUSTOMER =================

  Future<void> _addCustomer() async {
    final name = TextEditingController();
    final phone = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Add Customer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'Customer / Party name',
                ),
              ),
              TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile number',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (ok == true && name.text.trim().isNotEmpty) {
      Store.instance.customers.add({
        'name': name.text.trim(),
        'phone': phone.text.trim(),
        'balance': 0.0,
      });

      await Store.instance.save();

      if (mounted) {
        setState(() {});
      }
    }
  }
}

// ================= DASHBOARD =================

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Store.instance;

    final low = s.products.where((p) {
      final qty = (p['qty'] ?? 0) as num;
      final limit = (p['low'] ?? 2) as num;

      return qty > 0 && qty <= limit;
    }).length;

    final nil = s.products.where((p) {
      final qty = (p['qty'] ?? 0) as num;
      return qty <= 0;
    }).length;

    final today = DateFormat('dd-MM-yyyy').format(DateTime.now());

    double sales = 0;

    for (final bill in s.bills) {
      if (bill['date'] == today) {
        sales += (bill['total'] ?? 0).toDouble();
      }
    }

    return RefreshIndicator(
      onRefresh: s.save,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Welcome to Saini Info Solutions',
            style: Theme.of(context).textTheme.headlineSmall,
          ),

          const SizedBox(height: 16),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _card(
                context,
                'Products',
                s.products.length,
                Icons.inventory_2,
              ),
              _card(
                context,
                'Low Stock',
                low,
                Icons.warning,
              ),
              _card(
                context,
                'Nil Stock',
                nil,
                Icons.remove_shopping_cart,
              ),
              _card(
                context,
                'Customers',
                s.customers.length,
                Icons.people,
              ),
              _card(
                context,
                "Today's Sales",
                '₹${sales.toStringAsFixed(2)}',
                Icons.currency_rupee,
              ),
              _card(
                context,
                'Bills',
                s.bills.length,
                Icons.receipt_long,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _card(
    BuildContext context,
    String title,
    dynamic value,
    IconData icon,
  ) {
    return SizedBox(
      width: 160,
      height: 120,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon),
              Text(title),
              Text(
                '$value',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================= PRODUCTS =================

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  @override
  Widget build(BuildContext context) {
    final products = Store.instance.products;

    if (products.isEmpty) {
      return const Center(
        child: Text('No products added'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: products.length,
      itemBuilder: (context, i) {
        final p = products[i];

        final int qty = (p['qty'] ?? 0) as int;
        final int low = (p['low'] ?? 2) as int;

        return Card(
          child: ListTile(
            leading: const Icon(Icons.inventory_2),
            title: Text('${p['name']}'),
            subtitle: Text(
              'Sale: ₹${p['price']}  |  Stock: $qty',
            ),
            trailing: Chip(
              label: Text(
                qty <= 0
                    ? 'NIL'
                    : qty <= low
                        ? 'LOW'
                        : 'OK',
              ),
            ),
          ),
        );
      },
    );
  }
}

// ================= CUSTOMERS =================

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  @override
  Widget build(BuildContext context) {
    final customers = Store.instance.customers;

    if (customers.isEmpty) {
      return const Center(
        child: Text('No customers added'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: customers.length,
      itemBuilder: (context, i) {
        final x = customers[i];

        return Card(
          child: ListTile(
            leading: const Icon(Icons.person),
            title: Text('${x['name']}'),
            subtitle: Text('${x['phone'] ?? ''}'),
            trailing: Text(
              '₹${x['balance'] ?? 0}',
            ),
          ),
        );
      },
    );
  }
}

// ================= BILLS =================

class BillsPage extends StatefulWidget {
  const BillsPage({super.key});

  @override
  State<BillsPage> createState() => _BillsPageState();
}

class _BillsPageState extends State<BillsPage> {
  @override
  Widget build(BuildContext context) {
    final bills = Store.instance.bills.reversed.toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: _newBill,
            icon: const Icon(Icons.add),
            label: const Text('New Sale Bill'),
          ),
        ),

        Expanded(
          child: bills.isEmpty
              ? const Center(
                  child: Text('No bills yet'),
                )
              : ListView.builder(
                  itemCount: bills.length,
                  itemBuilder: (context, i) {
                    final b = bills[i];

                    return ListTile(
                      leading: const Icon(Icons.receipt),
                      title: Text(
                        'Bill #${b['no']} - ${b['customer']}',
                      ),
                      subtitle: Text('${b['date']}'),
                      trailing: Text(
                        '₹${b['total']}',
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ================= NEW BILL =================

  Future<void> _newBill() async {
    final s = Store.instance;

    if (s.products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pehle product add karein'),
        ),
      );
      return;
    }

    String customer = 'Cash Sale';

    final selected = <String>{};

    final customerNames = <String>[
      'Cash Sale',
      ...s.customers.map(
        (e) => '${e['name']}',
      ),
    ];

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(
                'New Bill #${s.billNo}',
              ),

              content: SizedBox(
                width: 360,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: customer,
                        items: customerNames.map((name) {
                          return DropdownMenuItem<String>(
                            value: name,
                            child: Text(name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              customer = value;
                            });
                          }
                        },
                        decoration: const InputDecoration(
                          labelText: 'Customer',
                        ),
                      ),

                      const SizedBox(height: 10),

                      ...s.products.map(
                        (p) {
                          final name = '${p['name']}';

                          return CheckboxListTile(
                            value: selected.contains(name),
                            onChanged: (checked) {
                              setDialogState(() {
                                if (checked == true) {
                                  selected.add(name);
                                } else {
                                  selected.remove(name);
                                }
                              });
                            },
                            title: Text(name),
                            subtitle: Text(
                              '₹${p['price']} | Stock ${p['qty']}',
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  child: const Text('Cancel'),
                ),

                FilledButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      selected.isNotEmpty,
                    );
                  },
                  child: const Text('Save Bill'),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok != true || selected.isEmpty) {
      return;
    }

    double total = 0;

    final List<Map<String, dynamic>> billItems = [];

    for (final name in selected) {
      final product = s.products.firstWhere(
        (x) => '${x['name']}' == name,
      );

      final int qty = (product['qty'] ?? 0) as int;

      if (qty > 0) {
        product['qty'] = qty - 1;

        final double price =
            (product['price'] ?? 0).toDouble();

        total += price;

        billItems.add({
          'name': name,
          'price': price,
          'qty': 1,
        });
      }
    }

    if (billItems.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selected products ka stock available nahi hai'),
          ),
        );
      }
      return;
    }

    final date =
        DateFormat('dd-MM-yyyy').format(DateTime.now());

    final bill = {
      'no': s.billNo,
      'date': date,
      'customer': customer,
      'total': total,
      'items': billItems,
    };

    s.billNo++;

    s.bills.add(bill);

    await s.save();

    if (mounted) {
      setState(() {});
    }

    await _printBill(bill);
  }

  // ================= PRINT BILL =================

  Future<void> _printBill(
    Map<String, dynamic> bill,
  ) async {
    final doc = pw.Document();

    final items =
        List<Map<String, dynamic>>.from(
      (bill['items'] as List).map(
        (e) => Map<String, dynamic>.from(e),
      ),
    );

    doc.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment:
                pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'SAINI INFO SOLUTIONS',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(height: 8),

              pw.Text(
                'Bill No: ${bill['no']}',
              ),

              pw.Text(
                'Date: ${bill['date']}',
              ),

              pw.Text(
                'Customer: ${bill['customer']}',
              ),

              pw.SizedBox(height: 15),

              pw.Divider(),

              ...items.map(
                (item) {
                  return pw.Padding(
                    padding:
                        const pw.EdgeInsets.symmetric(
                      vertical: 4,
                    ),
                    child: pw.Row(
                      mainAxisAlignment:
                          pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          '${item['name']} x ${item['qty']}',
                        ),
                        pw.Text(
                          'Rs. ${item['price']}',
                        ),
                      ],
                    ),
                  );
                },
              ),

              pw.Divider(),

              pw.Text(
                'TOTAL: Rs. ${bill['total']}',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async {
        return doc.save();
      },
    );
  }
}
