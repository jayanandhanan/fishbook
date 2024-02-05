import 'package:firebase_auth/firebase_auth.dart';
import 'package:fishbook/home_screen.dart';
import 'package:fishbook/login_screen.dart';
import 'package:fishbook/statementsscreen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

enum FilterType { Date, Payment }

class FishingSailPayment extends StatefulWidget {
  @override
  _FishingSailPaymentState createState() => _FishingSailPaymentState();
}

class _FishingSailPaymentState extends State<FishingSailPayment> {
  String? _organizationId;
  String? userRole;
  FilterType? _activeFilter;
 DateTime? _selectedDate;
 bool isHomeScreen = false;
  String _selectedPaymentStatus = '';
  bool _showOwnerPayments = false;
  bool _showCrewMemberPayments = false;

  // Filter states for Crew Member Payments
  FilterType? _crewMemberActiveFilter;
  DateTime? _crewMemberSelectedDate;
  String _crewMemberSelectedPaymentStatus = '';

  // Filter states for Owner Payments
  FilterType? _ownerActiveFilter;
  DateTime? _ownerSelectedDate;
  String _ownerSelectedPaymentStatus = '';

  @override
  void initState() {
    super.initState();
    _fetchOrganizationId().then((String? organizationId) {
      setState(() {
        _organizationId = organizationId ?? '';
      });
    });
    _fetchUserRole();
  }

  Future<String?> _fetchOrganizationId() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      DocumentSnapshot userSnapshot =
          await FirebaseFirestore.instance.collection('users').doc(userId).get();
      return userSnapshot['organizationId'];
    }
    return null;
  }

  Future<void> _fetchUserRole() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      DocumentSnapshot userSnapshot =
          await FirebaseFirestore.instance.collection('users').doc(userId).get();
      setState(() {
        userRole = userSnapshot['role'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Fishing Payment'),
     backgroundColor: Colors.blue,
      ),
      bottomNavigationBar: buildBottomNavigationBar(context,false),
    body: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width / 2,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showCrewMemberPayments = true;
                        _showOwnerPayments = false;
                      });
                    },
                    child: Text('Crew Member Payment'),
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width / 2,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showOwnerPayments = true;
                        _showCrewMemberPayments = false;
                      });
                    },
                    child: Text('Owner Payment'),
                    style: userRole == 'Crew Member'
                        ? ButtonStyle(
                            backgroundColor: MaterialStateProperty.all(Colors.transparent),
                            foregroundColor: MaterialStateProperty.all(Colors.transparent),
                            overlayColor: MaterialStateProperty.all(Colors.transparent),
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFilterButton('Filter by Date', FilterType.Date, _showFilterByDateDialog),
                _buildFilterButton(
                    'Filter by Payment', FilterType.Payment, _showFilterByPaymentDialog),
                _buildResetFiltersButton(),
              ],
            ),
          ),
          if (_organizationId != null )
            _showOwnerPayments
                ? _buildPaymentTable(
                    userType: 'Owner',
                    activeFilter: _ownerActiveFilter,
                    selectedDate: _ownerSelectedDate,
                    selectedPaymentStatus: _ownerSelectedPaymentStatus,
                  )
                : _showCrewMemberPayments
                    ? _buildPaymentTable(
                        userType: 'Crew Member',
                        activeFilter: _crewMemberActiveFilter,
                        selectedDate: _crewMemberSelectedDate,
                        selectedPaymentStatus: _crewMemberSelectedPaymentStatus,
                      )
                    : SizedBox(), // Empty container if no payment table is selected
        ],
      ),
    ),
  );
}
BottomNavigationBar buildBottomNavigationBar(BuildContext context, bool isHomeScreen) {
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
        setState(() {
          switch (index) {
            case 0:
              // Navigate to HomeScreen only if it's not the current screen
              if (!isHomeScreen) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HomeScreen(organizationId: _organizationId)),
                );
              }
              break;
            case 1:
              // Navigate to StatementScreen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => StatementScreen()),
              );
              break;
            case 2:
              // Logout
              FirebaseAuth.instance.signOut().then((value) {
                print("Signed Out");
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen(userType: '')),
                );
              });
              break;
          }
        });
      },
    );
  }
  Widget _buildFilterButton(
      String title, FilterType filterType, Function()? onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(title),
    );
  }

