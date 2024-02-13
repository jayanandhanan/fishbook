import 'package:fishbook/home_screen.dart';
import 'package:fishbook/login_screen.dart';
import 'package:fishbook/statementsscreen.dart';
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
  final TextEditingController paymentdateController = TextEditingController();
  final TextEditingController selectedPaymentDateController = TextEditingController();
  final TextEditingController inchargeController = TextEditingController();
  final TextEditingController selectedDateController = TextEditingController();
  final TextEditingController paidAmountController = TextEditingController();
  final TextEditingController selectedSailingDateController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  DateTime selectedDate = DateTime.now();
  DateTime selectedPaymentDate = DateTime.now();
  String selectedInChargeType = '';
  String? selectedInChargeId;
  String? selectedInChargeName;
  String? selectedMaintenanceDocumentId;
  String selectedRemainingMaintenanceAmount = '';
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
  String? organizationId;
  String? assigned;
  bool isHomeScreen = false;

  @override
  void initState() {
    super.initState();
    _fetchOwnerDetails();
    _fetchCrewMemberDetails();
    _fetchUserRoleAndOrganizationId();
    _fetchAssigned();
  }
  
 Future<void> _fetchUserRoleAndOrganizationId() async {
  String? userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId != null) {
    DocumentSnapshot userSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    setState(() {
      userRole = userSnapshot['role']; // Assign the user role to the variable
      organizationId = userSnapshot['organizationId']; // Assign the organizationId
    });
  }
}

 Future<void> _fetchAssigned() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      DocumentSnapshot userSnapshot =
          await FirebaseFirestore.instance.collection('users').doc(userId).get();
      setState(() {
        assigned = userSnapshot['assigned'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Work Management'),
        backgroundColor: Colors.blue,
      ),
      bottomNavigationBar: buildBottomNavigationBar(context),
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
                if (userRole == 'Headowner' || assigned == 'Yes')
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

BottomNavigationBar buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 0,
      fixedColor: Colors.grey , 
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home, color: Colors.grey), 
          label: "Home",
          backgroundColor: Color(0xFFF9D8C5),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.wrap_text),
          label: "Statements",
          backgroundColor: Color(0xFFF9D8C5),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.exit_to_app),
          label: "Logout",
          backgroundColor: Color(0xFFF9D8C5),
        ),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            // Navigate to HomeScreen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HomeScreen(organizationId: organizationId),
              ),
            );
            break;
          case 1:
            // Navigate to StatementScreen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StatementScreen(),
              ),
            );
            break;
          case 2:
            // Logout
            FirebaseAuth.instance.signOut().then((value) {
              print("Signed Out");
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            });
            break;
        }
      },
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
    child: SingleChildScrollView(
      scrollDirection: Axis.vertical,
 child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black), // Add black border around the table
          ),
          child: DataTable(
            showCheckboxColumn: false,
            columnSpacing: 16.0,
            headingRowColor: MaterialStateColor.resolveWith((states) => Color(0xFFF9D8C5)), // Set header row color
            dividerThickness: 1.0, // Add separator lines between columns
          
              columns: _buildTableColumns(),
              rows: _buildTableRows(workList),
            ),
          ),),);
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
       DataColumn(label: Text('Assigned Sailing Date')),
      if (userRole == 'Headowner' || assigned == 'Yes')
      DataColumn(label: Text('Actions')),
    ];
  }

 List<DataRow> _buildTableRows(List<DocumentSnapshot> workList) {
   workList.sort((a, b) {
    DateTime dateA = (a['date'] as Timestamp).toDate();
    DateTime dateB = (b['date'] as Timestamp).toDate();
    return dateA.compareTo(dateB);
  });
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
       DataCell(Text(_formatDate((work['assignedSailingDate'] as Timestamp).toDate()))), // New cell
      if (userRole == 'Headowner' || assigned == 'Yes')
      DataCell(
        Row(
          children: [
            if (userRole == 'Headowner' || assigned == 'Yes')
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                editWorkDialog(context, work);
              },
            ),
            if (userRole == 'Headowner' || assigned =='Yes')
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
               TextFormField(
              controller: selectedSailingDateController,
              enabled: false,
              decoration: InputDecoration(labelText: 'Assigned Sailing Date'),
            ),
            ElevatedButton(
              onPressed: () {
                _showAssignSailingDateDialog();
              },
              child: Text('Assign Sailing Date'),
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
            addWork(context);
          },
          child: Text('Add'),
        ),
      ],
    );
  }


