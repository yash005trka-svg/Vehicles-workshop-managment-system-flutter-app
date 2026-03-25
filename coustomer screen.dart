import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'coustemerbillhistory.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  String search = '';

  @override
  Widget build(BuildContext context) {
    final billsRef = FirebaseFirestore.instance.collection('bills');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'CUSTOMERS',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          /// 🔍 SEARCH
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Search by mobile',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => search = v),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: billsRef.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No customers found"));
                }

                final docs = snapshot.data!.docs;

                /// 🧠 GROUP BY MOBILE
                final Map<String, Map<String, dynamic>> customers = {};

                for (var d in docs) {
                  final data = d.data() as Map<String, dynamic>;
                  final mobile = (data['customerMobile'] ?? '').toString();
                  if (mobile.isEmpty) continue;

                  final total = (data['total'] ?? 0).toDouble();

                  if (customers.containsKey(mobile)) {
                    customers[mobile]!['total'] += total;
                    customers[mobile]!['count'] += 1;
                  } else {
                    customers[mobile] = {
                      'name': data['customerName'] ?? 'Unknown',
                      'mobile': mobile,
                      'total': total,
                      'count': 1,
                    };
                  }
                }

                final list = customers.values
                    .where((c) => c['mobile'].contains(search))
                    .toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final c = list[i];
                    final String name = c['name'];
                    final String letter =
                    name.isNotEmpty ? name[0].toUpperCase() : '?';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                          )
                        ],
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.withOpacity(0.1),
                          child: Text(
                            letter,
                            style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w900),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("📞 ${c['mobile']}"),
                            const SizedBox(height: 4),
                            Text(
                              "${c['count']} bills • ₹${c['total'].toStringAsFixed(0)}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            /// ➡️ VIEW BILLS
                            IconButton(
                              icon: const Icon(Icons.receipt_long),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CustomerBillsScreen(
                                      mobile: c['mobile'],
                                      name: name,
                                    ),
                                  ),
                                );
                              },
                            ),

                            /// 🗑 DELETE CUSTOMER
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              onPressed: () {
                                _confirmDelete(context, c['mobile'], name);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// ⚠️ CONFIRM DELETE
  void _confirmDelete(
      BuildContext context, String mobile, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Customer"),
        content: Text(
          "Delete ALL bills of $name?\nThis cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await _deleteCustomerBills(mobile);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  /// 🧨 DELETE ALL BILLS
  Future<void> _deleteCustomerBills(String mobile) async {
    final ref = FirebaseFirestore.instance.collection('bills');

    final snap =
    await ref.where('customerMobile', isEqualTo: mobile).get();

    final batch = FirebaseFirestore.instance.batch();

    for (var doc in snap.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}