Widget _buildResetFiltersButton() {
  return ElevatedButton(
    onPressed: () {
      setState(() {
        // Reset filters for Crew Member Payments
        _crewMemberActiveFilter = null;
        _crewMemberSelectedDate = null;
        _crewMemberSelectedPaymentStatus = '';
        // Reset filters for Owner Payments
        _ownerActiveFilter = null;
        _ownerSelectedDate = null;
        _ownerSelectedPaymentStatus = '';
      });
    },
    child: Text('Reset Filters In Both Payment'),
  );
}


 Widget _buildPaymentTable({
  required String userType,
  required FilterType? activeFilter,
  required DateTime? selectedDate,
  required String selectedPaymentStatus,
}) {
  return StreamBuilder(
    stream: _fetchPaymentDetails(
        userType: userType,
        activeFilter: activeFilter,
        selectedDate: selectedDate,
        selectedPaymentStatus: selectedPaymentStatus),
    builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return CircularProgressIndicator();
      }

      if (snapshot.hasError) {
        return Text('Error: ${snapshot.error}');
      }

      List<QueryDocumentSnapshot> payments = snapshot.data!.docs;
payments.sort((a, b) {
  DateTime dateA = (a['paymentdate'] as Timestamp).toDate();
  DateTime dateB = (b['paymentdate'] as Timestamp).toDate();
  return dateA.compareTo(dateB); // Sorting in ascending order
});
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
          columns: [
            DataColumn(label: Text('Payment Date')),
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('User')),
            DataColumn(label: Text('Amount')),
            DataColumn(label: Text('Paid Amount')),
            DataColumn(label: Text('Pending Amount')),
            DataColumn(label: Text('Payment')),
            DataColumn(label: Text('Mode of Payment')),
          ],
          rows: payments.map<DataRow>((paymentDoc) {
            Timestamp timestamp = paymentDoc['paymentdate'] ?? Timestamp.now();
            DateTime dateTime = timestamp.toDate();
            String formattedDate = DateFormat('dd-MM-yyyy').format(dateTime);

            String paidAmountString = paymentDoc['paidamount'] ?? '0';
            double paidAmount = double.parse(paidAmountString);
            double pendingAmount = double.parse(paymentDoc['pendingamount'] ?? '0');

            String amountString = userType == 'Crew Member'
                ? paymentDoc['amount'].toString()
                : paymentDoc['remainingamountshare'].toString();

            List<DataCell> cells = [
              DataCell(
                Row(
                  children: [
                    Text(formattedDate),
                    if (userRole == 'Headowner')
                      ElevatedButton(
                        onPressed: () {
                          _showDatePickerDialog(paymentDoc, dateTime, userRole!);
                        },
                        child: Text('Change'),
                      ),
                  ],
                ),
              ),
              DataCell(Text(paymentDoc['name'] ?? '')),
              DataCell(Text(paymentDoc['user'] ?? '')),
              DataCell(Text(amountString)),
              DataCell(
                Row(
                  children: [
                    Text(paidAmountString),
                    if (userRole == 'Headowner')
                      ElevatedButton(
                        onPressed: () {
                          _showPaidAmountDialog(paymentDoc, paidAmount, userType, userRole!);
                        },
                        child: Text('Change'),
                      ),
                  ],
                ),
              ),
              DataCell(Text(pendingAmount.toString())),
              DataCell(
                TextButton(
                  onPressed: () {
                    if (userRole == 'Headowner') {
                      _showPaymentStatusDialog(paymentDoc, userRole!);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('You are not authorized to perform this action.'),
                        ),
                      );
                    }
                  },
                  child: Text(paymentDoc['payment'] ?? ''),
                ),
              ),
              DataCell(
                TextButton(
                  onPressed: () {
                    if (userRole == 'Headowner') {
                      _showModeOfPaymentDialog(paymentDoc, userRole!);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('You are not authorized to perform this action.'),
                        ),
                      );
                    }
                  },
                  child: Text(paymentDoc['modeofpayment'] ?? 'Not Set'),
                ),
              ),
            ];
            return DataRow(cells: cells);
          }).toList(),
        ),
      ),),);
    },
  );
}