void _showAssignSailingDateDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Select Sailing Date'),
        content: Container(
          width: double.maxFinite,
          child: FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('organizations')
                .doc(organizationId) // Use the fetched organizationId
                .collection('boatmaintenanceamounts')
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              }
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              List<DocumentSnapshot> documents = snapshot.data!.docs;
              return ListView.builder(
                itemCount: documents.length,
                itemBuilder: (context, index) {
                  var document = documents[index];
                  Timestamp sailingDateTimestamp = document['sailingdate'];
                  DateTime sailingDate = sailingDateTimestamp.toDate();
                  String formattedDate = DateFormat('dd-MM-yyyy').format(sailingDate);
                  return ListTile(
                    title: Text('Sailing Date: $formattedDate'),
                    subtitle: Text('Remaining Maintenance Amount: ${document['remainingboatmaintenanceamount']}'),
                    onTap: () {
                      // Pass selected document ID and sailing date back to the caller
                      Navigator.pop(context, {'documentId': document.id, 'sailingDate': formattedDate});
                    },
                  );
                },
              );
            },
          ),
        ),
      );
    },
  ).then((value) {
    if (value != null) {
      // Handle the selected document ID and sailing date here
      selectedMaintenanceDocumentId = value['documentId'];
      selectedSailingDateController.text = value['sailingDate'];
    }
  });
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

    // Get the selected boat maintenance document
    final selectedBoatDocRef = FirebaseFirestore.instance.collection('organizations')
        .doc(organizationId).collection('boatmaintenanceamounts').doc(selectedMaintenanceDocumentId);
    final selectedBoatDocSnapshot = await selectedBoatDocRef.get();
    int remainingMaintenanceAmount = selectedBoatDocSnapshot['remainingboatmaintenanceamount'];

    // Check if the amount value is less than or equal to the remaining maintenance amount
    if (int.parse(amount) <= remainingMaintenanceAmount) {
      try {
        // Proceed with adding work
        final newDocRef = workRef.doc();
        Timestamp sailingDateTimestamp = selectedBoatDocSnapshot['sailingdate'];

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
          'inchargeid': selectedInChargeId,
          'user': selectedInChargeType == 'Owner' ? 'Owner' : 'Crew Member',
          'assignedSailingDate': sailingDateTimestamp,
          'boatmaintenancedocumentid': selectedMaintenanceDocumentId,
        });

        // Update used amount in the boatmaintenanceamounts document
        int newAmount = int.parse(amount);
        int currentUsedAmount = selectedBoatDocSnapshot['usedamount'] ?? 0;
        int updatedUsedAmount = currentUsedAmount + newAmount;
        int boatMaintenanceAmount = selectedBoatDocSnapshot['boatmaintenanceamount'] ?? 0;
        int remainingMaintenanceAmount = boatMaintenanceAmount - updatedUsedAmount;

        await selectedBoatDocRef.update({
          'usedamount': updatedUsedAmount,
          'remainingboatmaintenanceamount': remainingMaintenanceAmount,
        });

        // Clear input fields
        setState(() {
          dateController.clear();
          workController.clear();
          selectedProgressOption = 'Done';
          amountController.clear();
          paidAmountController.clear();
          selectedPaymentOption = 'Paid';
          paymentdateController.clear();
          selectedModeOfPayment = 'Cash';
          inchargeController.clear();
          selectedSailingDateController.clear();
        });

        // Show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Work added successfully.'),
            duration: Duration(seconds: 3),
          ),
        );
         Navigator.of(context).pop();
      } catch (e) {
        // Show an error message
        print('Error adding work: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add work. Please try again later.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } else {
      // Show a message indicating that work cannot be added with an amount value more than the remaining boat maintenance amount
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You cannot add work with an amount value more than the remaining boat maintenance amount. Try assigning other documents.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
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



Widget _buildTextField(String label, TextEditingController controller, {ValueChanged<String>? onChanged}) {
  return TextFormField(
    controller: controller,
    decoration: InputDecoration(
      labelText: label,
    ),
    onChanged: onChanged,
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

              // Get the boat maintenance document ID from the work document
              String boatMaintenanceDocumentId = work['boatmaintenancedocumentid'];

              // Convert the amount from string to int
              int workAmount = int.parse(work['amount'] ?? '0');

              // Delete the work entry
              await workRef.doc(work.id).delete();

              // Update the corresponding boat maintenance document
              final boatMaintenanceRef = FirebaseFirestore.instance.collection('organizations')
                .doc(organizationId).collection('boatmaintenanceamounts').doc(boatMaintenanceDocumentId);

              final boatMaintenanceSnapshot = await boatMaintenanceRef.get();

              if (boatMaintenanceSnapshot.exists) {
                // Get the current used amount from the boat maintenance document
                int currentUsedAmount = boatMaintenanceSnapshot['usedamount'] ?? 0;

                // Calculate the updated used amount and remaining maintenance amount
                int updatedUsedAmount = currentUsedAmount - workAmount;
                int totalMaintenanceAmount = boatMaintenanceSnapshot['boatmaintenanceamount'] ?? 0;
                int remainingMaintenanceAmount = totalMaintenanceAmount - updatedUsedAmount;

                // Update the boat maintenance document
                await boatMaintenanceRef.update({
                  'usedamount': updatedUsedAmount,
                  'remainingboatmaintenanceamount': remainingMaintenanceAmount,
                });
              } else {
                print('Boat maintenance document does not exist');
              }

              setState(() {
                // Handle state update accordingly
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
  int previousAmount = int.parse(work['amount'] ?? '0');
  selectedDateController.text = _formatDate((work['date'] as Timestamp).toDate());
  workController.text = work['work'];
  selectedProgressOption = work['progress'];
  amountController.text = previousAmount.toString();
  paidAmountController.text = work['paidamount'];
  selectedPaymentOption = work['payment'];
  selectedPaymentDateController.text = _formatDate((work['paymentdate'] as Timestamp).toDate());
  selectedModeOfPayment = work['modeofpayment'];
  selectedInChargeName = work['incharge'];
  Timestamp assignedSailingDateTimestamp = work['assignedSailingDate'];

  selectedSailingDateController.text = ''; // Set the sailing date field initially empty
  selectedInChargeId = work.id;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
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
                    _buildSailingDateField(context), // Show the sailing date field
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
                onPressed: () async {
                  if (selectedSailingDateController.text.isEmpty) {
                    // Prompt the user to select a sailing date if not selected
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Please select a sailing date'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else {
                    int newAmount = int.tryParse(amountController.text) ?? 0;
                    int difference = newAmount - previousAmount;
                    bool isWorkUpdated = await updateWork(work.id, previousAmount); // Update the work
                    if (isWorkUpdated) {
                      updateUsedAmount(newAmount, difference, assignedSailingDateTimestamp); // Update used amount
                      Navigator.of(context).pop(); // Close the dialog
                    }
                  }
                },
                child: Text('Update'),
              ),
            ],
          );
        },
      );
    },
  );
}


