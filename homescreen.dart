import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kgarage/billscreen.dart';
import 'package:kgarage/pdfsharescreen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String filter = 'all';

  @override
  Widget build(BuildContext context) {
    final billsRef = FirebaseFirestore.instance.collection('bills');
    Query query = billsRef.orderBy('createdAt', descending: true);

    if (filter == 'paid') {
      query = query.where('paid', isEqualTo: true);
    } else if (filter == 'unpaid') {
      query = query.where('paid', isEqualTo: false);
    }

    return Scaffold(
        backgroundColor: const Color(0xFFF0F3F7), // Neutral modern background
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,

        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Image.asset(
            'assets/images/1.png',
            height: 32,

          ),
        ),

        title: const Text(
          'CAR WORKSHOP',
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            fontSize: 18,
          ),
        ),

        actions: [
          _buildFilterChip(),
          IconButton(
            icon: const Icon(Icons.power_settings_new_rounded,
                color: Colors.redAccent),
            onPressed: () => _showLogoutDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),


      floatingActionButton: FloatingActionButton.extended(
          backgroundColor: Colors.white, // Deep black for premium look
          elevation: 4,
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BillScreen())),
          label: const Text("CREATE BILLS", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1,color: Colors.black)),
          icon: const Icon(Icons.add_rounded),
        ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bills')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          // Get all docs
          final allDocs = snapshot.data!.docs;

          // Apply filter manually (handles missing 'paid' field)
          final filteredDocs = allDocs.where((doc) {
            final bill = doc.data() as Map<String, dynamic>;
            final paid = bill['paid'] ?? false; // default to false if missing
            if (filter == 'all') return true;
            if (filter == 'paid') return paid;
            if (filter == 'unpaid') return !paid;
            return true;
          }).toList();

          if (filteredDocs.isEmpty) return _buildEmptyState();

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: filteredDocs.length,
            itemBuilder: (context, index) {
              final doc = filteredDocs[index];
              final bill = doc.data() as Map<String, dynamic>;
              final docId = doc.id;
              final bool isPaid = bill['paid'] ?? false;

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10))
                  ],
                ),
                child: Column(
                  children: [
                    // TOP BAR: Status & Date
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [_statusBadge(isPaid, docId, billsRef)]),
                    ),

                    // MIDDLE SECTION: Customer & Price
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                      title: Text(bill['customerName'] ?? 'Guest',
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1A1A1A))),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                            "📞 ${bill['customerMobile']}\n🚗 ${bill['vehicleName']} | ${bill['vehicleNumber']}",
                            style: TextStyle(
                                color: Colors.blueGrey.shade600,
                                height: 1.5,
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                      ),
                      trailing: Text("RS ${bill['total']}",
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.blueAccent)),
                    ),

                    const SizedBox(height: 10),
                    const Divider(indent: 20, endIndent: 20),

                    // BOTTOM ACTIONS
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _modernActionBtn(
                              Icons.print_rounded, "Share PDF", Colors.redAccent,
                                  () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => PdfShareScreen(bill: bill)));
                              }),
                          _modernActionBtn(Icons.edit_square, "Edit", Colors.indigo,
                                  () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            BillScreen(billData: bill, docId: docId)));
                              }),
                          _modernActionBtn(Icons.delete_sweep_rounded, "Delete",
                              Colors.grey.shade400, () =>
                                  _showDeleteDialog(context, docId, billsRef)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),

    );

            }

            // --- REFINED LOGIC COMPONENTS (Restored your specific Dialogs) ---

            void _showLogoutDialog(BuildContext context) async {
    final confirm = await showDialog<bool>(
    context: context,
    builder: (_) => _styledDialog(
    title: 'Logout',
    content: 'Are you sure you want to logout?',
    confirmText: 'Logout',
    isDestructive: true,
    ),
    );
    if (confirm == true) await FirebaseAuth.instance.signOut();
    }

        void _showDeleteDialog(BuildContext context, String docId, CollectionReference ref) async {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => _styledDialog(
          title: 'Delete Bill',
          content: 'Are you sure?',
          confirmText: 'Delete',
          isDestructive: true,
        ),
      );
      if (confirm == true) await ref.doc(docId).delete();
    }

    Widget _statusBadge(bool isPaid, String docId, CollectionReference ref) {
      return GestureDetector(
        onTap: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (_) => _styledDialog(
              title: 'Change Payment Status',
              content: isPaid ? 'Mark this bill as UNPAID?' : 'Mark this bill as PAID?',
              confirmText: 'Yes',
            ),
          );
          if (confirm == true) await ref.doc(docId).update({'paid': !isPaid});
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isPaid ? Colors.green.shade50 : Colors.orange.shade50,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: isPaid ? Colors.green.shade200 : Colors.orange.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, size: 8, color: isPaid ? Colors.green : Colors.orange),
              const SizedBox(width: 6),
              Text(isPaid ? 'PAID' : 'UNPAID',
                  style: TextStyle(color: isPaid ? Colors.green.shade800 : Colors.orange.shade800, fontWeight: FontWeight.bold, fontSize: 11)),
            ],
          ),
        ),
      );
    }


    Widget _styledDialog({required String title, required String content, required String confirmText, bool isDestructive = false}) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive ? Colors.red : Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText, style: const TextStyle(color: Colors.white)),
          ),
        ],
      );
    }

    Widget _buildFilterChip() {
      return PopupMenuButton<String>(
        offset: const Offset(0, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
          child: const Icon(Icons.filter_list_rounded, color: Colors.black, size: 20),
        ),
        onSelected: (value) => setState(() => filter = value),
        itemBuilder: (_) => [
          _popItem('all', 'All Transactions', Icons.receipt_long_rounded),
          _popItem('paid', 'Paid Only', Icons.check_circle_rounded),
          _popItem('unpaid', 'Unpaid Only', Icons.error_outline_rounded),
        ],
      );
    }

    PopupMenuItem<String> _popItem(String val, String label, IconData icon) {
      return PopupMenuItem(value: val, child: Row(children: [Icon(icon, size: 18), const SizedBox(width: 10), Text(label)]));
    }

    Widget _modernActionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            ],
          ),
        ),
      );
    }

    Widget _buildEmptyState() {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open_rounded, size: 100, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text("No invoices recorded yet.", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }
  }