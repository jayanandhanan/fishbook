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
  final TextEditingController selectedPaymentDateController = TextEditingController();
  final TextEditingController inchargeController = TextEditingController();
  final TextEditingController selectedDateController = TextEditingController();
  final TextEditingController paidAmountController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  DateTime selectedDate = DateTime.now();
  DateTime selectedPaymentDate = DateTime.now();
  String selectedInChargeType = '';
  String? selectedInChargeId;
  String? selectedInChargeName;

  List<String> ownerNames = [];
  List<String> crewMemberNames = [];

  late QuerySnapshot ownerDetailsSnapshot;
  late QuerySnapshot crewMemberDetailsSnapshot;

  List<String> paymentOptions = ['Paid', 'Not Paid'];
  List<String> progressOptions = ['Done', 'Pending'];
  List<String> paymentModeOptions = ['Cash', 'UPI', 'Net Banking'];
  String selectedPaymentOption = 'Paid';
  String selectedProgressOption = 'Done';
  String selectedModeOfPayment = 'Cash';

  String? filterByWork; // Filter by Work value
  DateTime? filterByDate; // Filter by Date value
  String? filterByProgress; // Filter by Progress value
  String? filterByPayment; // Filter by Payment value
  String? filterByOwnerInCharge; // Filter by Owner Incharge value
  String? filterByCrewMemberInCharge; // Filter by Crew Member Incharge value

  // Define filter state variables
  bool isWorkFilterActive = false;
  bool isDateFilterActive = false;
  bool isProgressFilterActive = false;
  bool isPaymentFilterActive = false;
  bool isOwnerInChargeFilterActive = false;
  bool isCrewMemberInChargeFilterActive = false;
  String? userRole; 

  @override
  void initState() {
    super.initState();
    _fetchOwnerDetails();
    _fetchCrewMemberDetails();
    _fetchUserRole();
  }
  
  Future<void> _fetchUserRole() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      DocumentSnapshot userSnapshot =
          await FirebaseFirestore.instance.collection('users').doc(userId).get();
      setState(() {
        userRole = userSnapshot['role']; // Assign the user role to the variable
      });
    }
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isWorkFilterActive = true;
                        // Reset other filter states
                        isDateFilterActive = false;
                        isProgressFilterActive = false;
                        isPaymentFilterActive = false;
                        isOwnerInChargeFilterActive = false;
                        isCrewMemberInChargeFilterActive = false;
                      });
                      _showFilterDialog(FilterType.Work);
                    },
                    child: Text('Filter by Work'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isDateFilterActive = true;
                        // Reset other filter states
                        isWorkFilterActive = false;
                        isProgressFilterActive = false;
                        isPaymentFilterActive = false;
                        isOwnerInChargeFilterActive = false;
                        isCrewMemberInChargeFilterActive = false;
                      });
                      _showFilterDialog(FilterType.Date);
                    },
                    child: Text('Filter by Date'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isProgressFilterActive = true;
                        // Reset other filter states
                        isWorkFilterActive = false;
                        isDateFilterActive = false;
                        isPaymentFilterActive = false;
                        isOwnerInChargeFilterActive = false;
                        isCrewMemberInChargeFilterActive = false;
                      });
                      _showFilterDialog(FilterType.Progress);
                    },
                    child: Text('Filter by Progress'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isPaymentFilterActive = true;
                        // Reset other filter states
                        isWorkFilterActive = false;
                        isDateFilterActive = false;
                        isProgressFilterActive = false;
                        isOwnerInChargeFilterActive = false;
                        isCrewMemberInChargeFilterActive = false;
                      });
                      _showPaymentFilterDialog();
                    },
                    child: Text('Filter by Payment'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isOwnerInChargeFilterActive = true;
                        // Reset other filter states
                        isWorkFilterActive = false;
                        isDateFilterActive = false;
                        isProgressFilterActive = false;
                        isPaymentFilterActive = false;
                        isCrewMemberInChargeFilterActive = false;
                      });
                      _showOwnerInChargeFilterDialog();
                    },
                    child: Text('Filter by Owner Incharge'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isCrewMemberInChargeFilterActive = true;
                        // Reset other filter states
                        isWorkFilterActive = false;
                        isDateFilterActive = false;
                        isProgressFilterActive = false;
                        isPaymentFilterActive = false;
                        isOwnerInChargeFilterActive = false;
                      });
                      _showCrewMemberInChargeFilterDialog();
                    },
                    child: Text('Filter by Crew Member Incharge'),
                  ),
                ],
              ),
            ),
             SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (userRole == 'Headowner')
                ElevatedButton(
                  onPressed: () {
                setState(() {
                  // Reset all filters
                  isWorkFilterActive = false;
                  isDateFilterActive = false;
                  isProgressFilterActive = false;
                  isPaymentFilterActive = false;
                  isOwnerInChargeFilterActive = false;
                  isCrewMemberInChargeFilterActive = false;
                });
                _showAddWorkDialog();
              },
              child: Text('Add Work'),
            ), SizedBox(width: 10), // Add spacing between buttons
    ElevatedButton(
      onPressed: () {
        setState(() {
          // Reset filter states and values
          isWorkFilterActive = false;
          isDateFilterActive = false;
          isProgressFilterActive = false;
          isPaymentFilterActive = false;
          isOwnerInChargeFilterActive = false;
          isCrewMemberInChargeFilterActive = false;
          filterByWork = null;
          filterByDate = null;
          filterByProgress = null;
          filterByPayment = null;
          filterByOwnerInCharge = null;
          filterByCrewMemberInCharge = null;
        });
      },
      child: Text('Reset Filters'),
    ),
              ],
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

          // Apply filters based on active filter states
