import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'pdfsharescreen.dart';

class CustomerBillsScreen extends StatelessWidget {
  final String mobile;
  final String name; // Added name to display in AppBar

  const CustomerBillsScreen({
    super.key,
    required this.mobile,
    required this.name
  });

  @override
  Widget build(BuildContext context) {
    final billsRef = FirebaseFirestore.instance.collection('bills');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Column(
          children: [
            Text(name.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.5)),
            Text(mobile,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal, color: Colors.grey)),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: billsRef
            .where('customerMobile', isEqualTo: mobile)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final docId = docs[index].id;
              final bill = docs[index].data() as Map<String, dynamic>;
              final bool isPaid = bill['paid'] ?? false;
              final DateTime? date = (bill['createdAt'] as Timestamp?)?.toDate();

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 10)
                    )
                  ],
                ),
                child: Column(
                  children: [
                    // TOP BAR: Status & Invoice ID
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _statusBadge(context, isPaid, docId, billsRef),
                          Text(
                            date != null ? DateFormat('dd MMM yyyy').format(date) : "",
                            style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),

                    // MIDDLE SECTION: Vehicle & Price
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                      title: Text(bill['vehicleName'] ?? "Unknown Vehicle",
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text("Vehicle No: ${bill['vehicleNumber'] ?? 'N/A'}",
                            style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                      trailing: Text("RS ${bill['total'] ?? 0}",
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.blueAccent)),
                    ),

                    const SizedBox(height: 10),
                    const Divider(indent: 20, endIndent: 20),

                    // BOTTOM ACTIONS
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 5, 10, 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _modernActionBtn(Icons.picture_as_pdf_rounded, "SHARE INVOICE", Colors.redAccent, () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => PdfShareScreen(bill: bill)),
                            );
                          }),
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

  // --- LOGIC REPLICATED FROM HOME SCREEN ---

  Widget _statusBadge(BuildContext context, bool isPaid, String docId, CollectionReference ref) {
    return GestureDetector(
      onTap: () async {
        // Restoring your exact confirmation logic
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Change Payment Status'),
            content: Text(isPaid ? 'Mark this bill as UNPAID?' : 'Mark this bill as PAID?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Yes', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent))
              ),
            ],
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

  Widget _modernActionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(12)
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
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
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("No history found for this customer.",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}