void updateUsedAmount(int newAmount, int difference, Timestamp assignedSailingDateTimestamp) async {
  try {
    if (selectedMaintenanceDocumentId != null) {
      final selectedBoatDocRef = FirebaseFirestore.instance
          .collection('organizations')
          .doc(organizationId)
          .collection('boatmaintenanceamounts')
          .doc(selectedMaintenanceDocumentId);

      final selectedBoatDocSnapshot = await selectedBoatDocRef.get();
      if (selectedBoatDocSnapshot.exists) {
        // Update the used amount in Firestore
        int currentUsedAmount = selectedBoatDocSnapshot['usedamount'] ?? 0;
        int updatedUsedAmount = currentUsedAmount + difference;

        // Update the remaining maintenance amount
        int boatMaintenanceAmount = selectedBoatDocSnapshot['boatmaintenanceamount'] ?? 0;
        int remainingMaintenanceAmount = boatMaintenanceAmount - updatedUsedAmount;

        // Update the used amount and remaining maintenance amount in Firestore
        await selectedBoatDocRef.update({
          'usedamount': updatedUsedAmount,
          'remainingboatmaintenanceamount': remainingMaintenanceAmount,
        });
      } else {
        print('Document does not exist');
      }
    } else {
      print('Selected maintenance document ID is null');
    }
  } catch (e) {
    print('Error updating used amount: $e');
  }
}