if (isWorkFilterActive && filterByWork != null && filterByWork!.isNotEmpty) {
  workList = workList.where((work) => work['work'] == filterByWork).toList();
}
if (isDateFilterActive && filterByDate != null) {
  workList = workList.where((work) {
    DateTime workDate = (work['date'] as Timestamp).toDate();
    String formattedDate = DateFormat('dd-MM-yyyy').format(workDate);
    return formattedDate == DateFormat('dd-MM-yyyy').format(filterByDate!);
  }).toList();
}

if (isProgressFilterActive && filterByProgress != null && filterByProgress!.isNotEmpty) {
  workList = workList.where((work) => work['progress'] == filterByProgress).toList();
}
if (isPaymentFilterActive && filterByPayment != null && filterByPayment!.isNotEmpty) {
  workList = workList.where((work) => work['payment'] == filterByPayment).toList();
}
if (isOwnerInChargeFilterActive && filterByOwnerInCharge != null && filterByOwnerInCharge!.isNotEmpty) {
  workList = workList.where((work) => work['incharge'] == filterByOwnerInCharge).toList();
}
if (isCrewMemberInChargeFilterActive && filterByCrewMemberInCharge != null && filterByCrewMemberInCharge!.isNotEmpty) {
  workList = workList.where((work) => work['incharge'] == filterByCrewMemberInCharge).toList();
}
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
      DataColumn(label: Text('Paid Amount')),     
      DataColumn(label: Text('Pending Amount')),
      DataColumn(label: Text('Payment')),
      DataColumn(label: Text('Payment Date')),
      DataColumn(label: Text('Mode of Payment')), 
      DataColumn(label: Text('Incharge')),
      if (userRole == 'Headowner')
      DataColumn(label: Text('Actions')),
    ];
  }

 List<DataRow> _buildTableRows(List<DocumentSnapshot> workList) {
  List<DataRow> rows = [];

  workList.forEach((work) {
    DataRow row = DataRow(cells: [
      DataCell(Text(_formatDate((work['date'] as Timestamp).toDate()))),
      DataCell(Text(work['work'])),
      DataCell(Text(work['progress'])),
      DataCell(Text(work['amount'])),
      DataCell(Text(work['paidamount'])),
      DataCell(Text(work['pendingamount'])),
      DataCell(Text(work['payment'])),
      DataCell(Text(_formatDate((work['paymentdate'] as Timestamp).toDate()))),
      DataCell(Text(work['modeofpayment'])),
      DataCell(Text(work['incharge'])),
      if (userRole == 'Headowner')
      DataCell(
        Row(
          children: [
            if (userRole == 'Headowner')
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                editWorkDialog(context, work);
              },
            ),
            if (userRole == 'Headowner')
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                deleteWork(context, work);
              },
            ),
          ],
        ),
      ),
    ]);
    rows.add(row);
  });

  return rows;
}

  String _formatDate(DateTime dateTime) {
    return DateFormat('dd-MM-yyyy').format(dateTime);
  }

  void _showAddWorkDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _buildAddWorkDialog(context);
      },
    );
  }

