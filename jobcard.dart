import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'billscreen.dart';

class JobCardScreen extends StatefulWidget {
  const JobCardScreen({super.key});

  @override
  State<JobCardScreen> createState() => _JobCardScreenState();
}

class _JobCardScreenState extends State<JobCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final customerNameCtrl = TextEditingController();
  final customerPhoneCtrl = TextEditingController();

  // Stores full service objects {name: string, price: int}
  List<Map<String, dynamic>> availableServicesData = [];
  List<String> availableServicesNames = [];

  // Stores selection: [{name: "Oil Change", price: 500}]
  // We keep the price here in code, but we don't show it on screen.
  List<Map<String, dynamic>> selectedServices = [];

  List<TextEditingController> customServiceCtrls = List.generate(2, (_) => TextEditingController());

  @override
  void initState() {
    super.initState();
    fetchAvailableServices();
  }

  Future<void> fetchAvailableServices() async {
    final snap = await FirebaseFirestore.instance
        .collection('services')
        .orderBy('name')
        .get();

    setState(() {
      availableServicesData = snap.docs.map((d) {
        final data = d.data();
        return {
          'name': data['name'] as String,
          'price': (data['price'] ?? 0) as int,
        };
      }).toList();
      availableServicesNames = availableServicesData.map((e) => e['name'] as String).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        elevation: 0,
        title: const Text('Service Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: _buildFormCard(),
            ),
            _sectionLabel("Recent Job Cards"),
            _buildHorizontalList(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(25, 10, 25, 40),
      decoration: const BoxDecoration(
        color: Colors.indigo,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Workshop Management", style: TextStyle(color: Colors.white.withOpacity(0.7))),
          const Text("Create Job Card", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _sectionHeader("Customer Information", Icons.person_add_alt_1),
              TextFormField(
                controller: customerNameCtrl,
                validator: (v) => v!.isEmpty ? 'Name required' : null,
                decoration: _input('Full Name', Icons.person_outline),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: customerPhoneCtrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                validator: (v) => (v == null || v.length < 10) ? 'Valid 10-digit mobile required' : null,
                decoration: _input('Mobile Number', Icons.phone_android),
              ),

              const SizedBox(height: 24),
              _sectionHeader("Select Services", Icons.plumbing),

              ...List.generate(selectedServices.length + 1, (idx) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          decoration: _input('Service ${idx + 1}', Icons.settings_outlined),
                          value: idx < selectedServices.length ? selectedServices[idx]['name'] : null,
                          items: availableServicesNames.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (val) {
                            // Logic works here: we find the price
                            final serviceData = availableServicesData.firstWhere((e) => e['name'] == val);
                            setState(() {
                              if (idx < selectedServices.length) {
                                selectedServices[idx] = serviceData;
                              } else {
                                selectedServices.add(serviceData);
                              }
                            });
                          },
                        ),
                      ),
                      // ❌ PRICE DISPLAY REMOVED FROM HERE
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: Colors.indigo),
                        onPressed: () => setState(() => selectedServices.add({'name': null, 'price': 0})),
                      ),
                    ],
                  ),
                );
              }),

              _sectionHeader("Custom Requirements", Icons.edit_note),
              ...customServiceCtrls.map((ctrl) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextFormField(controller: ctrl, decoration: _input("Enter custom service...", Icons.edit_outlined)),
              )),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  onPressed: saveJobCard,
                  child: const Text('SAVE JOB CARD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalList() {
    return SizedBox(
      height: 250,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('job_cards').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("No Recent Job Cards"));

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            scrollDirection: Axis.horizontal,
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              // Services are fetched as objects but displayed only as names below
              final services = List<Map<String, dynamic>>.from(data['services'] ?? []);
              return _buildModernCard(data, services);
            },
          );
        },
      ),
    );
  }

  Widget _buildModernCard(Map<String, dynamic> data, List<Map<String, dynamic>> services) {
    return Container(
      width: 260,
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(child: Text(data['customerName'][0])),
            title: Text(data['customerName'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(data['customerMobile']),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 5,
                children: services.map((s) => Chip(
                  label: Text(s['name'] ?? '', style: const TextStyle(fontSize: 10)),
                  backgroundColor: Colors.indigo.withOpacity(0.05),
                )).toList(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: OutlinedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BillScreen(billData: data)),
              ),
              child: const Text("View Details"),
            ),
          )
        ],
      ),
    );
  }

  Future<void> saveJobCard() async {
    if (!_formKey.currentState!.validate()) return;

    final List<Map<String, dynamic>> finalServices = [];

    for (var s in selectedServices) {
      if (s['name'] != null) finalServices.add(s);
    }

    for (var ctrl in customServiceCtrls) {
      if (ctrl.text.isNotEmpty) {
        finalServices.add({'name': ctrl.text.trim(), 'price': 0});
      }
    }

    await FirebaseFirestore.instance.collection('job_cards').add({
      'customerName': customerNameCtrl.text.trim(),
      'customerMobile': customerPhoneCtrl.text.trim(),
      'services': finalServices, // Price is saved here!
      'createdAt': FieldValue.serverTimestamp(),
    });

    customerNameCtrl.clear();
    customerPhoneCtrl.clear();
    selectedServices.clear();
    for (var c in customServiceCtrls) { c.clear(); }
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Job Card Created!")));
  }

  Widget _sectionLabel(String t) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    child: Align(alignment: Alignment.centerLeft, child: Text(t, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
  );

  Widget _sectionHeader(String title, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 12, top: 8),
    child: Row(children: [
      Icon(icon, size: 18, color: Colors.indigo),
      const SizedBox(width: 8),
      Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo)),
    ]),
  );

  InputDecoration _input(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: Colors.indigo, size: 20),
    filled: true,
    fillColor: Colors.grey[50],
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  );
}