import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class WorkManagementPage extends StatefulWidget {
  @override
  _WorkManagementPageState createState() => _WorkManagementPageState();
}

class _WorkManagementPageState extends State<WorkManagementPage> {
  final TextEditingController dateController = TextEditingController();
  final TextEditingController workController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController inchargeController = TextEditingController();
  final TextEditingController selectedDateController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  DateTime selectedDate = DateTime.now();
  String selectedInChargeType = '';
  String? selectedInChargeId;
  String? selectedInChargeName;

  List<String> ownerNames = [];
  List<String> crewMemberNames = [];
  
  late QuerySnapshot ownerDetailsSnapshot;
  late QuerySnapshot crewMemberDetailsSnapshot;

  List<String> paymentOptions = ['Paid', 'Not Paid'];
  List<String> progressOptions = ['Done', 'Pending'];
  String selectedPaymentOption = 'Paid'; // Set initial value for payment dropdown
  String selectedProgressOption = 'Done'; // Set initial value for progress dropdown

  @override
  void initState() {
    super.initState();
    _fetchOwnerDetails();
    _fetchCrewMemberDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Work Management'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return _buildAddWorkDialog(context);
                  },
                );
              },
              child: Text('Add Work'),
            ),
            SizedBox(height: 20),
            _buildWorkTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkTable() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getWorkStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        } else if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text('No data available'),
          );
        } else {
          List<DocumentSnapshot> workList = snapshot.data!.docs;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              showCheckboxColumn: false,
              columns: _buildTableColumns(),
              columnSpacing: 16.0,
              rows: _buildTableRows(workList),
            ),
          );
        }
      },
    );
  }

  List<DataColumn> _buildTableColumns() {
    return [
      DataColumn(label: Text('Date')),
      DataColumn(label: Text('Work')),
      DataColumn(label: Text('Progress')),
      DataColumn(label: Text('Amount')),
      DataColumn(label: Text('Payment')),
      DataColumn(label: Text('Incharge')),
      DataColumn(label: Text('Actions')),
    ];
  }

  List<DataRow> _buildTableRows(List<DocumentSnapshot> workList) {
    return workList.map((work) {
      Timestamp timestamp = work['date'] ?? Timestamp.now();
      DateTime dateTime = timestamp.toDate();

      return DataRow(
        cells: [
          DataCell(Text(_formatDate(dateTime))),
          DataCell(Text(work['work'].toString())),
          DataCell(Text(work['progress'].toString())),
          DataCell(Text(work['amount'].toString())),
          DataCell(Text(work['payment'].toString())),
          DataCell(Text(work['incharge'].toString())),
          DataCell(
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    editWorkDialog(context, work);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    deleteWork(work);
                  },
                ),
              ],
            ),
          ),
        ],
      );
    }).toList();
  }

  String _formatDate(DateTime dateTime) {
    return DateFormat('dd-MM-yyyy').format(dateTime);
  }

  Widget _buildAddWorkDialog(BuildContext context) {
    return AlertDialog(
      title: Text('Add Work'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDateField(context),
              _buildTextField('Work', workController),
              _buildTextField('Amount', amountController),
              _buildDropdownField('Payment', paymentOptions, selectedPaymentOption),
              _buildDropdownField('Progress', progressOptions, selectedProgressOption),
              _buildInChargeSelection(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            addWork(context);
          },
          child: Text('Add'),
        ),
      ],
    );
  }

  Widget _buildDateField(BuildContext context) {
    return TextButton(
      onPressed: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2015, 8),
          lastDate: DateTime(2101),
        );
        if (picked != null && picked != selectedDate) {
          setState(() {
            selectedDate = picked;
            dateController.text = DateFormat('dd-MM-yyyy').format(selectedDate);
          });
        }
      },
      child: Text(
        'Select Date',
        style: TextStyle(color: Theme.of(context).primaryColor),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }

  Widget _buildDropdownField(String label, List<String> options, String value) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: label),
      value: value,
      items: options.map((option) {
        return DropdownMenuItem<String>(
          value: option,
          child: Text(option),
        );
      }).toList(),
      onChanged: (newValue) {
        setState(() {
          if (label == 'Payment') {
            selectedPaymentOption = newValue!;
          } else if (label == 'Progress') {
            selectedProgressOption = newValue!;
          }
        });
      },
    );
  }

  Widget _buildInChargeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Incharge:'),
        ElevatedButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return _buildOwnerDialog(context);
              },
            );
          },
          child: Text('Owner as Incharge'),
        ),
        ElevatedButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return _buildCrewMemberDialog(context);
              },
            );
          },
          child: Text('Crew Member as Incharge'),
        ),
        SizedBox(height: 8.0),
        TextFormField(
          controller: inchargeController,
          enabled: false,
          decoration: InputDecoration(labelText: 'Incharge'),
        ),
      ],
    );
  }

  Widget _buildOwnerDialog(BuildContext context) {
    return AlertDialog(
      title: Text('Select Owner'),
      content: Container(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: ownerNames.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(ownerNames[index]),
              onTap: () {
                setState(() {
                  selectedInChargeType = 'Owner';
                  selectedInChargeId = ownerDetailsSnapshot.docs[index].id;
                  selectedInChargeName = ownerNames[index];
                  inchargeController.text = selectedInChargeName!;
                });
                Navigator.pop(context);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildCrewMemberDialog(BuildContext context) {
    return AlertDialog(
      title: Text('Select Crew Member'),
      content: Container(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: crewMemberNames.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(crewMemberNames[index]),
              onTap: () {
                setState(() {
                  selectedInChargeType = 'Crew Member';
                  selectedInChargeId = crewMemberDetailsSnapshot.docs[index].id;
                  selectedInChargeName = crewMemberNames[index];
                  inchargeController.text = selectedInChargeName!;
                });
                Navigator.pop(context);
              },
            );
          },
        ),
      ),
    );
  }

  void addWork(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      if (selectedInChargeName == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select an incharge before adding work.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      final userSnapshot = await _getCurrentUser();
      final organizationId = userSnapshot.data()?['organizationId'];
      final workRef = FirebaseFirestore.instance.collection('organizations').doc(organizationId).collection('workmanagement');

      await workRef.doc(selectedInChargeId).set({
        'date': selectedDate,
        'work': workController.text,
        'amount': amountController.text,
        'payment': selectedPaymentOption,
        'progress': selectedProgressOption,
        'incharge': selectedInChargeName,
      });

      setState(() {
        dateController.clear();
        workController.clear();
        amountController.clear();
        selectedPaymentOption = 'Paid'; // Reset payment dropdown to default value
        selectedProgressOption = 'Done'; // Reset progress dropdown to default value
        inchargeController.clear();
      });

      Navigator.of(context).pop();
    }
  }

  Future<void> _fetchOwnerDetails() async {
    final userSnapshot = await _getCurrentUser();
    final organizationId = userSnapshot.data()?['organizationId'];

    ownerDetailsSnapshot = await FirebaseFirestore.instance
        .collection('organizations')
        .doc(organizationId)
        .collection('ownerdetails')
        .get();

    setState(() {
      ownerNames = ownerDetailsSnapshot.docs.map((doc) => doc['name'].toString()).toList();
    });
  }

  Future<void> _fetchCrewMemberDetails() async {
    final userSnapshot = await _getCurrentUser();
    final organizationId = userSnapshot.data()?['organizationId'];

    crewMemberDetailsSnapshot = await FirebaseFirestore.instance
        .collection('organizations')
        .doc(organizationId)
        .collection('crewmemberdetails')
        .get();

    setState(() {
      crewMemberNames = crewMemberDetailsSnapshot.docs.map((doc) => doc['name'].toString()).toList();
    });
  }

  Stream<QuerySnapshot> _getWorkStream() async* {
    final userSnapshot = await _getCurrentUser();
    final organizationId = userSnapshot.data()?['organizationId'];

    yield* FirebaseFirestore.instance
        .collection('organizations')
        .doc(organizationId)
        .collection('workmanagement')
        .snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _getCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    }
    throw Exception('User not found');
  }

  void editWorkDialog(BuildContext context, DocumentSnapshot work) {
  Timestamp timestamp = work['date'] ?? Timestamp.now();
  DateTime dateTime = timestamp.toDate();

  setState(() {
    selectedDate = dateTime;
    dateController.text = _formatDate(dateTime);
    workController.text = work['work'].toString();
    amountController.text = work['amount'].toString();
    selectedPaymentOption = work['payment'];
    selectedProgressOption = work['progress'];
    // Set the incharge values
    selectedInChargeId = work['incharge'].toString();
    inchargeController.text = selectedInChargeId!;
  });

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return _buildEditWorkDialog(context, work);
    },
  );
}


  void deleteWork(DocumentSnapshot work) async {
    final userSnapshot = await _getCurrentUser();
    final organizationId = userSnapshot.data()?['organizationId'];
    final workRef = FirebaseFirestore.instance.collection('organizations').doc(organizationId).collection('workmanagement');

    await workRef.doc(work.id).delete();

    setState(() {
      // Handle deletion accordingly
    });
  }

 Widget _buildEditWorkDialog(BuildContext context, DocumentSnapshot work) {
  return AlertDialog(
    title: Text('Edit Work'),
    content: SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDateField(context),
            _buildTextField('Work', workController),
            _buildTextField('Amount', amountController),
            _buildDropdownField('Payment', paymentOptions, selectedPaymentOption),
            _buildDropdownField('Progress', progressOptions, selectedProgressOption),
            // Display the incharge value, disable the field
            TextFormField(
              controller: inchargeController,
              enabled: false,
              decoration: InputDecoration(labelText: 'Incharge'),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: Text('Cancel'),
      ),
      TextButton(
        onPressed: () {
          updateWork(work.id);
        },
        child: Text('Update'),
      ),
    ],
  );
}


  void updateWork(String workId) async {
    if (_formKey.currentState!.validate()) {
      final userSnapshot = await _getCurrentUser();
      final organizationId = userSnapshot.data()?['organizationId'];
      final workRef = FirebaseFirestore.instance.collection('organizations').doc(organizationId).collection('workmanagement');

      await workRef.doc(workId).update({
        'date': selectedDate,
        'work': workController.text,
        'amount': amountController.text,
        'payment': selectedPaymentOption,
        'progress': selectedProgressOption,
        'incharge': selectedInChargeName,
      });

      setState(() {
        dateController.clear();
        workController.clear();
        amountController.clear();
        selectedPaymentOption = 'Paid'; // Reset payment dropdown to default value
        selectedProgressOption = 'Done'; // Reset progress dropdown to default value
        inchargeController.clear();
        selectedInChargeId = null;
        selectedInChargeType = '';
      });

      Navigator.of(context).pop();
    }
  }
}