Future<bool> updateWork(String workId, int previousAmount) async {
  if (_formKey.currentState!.validate()) {
    String selectedSailingDate = selectedSailingDateController.text;

    // Convert the selected sailing date to a DateTime object
    DateTime sailingDate = DateFormat('dd-MM-yyyy').parse(selectedSailingDate);

    // Convert the DateTime object to a Timestamp for Firestore
    Timestamp sailingDateTimestamp = Timestamp.fromDate(sailingDate);

    String amount = amountController.text;
    String paidAmount = paidAmountController.text.isNotEmpty ? paidAmountController.text : '0';
    // Calculate pending amount
    String pendingAmount = (int.parse(amount) - int.parse(paidAmount)).toString();

    final userSnapshot = await _getCurrentUser();
    final organizationId = userSnapshot.data()?['organizationId'];
    final workRef = FirebaseFirestore.instance.collection('organizations').doc(organizationId).collection('workmanagement');

    // Fetch the selected maintenance document to get the remaining maintenance amount
    final selectedBoatDocRef = FirebaseFirestore.instance.collection('organizations')
        .doc(organizationId)
        .collection('boatmaintenanceamounts')
        .doc(selectedMaintenanceDocumentId);

    final selectedBoatDocSnapshot = await selectedBoatDocRef.get();
    int remainingMaintenanceAmount = selectedBoatDocSnapshot['remainingboatmaintenanceamount'] ?? 0;

    // Check if the amount value is less than or equal to the remaining maintenance amount
    if (int.parse(amount) <= remainingMaintenanceAmount) {
      try {
        await workRef.doc(workId).update({
          'date': selectedDate,
          'work': workController.text,
          'amount': amountController.text,
          'payment': selectedPaymentOption,
          'modeofpayment': selectedModeOfPayment,
          'paymentdate': selectedPaymentDate,
          'paidamount': paidAmount,
          'pendingamount': pendingAmount,
          'progress': selectedProgressOption,
          'incharge': selectedInChargeName,
          'assignedSailingDate': sailingDateTimestamp,
          'boatmaintenancedocumentid': selectedMaintenanceDocumentId,
        });

        // Update is successful
        return true;
      } catch (e) {
        print('Error updating work: $e');
        // Update failed
        return false;
      }
    } else {
      // Work cannot be updated with an amount value more than the remaining boat maintenance amount
      return false;
    }
  }
  return false;
}



Widget _buildSailingDateField(BuildContext context) {
  return GestureDetector(
    onTap: () {
      _showAssignSailingDateDialog(); // Call the function to show the dialog
    },
    child: AbsorbPointer(
      child: TextFormField(
        controller: selectedSailingDateController,
        keyboardType: TextInputType.datetime,
        decoration: InputDecoration(
          labelText: 'Sailing Date',
          hintText: 'Select Sailing Date',
          icon: Icon(Icons.calendar_today),
        ),
        validator: (value) {
          if (value!.isEmpty) {
            return 'Please select a sailing date';
          }
          return null;
        },
        onTap: () {
          _showAssignSailingDateDialog(); // Also call the function on tap
        },
      ),
    ),
  );
}

}
  enum FilterType {
    Work,
    Date,
    Progress,
   
  }