Widget _buildPaymentDateField(BuildContext context) {
  return TextFormField(
    controller: selectedPaymentDateController, // Set the controller
    readOnly: true, // Make the field read-only
    decoration: InputDecoration(
      labelText: 'Payment Date',
      suffixIcon: IconButton(
        onPressed: () async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: selectedPaymentDate, // Set initial date to selectedPaymentDate
            firstDate: DateTime(2015, 8),
            lastDate: DateTime(2101),
          );
          if (picked != null && picked != selectedPaymentDate) {
            setState(() {
              selectedPaymentDate = picked;
              selectedPaymentDateController.text = DateFormat('dd-MM-yyyy').format(selectedPaymentDate);
            });
          }
        },
        icon: Icon(Icons.calendar_today),
      ),
    ),
    validator: (value) {
      if (value == null || value.isEmpty) {
        return 'Please select a payment date';
      }
      return null;
    },
  );
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
              _buildDropdownField('Progress', progressOptions, selectedProgressOption),
              _buildTextField('Amount', amountController),
              _buildTextField('Paid Amount', paidAmountController),
              _buildDropdownField('Payment', paymentOptions, selectedPaymentOption),
              _buildPaymentDateField(context),            
              _buildDropdownField('Mode of Payment', paymentModeOptions, selectedModeOfPayment),
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

 void addWork(BuildContext context) async {
  if (_formKey.currentState!.validate()) {
    String amount = amountController.text;
    String paidAmount = paidAmountController.text.isNotEmpty ? paidAmountController.text : '0';
    // Calculate pending amount
    String pendingAmount = (int.parse(amount) - int.parse(paidAmount)).toString();
    if (selectedInChargeName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select an incharge before adding work.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      isWorkFilterActive = false;
      isDateFilterActive = false;
      isProgressFilterActive = false;
      isPaymentFilterActive = false;
      isOwnerInChargeFilterActive = false;
      isCrewMemberInChargeFilterActive = false;
    });

    // Add work to Firestore
    final userSnapshot = await _getCurrentUser();
    final organizationId = userSnapshot.data()?['organizationId'];
    final workRef = FirebaseFirestore.instance.collection('organizations').doc(organizationId).collection('workmanagement');


   // Check if the incharge was selected from the owner details
    if (selectedInChargeType == 'Owner') {
      // If selected from owner details, set the user field in Firestore as 'Owner'
      final userSnapshot = await _getCurrentUser();
      final organizationId = userSnapshot.data()?['organizationId'];
      final workRef = FirebaseFirestore.instance.collection('organizations').doc(organizationId).collection('workmanagement');

      // Generate a new document ID
      final newDocRef = workRef.doc();

      // Add work entry with incharge ID and set user as 'Owner'
      await newDocRef.set({
        'date': selectedDate,
        'work': workController.text,
        'amount': amountController.text,
        'paymentdate': selectedPaymentDate,
        'modeofpayment': selectedModeOfPayment,
        'paidamount': paidAmount,
        'pendingamount': pendingAmount,
        'payment': selectedPaymentOption,
        'progress': selectedProgressOption,
        'incharge': selectedInChargeName,
        'inchargeid': selectedInChargeId, // Add the ID of the incharge
        'user': 'Owner', // Set the user field as 'Owner'
      });
    } else {
      // If not selected from owner details, set the user field in Firestore as 'Crew Member'
      final userSnapshot = await _getCurrentUser();
      final organizationId = userSnapshot.data()?['organizationId'];
      final workRef = FirebaseFirestore.instance.collection('organizations').doc(organizationId).collection('workmanagement');

      // Generate a new document ID
      final newDocRef = workRef.doc();

      // Add work entry with incharge ID and set user as 'Crew Member'
      await newDocRef.set({
        'date': selectedDate,
        'work': workController.text,
        'amount': amountController.text,
        'paymentdate': selectedPaymentDate,
        'modeofpayment': selectedModeOfPayment,
        'paidamount': paidAmount,
        'pendingamount': pendingAmount,
        'payment': selectedPaymentOption,
        'progress': selectedProgressOption,
        'incharge': selectedInChargeName,
        'inchargeid': selectedInChargeId, // Add the ID of the incharge
        'user': 'Crew Member', // Set the user field as 'Crew Member'
      });
    }

    // Clear input fields
    setState(() {
      dateController.clear();
      workController.clear();
      selectedProgressOption = 'Done';
      amountController.clear();
      paidAmountController.clear();
      selectedPaymentOption = 'Paid';
      selectedPaymentDateController.clear();
      selectedModeOfPayment = 'Cash';
      inchargeController.clear();
    });

    Navigator.of(context).pop();
  }
}

  void _showFilterDialog(FilterType filterType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        switch (filterType) {
          case FilterType.Work:
            return _buildFilterByWorkDialog(context);
          case FilterType.Date:
            return _buildFilterByDateDialog(context);
          case FilterType.Progress:
            return _buildFilterByProgressDialog(context);
        }
      },
    );
  }

  Widget _buildFilterByWorkDialog(BuildContext context) {
    return AlertDialog(
      title: Text('Filter by Work'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: workController,
              decoration: InputDecoration(labelText: 'Enter Work'),
              onChanged: (value) {
                setState(() {
                  filterByWork = value;
                  filterByDate = null;
                  filterByProgress = null;
                });
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Apply Filter'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterByDateDialog(BuildContext context) {
    return AlertDialog(
      title: Text('Filter by Date'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2015, 8),
                  lastDate: DateTime(2101),
                );
                if (picked != null && picked != selectedDate) {
                  setState(() {
                    filterByDate = picked;
                    filterByWork = null;
                    filterByProgress = null;
                  });
                }
              },
              child: Text('Select Date'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Apply Filter'),
            ),
          ],
        ),
      ),
    );
  }

