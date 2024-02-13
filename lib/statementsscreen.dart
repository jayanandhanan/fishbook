import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fishbook/home_screen.dart';
import 'package:fishbook/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StatementScreen extends StatefulWidget {
  @override
  _StatementScreenState createState() => _StatementScreenState();
}

class _StatementScreenState extends State<StatementScreen> {
  String? organizationId;
  String role = '';
  bool isHomeScreen = false;
  bool isStatementsScreen = true;
  int? selectedYear;
  int? selectedMonth;
  double _totalAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchOrganizationIdAndUserRole();
  }

  void _calculateTotalAmount(List<QueryDocumentSnapshot> combinedData) {
    double totalAmount = 0.0;

    combinedData.forEach((doc) {
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        String? amountString;

        if (data.containsKey('amount')) {
          amountString = data['amount'].toString();
        } else if (data.containsKey('remainingamountshare')) {
          amountString = data['remainingamountshare'].toString();
        } else if (data.containsKey('paidamount')) {
          amountString = data['paidamount'].toString();
        }

        if (amountString != null && amountString.isNotEmpty) {
          try {
            double amount = double.parse(amountString);
            totalAmount += amount;
          } catch (e) {
            print('Error parsing amount: $e');
            print(amountString);
          }
        }
      }
    });

    if (_totalAmount != totalAmount) {
      setState(() {
        _totalAmount = totalAmount;
      });
    }
  }

  Future<void> _fetchOrganizationIdAndUserRole() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      String? userOrganizationId = userDoc.get('organizationId');
      String? userRole = userDoc.get('role');

      if (userOrganizationId != null && userRole != null) {
        setState(() {
          organizationId = userOrganizationId;
          role = userRole;
        });
      } else {
        // Handle the case where organizationId or user role is not found
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Overall Statements'),
        backgroundColor: Colors.blue,
      ),
      bottomNavigationBar: buildBottomNavigationBar(context, false, true),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: [
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DropdownButton<int>(
                  hint: Text('Select Year'),
                  value: selectedYear,
                  onChanged: (int? year) {
                    setState(() {
                      selectedYear = year;
                    });
                  },
                  items: List.generate(
                    DateTime.now().year - 2020 + 21,
                    (index) => DropdownMenuItem<int>(
                      value: 2020 + index,
                      child: Text('${2020 + index}'),
                    ),
                  ),
                ),
                SizedBox(width: 20),
                DropdownButton<int>(
                  hint: Text('Select Month'),
                  value: selectedMonth,
                  onChanged: (int? month) {
                    setState(() {
                      selectedMonth = month;
                    });
                  },
                  items: List.generate(
                    12,
                    (index) => DropdownMenuItem<int>(
                      value: index + 1,
                      child: Text('${index + 1}'),
                    ),
                  ),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedYear = null;
                      selectedMonth = null;
                    });
                  },
                  child: Text('Remove Filters'),
                ),
              ],
            ),
            SizedBox(height: 20),
            FutureBuilder<List<QueryDocumentSnapshot>>(
              future: _fetchStatements(role),
              builder: (context,
                  AsyncSnapshot<List<QueryDocumentSnapshot>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  List<QueryDocumentSnapshot> combinedData = snapshot.data!;
                  List<QueryDocumentSnapshot> filteredCombinedData = [];

                  if (selectedYear != null && selectedMonth == null) {
                    filteredCombinedData = combinedData.where((doc) {
                      if (doc['paymentdate'] != null) {
                        DateTime timestamp =
                            (doc['paymentdate'] as Timestamp).toDate();
                        return timestamp.year == selectedYear;
                      }
                      return false;
                    }).toList();
                  } else if (selectedYear != null && selectedMonth != null) {
                    filteredCombinedData = combinedData.where((doc) {
                      if (doc['paymentdate'] != null) {
                        DateTime timestamp =
                            (doc['paymentdate'] as Timestamp).toDate();
                        return timestamp.year == selectedYear &&
                            timestamp.month == selectedMonth;
                      }
                      return false;
                    }).toList();
                  } else if (selectedYear == null && selectedMonth != null) {
                    filteredCombinedData = combinedData.where((doc) {
                      if (doc['paymentdate'] != null) {
                        DateTime timestamp =
                            (doc['paymentdate'] as Timestamp).toDate();
                        return timestamp.month == selectedMonth;
                      }
                      return false;
                    }).toList();
                  } else {
                    filteredCombinedData = combinedData;
                  }

                  WidgetsBinding.instance!.addPostFrameCallback((_) {
                    _calculateTotalAmount(filteredCombinedData);
                  });

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black),
                        ),
                        child: DataTable(
                          showCheckboxColumn: false,
                          columnSpacing: 16.0,
                          headingRowColor: MaterialStateColor.resolveWith(
                              (states) => Color(0xFFF9D8C5)),
                          dividerThickness: 1.0,
                          columns: [
                            DataColumn(label: Text('Payment Date')),
                            DataColumn(label: Text('Amount')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Mode of Payment')),
                            DataColumn(label: Text('Amount Given To')),
                          ],
                          rows: _buildDataRows(filteredCombinedData),
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
            Text(
              'Total Amount: $_totalAmount',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  BottomNavigationBar buildBottomNavigationBar(
      BuildContext context, bool isHomeScreen, bool isStatementsScreen) {
    return BottomNavigationBar(
      currentIndex: 1,
      fixedColor: isStatementsScreen ? Colors.blue : Color(0x862195F3),
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home, color: Colors.grey),
          label: 'Home',
          backgroundColor: Color(0xFFF9D8C5),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.wrap_text,
              color: isStatementsScreen ? Colors.blue : null),
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
            if (!isStatementsScreen)
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

  List<DataRow> _buildDataRows(List<QueryDocumentSnapshot> combinedData) {
    List<DataRow> rows = [];

    combinedData.forEach((doc) {
      Timestamp timestamp = doc['paymentdate'] ?? Timestamp.now();
      String formattedDate = DateFormat('dd-MM-yyyy').format(timestamp.toDate());

      String amount = '';
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('amount')) {
          amount = data['amount'].toString();
        } else if (data.containsKey('remainingamountshare')) {
          amount = data['remainingamountshare'].toString();
        } else if (data.containsKey('paidamount')) {
          amount = data['paidamount'].toString();
        }
      }

      String status = doc['payment'] ?? '';
      String modeOfPayment = doc['modeofpayment'] ?? '';
      String amountGivenTo = '';
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('name')) {
          amountGivenTo = data['name'].toString();
        } else if (data.containsKey('incharge')) {
          amountGivenTo = data['incharge'].toString();
        } else {
          amountGivenTo = data['name'];
        }
      }

      rows.add(DataRow(cells: [
        DataCell(Text(formattedDate)),
        DataCell(Text(amount)),
        DataCell(Text(status)),
        DataCell(Text(modeOfPayment)),
        DataCell(Text(amountGivenTo)),
      ]));
    });

    return rows;
  }

  Future<List<QueryDocumentSnapshot>> _fetchStatements(String userRole) async {
    List<QueryDocumentSnapshot> combinedData = [];

    QuerySnapshot paymentDetailsSnapshot;
    QuerySnapshot workManagementSnapshot;
    QuerySnapshot maintenancePaymentsSnapshot;

    if (role == 'Crewmember') {
      paymentDetailsSnapshot = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(organizationId)
          .collection('paymentdetails')
          .where('user', isEqualTo: 'Crew Member')
          .get();

      workManagementSnapshot = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(organizationId)
          .collection('workmanagement')
          .where('user', isEqualTo: 'Crew Member')
          .get();

      maintenancePaymentsSnapshot = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(organizationId)
          .collection('maintenancepayments')
          .get();
    } else {
      paymentDetailsSnapshot = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(organizationId)
          .collection('paymentdetails')
          .get();

      workManagementSnapshot = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(organizationId)
          .collection('workmanagement')
          .get();

      maintenancePaymentsSnapshot = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(organizationId)
          .collection('maintenancepayments')
          .get();
    }

    combinedData.addAll(paymentDetailsSnapshot.docs);
    combinedData.addAll(workManagementSnapshot.docs);
    combinedData.addAll(maintenancePaymentsSnapshot.docs);

    combinedData.sort((a, b) {
      DateTime dateA = (a['paymentdate'] as Timestamp).toDate();
      DateTime dateB = (b['paymentdate'] as Timestamp).toDate();
      return dateA.compareTo(dateB);
    });

    return combinedData;
  }
}
