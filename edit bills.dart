import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditBillScreen extends StatefulWidget {
  const EditBillScreen({super.key});

  @override
  State<EditBillScreen> createState() => _EditBillScreenState();
}

class _EditBillScreenState extends State<EditBillScreen> {
  final _formKey = GlobalKey<FormState>();
  late String docId;
  late Map<String, dynamic> bill;

  final TextEditingController customerNameController = TextEditingController();
  final TextEditingController customerMobileController =
  TextEditingController();
  final TextEditingController vehicleNameController = TextEditingController();
  final TextEditingController vehicleNumberController = TextEditingController();
  final TextEditingController customDetailController = TextEditingController();
  final TextEditingController newServiceController = TextEditingController();

  final List<Map<String, dynamic>> servicesList = [
    {'name': 'Oil Change', 'price': 500},
    {'name': 'Wheel Alignment', 'price': 800},
    {'name': 'Brake Check', 'price': 300},
    {'name': 'Battery Check', 'price': 700},
  ];

  List<Map<String, dynamic>> selectedServices = [];
  Map<String, dynamic>? dropdownValue;

  double get totalAmount =>
      selectedServices.fold(0, (sum, item) => sum + item['price']);

  final CollectionReference billsCollection =
  FirebaseFirestore.instance.collection('bills');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
    ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    docId = args['docId'];
    bill = args['data'];

    customerNameController.text = bill['customerName'];
    customerMobileController.text = bill['customerMobile'];
    vehicleNameController.text = bill['vehicleName'];
    vehicleNumberController.text = bill['vehicleNumber'];
    customDetailController.text = bill['customDetail'];
    selectedServices = List<Map<String, dynamic>>.from(bill['services']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Bill')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    TextFormField(
                      controller: customerNameController,
                      decoration: InputDecoration(
                        labelText: 'Customer Name',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) =>
                      value!.isEmpty ? 'Enter customer name' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: customerMobileController,
                      decoration: InputDecoration(
                        labelText: 'Mobile Number',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 10,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter mobile number';
                        } else if (value.length != 10) {
                          return 'Mobile number must be 10 digits';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: vehicleNameController,
                      decoration: InputDecoration(
                        labelText: 'Vehicle Name',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) =>
                      value!.isEmpty ? 'Enter vehicle name' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: vehicleNumberController,
                      decoration: InputDecoration(
                        labelText: 'Vehicle Number',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) =>
                      value!.isEmpty ? 'Enter vehicle number' : null,
                    ),
                    const SizedBox(height: 20),

                    // Dropdown with ability to add new service
                    DropdownButtonFormField<Map<String, dynamic>>(
                      value: dropdownValue,
                      decoration: InputDecoration(
                        labelText: 'Select Service',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      items: servicesList.map((service) {
                        return DropdownMenuItem<Map<String, dynamic>>(
                          value: service,
                          child:
                          Text('${service['name']} - RS ${service['price']}'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null && !selectedServices.contains(value)) {
                          setState(() {
                            selectedServices.add(value);
                            dropdownValue = null; // reset selection to avoid black screen
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 5),

                    // TextField to add custom service
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: newServiceController,
                            decoration: InputDecoration(
                              labelText: 'Add Custom Service (RS)',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 5),
                        ElevatedButton(
                          onPressed: () {
                            final name = newServiceController.text.trim();
                            if (name.isNotEmpty) {
                              final service = {
                                'name': name,
                                'price': 0, // default price 0, user can edit later
                              };
                              setState(() {
                                servicesList.add(service);
                                selectedServices.add(service);
                                newServiceController.clear();
                              });
                            }
                          },
                          child: const Text('Add'),
                        )
                      ],
                    ),

                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 5,
                      children: selectedServices.map((service) {
                        return Chip(
                          backgroundColor: Colors.indigo.shade100,
                          label: Text('${service['name']} RS ${service['price']}'),
                          deleteIcon:
                          const Icon(Icons.remove_circle, color: Colors.red),
                          onDeleted: () {
                            setState(() {
                              selectedServices.remove(service);
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: customDetailController,
                      decoration: InputDecoration(
                        labelText: 'Custom Detail',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),

              // Total & update button fixed at bottom
              Column(
                children: [
                  Text(
                    'Total: RS $totalAmount',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.indigo,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        await billsCollection.doc(docId).update({
                          'customerName': customerNameController.text,
                          'customerMobile': customerMobileController.text,
                          'vehicleName': vehicleNameController.text,
                          'vehicleNumber': vehicleNumberController.text,
                          'services': selectedServices,
                          'customDetail': customDetailController.text,
                          'total': totalAmount,
                        });
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Update Bill', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