// Add the _showModeOfPaymentDialog method to the class:
void _showModeOfPaymentDialog(DocumentSnapshot paymentDoc,String userRole) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Select Mode of Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                paymentDoc.reference.update({'modeofpayment': 'Cash'});
                Navigator.pop(context);
              },
              child: Text('Cash'),
            ),
            ElevatedButton(
              onPressed: () {
                paymentDoc.reference.update({'modeofpayment': 'UPI'});
                Navigator.pop(context);
              },
              child: Text('UPI'),
            ),
            ElevatedButton(
              onPressed: () {
                paymentDoc.reference.update({'modeofpayment': 'Net Banking'});
                Navigator.pop(context);
              },
              child: Text('Net Banking'),
            ),
          ],
        ),
      );
    },
  );
}

  void _showPaidAmountDialog(
      DocumentSnapshot paymentDoc, double paidAmount, String userType, String userRole) {
    TextEditingController paidAmountController =
        TextEditingController(text: paidAmount.toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter Paid Amount'),
          content: TextField(
            controller: paidAmountController,
            keyboardType: TextInputType.number,
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
                _updatePaidAmount(paymentDoc, paidAmountController.text,
                    paymentDoc['paymentdate'].toDate(), userType);
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showDatePickerDialog(
      DocumentSnapshot paymentDoc, DateTime currentDate, String userRole) async {
    if (userRole != 'Headowner') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You are not authorized to perform this action.'),
        ),
      );
      return;
    }

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selectedDate != null) {
      paymentDoc.reference.update({'paymentdate': selectedDate});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Date updated successfully.'),
        ),
      );
    }
  }

  Stream<QuerySnapshot> _fetchPaymentDetails({
    required String userType,
    required FilterType? activeFilter,
    required DateTime? selectedDate,
    required String selectedPaymentStatus,
  }) {
    Query paymentQuery = FirebaseFirestore.instance
        .collection('organizations')
        .doc(_organizationId)
        .collection('paymentdetails')
        .where('user', isEqualTo: userType);

    // Apply filters based on user type
    if (activeFilter == FilterType.Date && selectedDate != null) {
      paymentQuery = paymentQuery.where('paymentdate', isEqualTo: selectedDate);
    } else if (activeFilter == FilterType.Payment && selectedPaymentStatus.isNotEmpty) {
      paymentQuery = paymentQuery.where('payment', isEqualTo: selectedPaymentStatus);
    }

    return paymentQuery.snapshots();
  }

  void _showPaymentStatusDialog(DocumentSnapshot paymentDoc, String userRole) {
    if (userRole != 'Headowner') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You are not authorized to perform this action.'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Update Payment Status'),
          content: Text('Mark this payment as:'),
          actions: [
            TextButton(
              onPressed: () {
                paymentDoc.reference.update({'payment': 'Paid'});
                Navigator.of(context).pop();
              },
              child: Text('Paid'),
            ),
            TextButton(
              onPressed: () {
                paymentDoc.reference.update({'payment': 'Not Paid'});
                Navigator.of(context).pop();
              },
              child: Text('Not Paid'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updatePaidAmount(
      DocumentSnapshot paymentDoc, String paidAmountString, DateTime selectedDate, String userType) async {
    try {
      if (userRole != 'Headowner') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You are not authorized to perform this action.'),
          ),
        );
        return;
      }

      double paidAmount = paidAmountString.isEmpty ? 0 : double.parse(paidAmountString);

      double amount =
          userType == 'Crew Member' ? double.parse(paymentDoc['amount'].toString() ?? '0') : 0;
      double remainingAmountShare = userType == 'Owner'
          ? double.parse(paymentDoc['remainingamountshare'].toString() ?? '0')
          : 0;

      double pendingAmount =
          userType == 'Crew Member' ? (amount - paidAmount) : (remainingAmountShare - paidAmount);

      await paymentDoc.reference.update({
        'paidamount': paidAmount.toString(),
        'pendingamount': pendingAmount.toString(),
        'date': selectedDate,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Paid amount updated successfully.'),
        ),
      );
      setState(() {});
    } catch (e) {
      print('Error updating paid amount: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating paid amount. Please try again.'),
        ),
      );
    }
  }

  void _showFilterByDateDialog() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selectedDate != null) {
      setState(() {
        _activeFilter = FilterType.Date;
        _selectedDate = selectedDate;
        _selectedPaymentStatus = '';
        // Update filter states for Crew Member Payments
        _crewMemberActiveFilter = _activeFilter;
        _crewMemberSelectedDate = _selectedDate;
        _crewMemberSelectedPaymentStatus = _selectedPaymentStatus;
        // Update filter states for Owner Payments
        _ownerActiveFilter = _activeFilter;
        _ownerSelectedDate = _selectedDate;
        _ownerSelectedPaymentStatus = _selectedPaymentStatus;
      });
    }
  }

  void _showFilterByPaymentDialog() {
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
                    _activeFilter = FilterType.Payment;
                    _selectedPaymentStatus = 'Paid';
                    _selectedDate = null;
                    // Update filter states for Crew Member Payments
                    _crewMemberActiveFilter = _activeFilter;
                    _crewMemberSelectedDate = _selectedDate;
                    _crewMemberSelectedPaymentStatus = _selectedPaymentStatus;
                    // Update filter states for Owner Payments
                    _ownerActiveFilter = _activeFilter;
                    _ownerSelectedDate = _selectedDate;
                    _ownerSelectedPaymentStatus = _selectedPaymentStatus;
                  });
                  Navigator.pop(context);
                },
                child: Text('Paid'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedPaymentStatus = 'Not Paid';
                    _selectedDate = null;
                    // Update filter states for Crew Member Payments
                    _crewMemberActiveFilter = _activeFilter;
                    _crewMemberSelectedDate = _selectedDate;
                    _crewMemberSelectedPaymentStatus = _selectedPaymentStatus;
                    // Update filter states for Owner Payments
                    _ownerActiveFilter = _activeFilter;
                    _ownerSelectedDate = _selectedDate;
                    _ownerSelectedPaymentStatus = _selectedPaymentStatus;
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
}