Widget _buildFilterByProgressDialog(BuildContext context) {
  return AlertDialog(
    title: Text('Filter by Progress'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    filterByProgress = 'Done';
                    Navigator.pop(context);
                  });
                },
                child: Text('Done'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    filterByProgress = 'Pending';
                    Navigator.pop(context);
                  });
                },
                child: Text('Pending'),
              ),
            ],
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
        ],
      ),
    ),
  );
}

 void _showPaymentFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Filter by Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    filterByPayment = 'Paid';
                  });
                  Navigator.pop(context);
                },
                child: Text('Paid'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    filterByPayment = 'Not Paid';
                  });
                  Navigator.pop(context);
                },
                child: Text('Not Paid'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showOwnerInChargeFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Filter by Owner Incharge'),
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
                      filterByOwnerInCharge = ownerNames[index];
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showCrewMemberInChargeFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Filter by Crew Member Incharge'),
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
                      filterByCrewMemberInCharge = crewMemberNames[index];
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

 Widget _buildDateField(BuildContext context) {
  return TextFormField(
    controller: selectedDateController, // Set the controller
    readOnly: true, // Make the field read-only
    decoration: InputDecoration(
      labelText: 'Date',
      suffixIcon: IconButton(
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
              selectedDateController.text = DateFormat('dd-MM-yyyy').format(selectedDate);
            });
          }
        },
        icon: Icon(Icons.calendar_today),
      ),
    ),
    validator: (value) {
      if (value == null || value.isEmpty) {
        return 'Please select a date';
      }
      return null;
    },
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

