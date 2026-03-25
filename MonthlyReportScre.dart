import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MonthlyReportPage extends StatefulWidget {
  const MonthlyReportPage({super.key});

  @override
  State<MonthlyReportPage> createState() => _MonthlyReportPageState();
}

class _MonthlyReportPageState extends State<MonthlyReportPage> {
  DateTime selectedMonth = DateTime.now();

  /// 📅 CUSTOM MONTH & YEAR PICKER (Only Months, No Days)
  Future<void> _selectMonth(BuildContext context) async {
    int tempYear = selectedMonth.year;
    int tempMonth = selectedMonth.month;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Select Month & Year", textAlign: TextAlign.center),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, size: 18),
                        onPressed: () => setDialogState(() => tempYear--),
                      ),
                      Text("$tempYear", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 18),
                        onPressed: () => setDialogState(() => tempYear++),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: List.generate(12, (index) {
                      final monthDate = DateTime(0, index + 1);
                      final monthName = DateFormat('MMM').format(monthDate);
                      final isSelected = tempMonth == index + 1;
                      return ChoiceChip(
                        label: SizedBox(width: 45, child: Center(child: Text(monthName))),
                        selected: isSelected,
                        selectedColor: Colors.blueAccent,
                        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                        onSelected: (val) => setDialogState(() => tempMonth = index + 1),
                      );
                    }),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                  onPressed: () {
                    setState(() => selectedMonth = DateTime(tempYear, tempMonth, 1));
                    Navigator.pop(context);
                  },
                  child: const Text("CONFIRM", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Logic to calculate the start and end of the selected month
    final start = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final end = DateTime(selectedMonth.year, selectedMonth.month + 1, 1);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        title: const Text("MONTHLY ANALYTICS", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: Column(
        children: [
          /// 📅 ACTIVE MONTH SELECTOR
          _buildMonthHeader(),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bills')
                  .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
                  .where('createdAt', isLessThan: Timestamp.fromDate(end))
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return _buildEmptyState();
                }

                // Data Aggregation
                double totalRevenue = 0;
                int paidCount = 0;
                int unpaidCount = 0;
                final Map<String, double> customerMap = {};

                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final double amt = (data['total'] ?? 0).toDouble();
                  totalRevenue += amt;

                  if (data['paid'] ?? false) paidCount++; else unpaidCount++;

                  // Safety check for Customer Name
                  String cName = data['customerName']?.toString().trim() ?? 'Unknown';
                  if (cName.isEmpty) cName = 'Unknown';

                  customerMap[cName] = (customerMap[cName] ?? 0) + amt;
                }

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    const SizedBox(height: 10),

                    /// 📊 STATS CARDS
                    Row(
                      children: [
                        _buildStatCard("Total Revenue", "RS $totalRevenue", Colors.blue, Icons.account_balance_wallet_rounded),
                        _buildStatCard("Total Bills", "${docs.length}", Colors.orange, Icons.inventory_2_rounded),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildStatCard("Paid Bills", "$paidCount", Colors.green, Icons.verified_rounded),
                        _buildStatCard("Pending", "$unpaidCount", Colors.redAccent, Icons.pending_actions_rounded),
                      ],
                    ),

                    const SizedBox(height: 30),
                    const Text("TOP CUSTOMERS",
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1.5)),
                    const SizedBox(height: 12),

                    /// 👥 CUSTOMER LIST
                    ...customerMap.entries.map((e) => _buildCustomerRow(e.key, e.value)),

                    const SizedBox(height: 40),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET COMPONENTS ---

  Widget _buildMonthHeader() {
    return GestureDetector(
      onTap: () => _selectMonth(context),
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, color: Colors.blueAccent, size: 20),
            const SizedBox(width: 15),
            Text(
              DateFormat('MMMM yyyy').format(selectedMonth).toUpperCase(),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1),
            ),
            const Spacer(),
            const Icon(Icons.tune_rounded, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(5),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 15),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerRow(String name, double amount) {
    // SAFETY FIX: Prevent RangeError by checking if name is empty before accessing name[0]
    String displayInitial = name.isNotEmpty ? name[0].toUpperCase() : "?";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: Colors.blueAccent.withOpacity(0.1),
          child: Text(displayInitial, style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: const Text("Customer Revenue", style: TextStyle(fontSize: 11)),
        trailing: Text(
          "RS ${amount.toStringAsFixed(0)}",
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insert_chart_outlined_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text("No data found for ${DateFormat('MMMM').format(selectedMonth)}",
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}