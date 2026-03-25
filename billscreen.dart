import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BillScreen extends StatefulWidget {
  final Map<String, dynamic>? billData;
  final String? docId;
  final Map<String, dynamic>? jobCardData;

  const BillScreen({super.key, this.billData, this.docId, this.jobCardData});

  @override
  State<BillScreen> createState() => _BillScreenState();
}

class _BillScreenState extends State<BillScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  final mobileCtrl = TextEditingController();
  final vehicleNameCtrl = TextEditingController();
  final vehicleNoCtrl =  TextEditingController();
  final customNoteCtrl = TextEditingController();

  List<Map<String, dynamic>> services = [];
  List<Map<String, dynamic>> dropdownServices = [];
  Map<String, dynamic>? selectedService;

  final servicePriceCtrl = TextEditingController();
  final customServiceNameCtrl = TextEditingController();
  final customServicePriceCtrl = TextEditingController();

  int get total => services.fold(0, (sum, item) => sum + (item['price'] as int));

  @override
  void initState() {
    super.initState();
    fetchServices();

    if (widget.billData != null) {
      final b = widget.billData!;
      nameCtrl.text = (b['customerName'] ?? '').toString();
      mobileCtrl.text = (b['customerMobile'] ?? '').toString();
      vehicleNameCtrl.text = (b['vehicleName'] ?? '').toString();
      vehicleNoCtrl.text = (b['vehicleNumber'] ?? '').toString();
      customNoteCtrl.text = (b['customDetail'] ?? '').toString();

      services = List<Map<String, dynamic>>.from(
        (b['services'] ?? []).map((s) => {
          'name': (s['name'] ?? '').toString(),
          'price': s['price'] ?? 0,
        }),
      );
    }
    else if (widget.jobCardData != null) {
      final j = widget.jobCardData!;
      nameCtrl.text = (j['customerName'] ?? '').toString();
      mobileCtrl.text = (j['customerMobile'] ?? '').toString();

      services = List<Map<String, dynamic>>.from(
        (j['services'] ?? []).map((s) {
          if (s is Map) {
            return {
              'name': (s['name'] ?? '').toString(),
              'price': s['price'] ?? 0,
            };
          } else {
            return {
              'name': s.toString(),
              'price': 0,
            };
          }
        }),
      );
    }
  }

  Future<void> fetchServices() async {
    final snap = await FirebaseFirestore.instance
        .collection('services')
        .orderBy('name')
        .get();

    setState(() {
      dropdownServices = snap.docs
          .map((d) => {'name': d['name'], 'price': d['price']})
          .toList();
    });
  }

  Future<void> saveBill() async {
    if (!_formKey.currentState!.validate()) return;

    // 🛠 RESTORED YOUR ORIGINAL LOGIC
    final createdByName = _getCreatorName();

    final data = {
      'customerName': nameCtrl.text.trim(),
      'customerMobile': mobileCtrl.text.trim(),
      'vehicleName': vehicleNameCtrl.text.trim(),
      'vehicleNumber': vehicleNoCtrl.text.trim(),
      'services': services,
      'customDetail': customNoteCtrl.text.trim(),
      'total': total,
      'createdAt': FieldValue.serverTimestamp(),
      'createdByName': createdByName,
    };

    final ref = FirebaseFirestore.instance.collection('bills');
    if (widget.docId == null) {
      await ref.add(data);
    } else {
      await ref.doc(widget.docId).update(data);
    }
    Navigator.pop(context);
  }

  // 🛠 RESTORED: This is your exact original creator name logic
  String _getCreatorName() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return 'User';

    if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
      return user.displayName!;
    }

    if (user.email != null) {
      return user.email!.split('@').first;
    }

    return 'User';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(widget.docId == null ? 'CREATE BILL' : 'EDIT BILL',
            style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSectionHeader(Icons.person_pin_rounded, "CLIENT INFO"),
            _buildField(nameCtrl, 'Full Name', Icons.person_outline),
            const SizedBox(height: 12),
            _buildField(mobileCtrl, 'Phone Number', Icons.phone_android_outlined,
                keyboard: TextInputType.number,
                formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)]),

            const SizedBox(height: 25),
            _buildSectionHeader(Icons.directions_car_filled_rounded, "VEHICLE DETAILS"),
            Row(
              children: [
                Expanded(child: _buildField(vehicleNameCtrl, 'Vehicle Name', Icons.minor_crash_outlined)),
                const SizedBox(width: 12),
                Expanded(child: _buildField(vehicleNoCtrl, 'Vehicle No.', Icons.tag_rounded)),
              ],
            ),

            const SizedBox(height: 23),
            _buildSectionHeader(Icons.handyman_rounded, "SERVICES & LABOR"),
            DropdownButtonFormField<Map<String, dynamic>>(
              decoration: _inputDeco('Select a Service', Icons.settings_outlined,),
              items: dropdownServices.map((s) => DropdownMenuItem(
                value: s,
                child: Text('${s['name']} (RS ${s['price']})'),
              )).toList(),
              onChanged: (val) {
                setState(() {
                  selectedService = val;
                  servicePriceCtrl.text = val!['price'].toString();
                });
              },
            ),

            if (selectedService != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildField(servicePriceCtrl, 'Service Price', Icons.currency_rupee, keyboard: TextInputType.number)),
                  const SizedBox(width: 10),
                  _buildQuickAdd(() {
                    setState(() {
                      services.add({
                        'name': selectedService!['name'],
                        'price': int.tryParse(servicePriceCtrl.text) ?? 0,
                      });
                      selectedService = null;
                      servicePriceCtrl.clear();
                    });
                  }),
                ],
              ),
            ],

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text("OR CUSTOM", style: TextStyle(fontSize: 10, color: Colors.grey))),
                  Expanded(child: Divider()),
                ],
              ),
            ),

            _buildField(customServiceNameCtrl, 'Custom Service Name', Icons.edit_note_rounded, isRequired: false),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildField(customServicePriceCtrl, 'Price', Icons.payments_outlined, keyboard: TextInputType.number, isRequired: false)),
                const SizedBox(width: 10),
                _buildQuickAdd(() {
                  if (customServiceNameCtrl.text.isEmpty || customServicePriceCtrl.text.isEmpty) return;
                  setState(() {
                    services.add({
                      'name': customServiceNameCtrl.text.trim(),
                      'price': int.tryParse(customServicePriceCtrl.text) ?? 0,
                    });
                    customServiceNameCtrl.clear();
                    customServicePriceCtrl.clear();
                  });
                }),
              ],
            ),

            const SizedBox(height: 30),

            if (services.isNotEmpty) ...[
              _buildSectionHeader(Icons.receipt_long_rounded, "BILL SUMMARY"),
              ...services.asMap().entries.map((entry) {
                final idx = entry.key;
                final s = entry.value;

                return Container(
                  key: ValueKey('service_row_$idx'),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    title: Text(s['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    trailing: SizedBox(
                      width: 130,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextFormField(
                              key: ValueKey('price_field_$idx'),
                              initialValue: s['price'].toString(),
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
                              decoration: const InputDecoration(border: InputBorder.none, prefixText: 'RS '),
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              onChanged: (val) {
                                s['price'] = int.tryParse(val) ?? 0;
                                setState(() {});
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                            onPressed: () => setState(() => services.removeAt(idx)),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],

            const SizedBox(height: 20),
            _buildField(customNoteCtrl, 'Custom Notes', Icons.note_alt_outlined, maxLines: 2, isRequired: false),

            const SizedBox(height: 30),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)]),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("TOTAL PAYABLE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  Text("RS $total", style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                ],
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                onPressed: saveBill,
                icon: const Icon(Icons.cloud_done_rounded),
                label: const Text('SAVE INVOICE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blueAccent),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1.2)),
        ],
      ),
    );
  }

  Widget _buildQuickAdd(VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(12)),
      child: IconButton(onPressed: onTap, icon: const Icon(Icons.add, color: Colors.white)),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? keyboard, List<TextInputFormatter>? formatters, int maxLines = 1, bool isRequired = true}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      inputFormatters: formatters,
      maxLines: maxLines,
      decoration: _inputDeco(label, icon),
      validator: isRequired ? (v) => v!.isEmpty ? 'Required' : null : null,
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: Colors.blueAccent.withOpacity(0.7)),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5), borderRadius: BorderRadius.circular(12)),
      errorBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.redAccent), borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.all(16),
    );
  }
}