void deleteWork(BuildContext context, DocumentSnapshot work) async {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete this work entry?'),
        actions: <Widget>[
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close the dialog

              final userSnapshot = await _getCurrentUser();
              final organizationId = userSnapshot.data()?['organizationId'];
              final workRef = FirebaseFirestore.instance.collection('organizations').doc(organizationId).collection('workmanagement');

              // Delete the work entry
              await workRef.doc(work.id).delete();

              setState(() {
                // Handle deletion accordingly
              });
            },
            child: Text('Yes'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: Text('No'),
          ),
        ],
      );
    },
  );
}
  
void editWorkDialog(BuildContext context, DocumentSnapshot work) {
  selectedDateController.text = _formatDate((work['date'] as Timestamp).toDate());
  workController.text = work['work'];
  selectedProgressOption = work['progress'];
  amountController.text = work['amount'];
  paidAmountController.text = work['paidamount'];
  selectedPaymentOption = work['payment'];
  selectedPaymentDateController.text = _formatDate((work['date'] as Timestamp).toDate());
  selectedModeOfPayment = work['modeofpayment'];
  selectedInChargeId = work.id;
  selectedInChargeName = work['incharge'];

  showDialog(
    context: context,
    builder: (BuildContext context) {
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
                _buildDropdownField('Progress', progressOptions, selectedProgressOption),
                _buildTextField('Amount', amountController),
                _buildTextField('Paid Amount', paidAmountController),
                _buildDropdownField('Payment', paymentOptions, selectedPaymentOption),
                _buildPaymentDateField(context),
                _buildDropdownField('Mode of Payment', paymentModeOptions, selectedModeOfPayment),
                
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
    },
  );
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
            _buildDropdownField('Progress', progressOptions, selectedProgressOption),
            _buildTextField('Amount', amountController),
            _buildTextField('Paid Amount', paidAmountController),
            _buildDropdownField('Payment', paymentOptions, selectedPaymentOption),
            _buildPaymentDateField(context),
            _buildDropdownField('Mode of Payment', paymentModeOptions, selectedModeOfPayment),
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
         String amount = amountController.text;
        String paidAmount = paidAmountController.text.isNotEmpty ? paidAmountController.text : '0';
    // Calculate pending amount
       String pendingAmount = (int.parse(amount) - int.parse(paidAmount)).toString();
      final userSnapshot = await _getCurrentUser();
      final organizationId = userSnapshot.data()?['organizationId'];
      final workRef = FirebaseFirestore.instance.collection('organizations').doc(organizationId).collection('workmanagement');

      await workRef.doc(workId).update({
        'date': selectedDate,
        'work': workController.text,
        'amount': amountController.text,
        'payment': selectedPaymentOption,
        'modeofpayment': selectedModeOfPayment,
        'paymentDate': selectedPaymentDate,
       'paidamount': paidAmount,
       'pendingamount': pendingAmount,
        'progress': selectedProgressOption,
        'incharge': selectedInChargeName,
      });
setState(() {
    isWorkFilterActive = false;
    isDateFilterActive = false;
    isProgressFilterActive = false;
    isPaymentFilterActive = false;
    isOwnerInChargeFilterActive = false;
    isCrewMemberInChargeFilterActive = false;
  });

      setState(() {
      dateController.clear();
      workController.clear();
      selectedProgressOption = 'Done';
      amountController.clear();
      paidAmountController.clear();
      selectedPaymentOption = 'Paid';
      selectedPaymentDateController.clear();
      selectedModeOfPayment = 'Cash';
      inchargeController.clear();
      });

      Navigator.of(context).pop();
    }
  }
}

  enum FilterType {
    Work,
    Date,
    Progress,
   
  }
