// ignore_for_file: unused_local_variable
import 'dart:math';
import 'package:fishbook/home_screen.dart';
import 'package:fishbook/login_screen.dart';
import 'package:fishbook/newentryscreen.dart';
import 'package:fishbook/statementsscreen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseScreen extends StatefulWidget {
  @override
  _DatabaseScreenState createState() => _DatabaseScreenState();
}

class _DatabaseScreenState extends State<DatabaseScreen> {
   String organizationId = ''; // To store the organizationId of the current user
   String role ='';
   bool isHomeScreen = false;
   DateTime? selectedDate;
  @override
  void initState() {
    super.initState();
    _fetchOrganizationIdAndUserRole(); // Fetch organizationId when the screen initializes
  }

 Future<void> _fetchOrganizationIdAndUserRole() async {
  // Fetch organizationId and user role based on the current user's UID
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    // Fetch user document from Firestore
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    // Extract organizationId and user role from the user document
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

  Future<void> _updateTotalProfit(String documentId) async {
    try {
      var revenueSnapshot = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(organizationId)
          .collection('newentry')
          .doc(documentId)
          .collection('revenue')
          .get();

      var expenseSnapshot = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(organizationId)
          .collection('newentry')
          .doc(documentId)
          .collection('expense')
          .get();

      double totalRevenue = revenueSnapshot.docs
          .map((doc) => (doc['amount'] as double?) ?? 0.0)
          .fold(0.0, (sum, amount) => sum + amount);

      double totalExpense = expenseSnapshot.docs
          .map((doc) => (doc['expenseamount'] as double?) ?? 0.0)
          .fold(0.0, (sum, amount) => sum + amount);

      double totalProfit = totalRevenue - totalExpense;

      await FirebaseFirestore.instance
          .collection('organizations')
          .doc(organizationId)
          .collection('newentry')
          .doc(documentId)
          .update({'totalprofit': totalProfit});

         
          _updateRemainingAmount(documentId);

      setState(() {});
      
    } catch (e) {
      print('Error updating total profit: $e');
      // Handle error, show a snackbar, or any other appropriate action
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Database Screen'),
        backgroundColor: Colors.blue,
      ),
      bottomNavigationBar: buildBottomNavigationBar(context, false),
      body: organizationId.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () => _showFilterDialog(),
                        child: Text('Filter'),
                      ),
                      ElevatedButton(
                        onPressed: () => _resetFilter(),
                        child: Text('Reset Filter'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildDatabaseScreen(),
                ),
              ],
            ),
              floatingActionButton: Visibility(
      visible: role == 'Headowner', // Show the FAB only if the role is Headowner
      child: FloatingActionButton(
        onPressed: () {
          // Navigate to the new entry screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => NewEntryScreen()),
          );
        },
        child: Icon(Icons.add),
        backgroundColor: Color.fromARGB(255, 235, 235, 235),
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
                  MaterialPageRoute(builder: (context) => HomeScreen(organizationId: organizationId)),
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
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              });
              break;
          }
        });
      },
    );
  }


void _showFilterDialog() async {
  DateTime? pickedDate = await showDatePicker(
    context: context,
    initialDate: selectedDate ?? DateTime.now(),
    firstDate: DateTime(2000),
    lastDate: DateTime(2101),
  );

  if (pickedDate != null) {
    setState(() {
      selectedDate = pickedDate;
    });
  }
}

void _filterBySailingDate(DateTime date) {
  setState(() {
    selectedDate = date;
  });
}
  // Method to reset the filter
  void _resetFilter() {
    setState(() {
      selectedDate = null;
    });
  }

bool _isSameDay(DateTime date1, DateTime date2) {
  return date1.year == date2.year &&
      date1.month == date2.month &&
      date1.day == date2.day;
}

Widget _buildDatabaseScreen() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('organizations')
        .doc(organizationId)
        .collection('newentry')
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      }

      if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}'));
      }

      var documents = snapshot.data!.docs;

       // Filter documents based on selected date
      if (selectedDate != null) {
        documents = documents
            .where((doc) =>
                doc['sailingdate'] != null &&
                _isSameDay(doc['sailingdate'].toDate(), selectedDate!))
            .toList();
      }

      return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: [
            for (var document in documents) ...[
              _buildMainDocumentFields(document),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                     child: Visibility(
                     visible: role == 'Headowner',
                    child: ElevatedButton(
                      onPressed: () {
                        _showDeleteConfirmationDialog(context, document.id, role);
                      },
                      child: Text('Delete Entry'),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _buildRevenueExpenseTable(document.id),
              ),
              SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _buildCrewMembersTable(document.id),
              ),
              SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _buildOwnersShareTable(document.id),
              ),
            ],
          ],
        ),
      );
    },
  );
}

void _showDeleteConfirmationDialog(BuildContext context, String documentId, String userRole) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete this entry?'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _deleteNewEntryDocument(documentId, userRole);
              Navigator.of(context).pop(); // Close the dialog
            },
            child: Text('Delete'),
          ),
        ],
      );
    },
  );
}

void _deleteNewEntryDocument(String documentId, String userRole) async {
  if (userRole != 'Headowner') {
    print('You do not have access to delete the entire entry.');
    return;
  }

  try {
    final DocumentReference newEntryDocRef = FirebaseFirestore.instance
        .collection('organizations')
        .doc(organizationId)
        .collection('newentry')
        .doc(documentId);

    // Delete associated documents in the paymentdetails subcollection
    QuerySnapshot paymentDetailsSnapshot = await FirebaseFirestore.instance
        .collection('organizations')
        .doc(organizationId)
        .collection('paymentdetails')
        .where('newentryid', isEqualTo: documentId)
        .get();

    for (DocumentSnapshot doc in paymentDetailsSnapshot.docs) {
      await doc.reference.delete();
    }

    // Delete the newentry document itself
    await newEntryDocRef.delete();


        // Delete the associated document in the boatmaintenanceamounts subcollection
    await FirebaseFirestore.instance
        .collection('organizations')
        .doc(organizationId)
        .collection('boatmaintenanceamounts')
        .doc(documentId)
        .delete();

    // Optionally, you can show a success message or perform other actions
  } catch (e) {
    print('Error deleting the entire entry: $e');
    // Handle error, show a snackbar, or any other appropriate action
  }
}


  Widget _buildMainDocumentFields(QueryDocumentSnapshot document) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Sailing Date: ${_formatDate(document['sailingdate'])}'),
              if (role == 'Headowner')
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () => _editSailingDate(
                    document.id, document['sailingdate'] as Timestamp,role),
              ),
            ],
          ),
          Row(
            children: [
              Text('Return Date: ${_formatDate(document['returndate'])}'),
              if (role == 'Headowner')
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () => _editReturnDate(
                    document.id, document['returndate'] as Timestamp,role),
              ),
            ],
          ),
          Row(
            children: [
              Text('Month Considered: ${document['monthconsidered']}'),
              if (role == 'Headowner')
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () => _editMonthConsidered(
                    document.id, document['monthconsidered'] as String,role),
              ),
            ],
          ),
          Row(
          children: [
            Text('Boat Maintenance Amount: ${document['boatmaintenanceamount'] ?? 'N/A'}'),
            if (role == 'Headowner')
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => _editBoatMaintenanceAmount(document.id, document['boatmaintenanceamount'] ?? 0.0),
            ),
          ],
        ),
          Text('Total Profit: ${document['remainingamount']}'),
        ],
      ),
    );
  }



void _editBoatMaintenanceAmount(String documentId, double currentAmount) async {
  double? newAmount = await showDialog<double>(
    context: context,
    builder: (BuildContext context) {
      double? amount;
      return AlertDialog(
        title: Text('Edit Boat Maintenance Amount'),
        content: TextFormField(
          keyboardType: TextInputType.number,
          initialValue: currentAmount.toString(),
          onChanged: (value) {
            amount = double.tryParse(value);
          },
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(amount);
            },
            child: Text('Save'),
          ),
        ],
      );
    },
  );

  if (newAmount != null) {
    try {
      // Update the boatmaintenanceamount field in the newentry document
      await FirebaseFirestore.instance
          .collection('organizations')
          .doc(organizationId)
          .collection('newentry')
          .doc(documentId)
          .update({'boatmaintenanceamount': newAmount});

          await _updateRemainingAmount(documentId);

      // Update the remainingboatmaintenanceamount field in the boatmaintenanceamounts subcollection
      await _updateRemainingBoatMaintenanceAmount(documentId, newAmount);

      // Reload the data after editing
      setState(() {});
    } catch (e) {
      print('Error updating boat maintenance amount: $e');
      // Handle error, show a snackbar, or any other appropriate action
    }
  }
}

Future<void> _updateRemainingBoatMaintenanceAmount(String documentId, double newAmount) async {
  try {
    // Retrieve the document from the boatmaintenanceamounts subcollection
    DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
        .collection('organizations')
        .doc(organizationId)
        .collection('boatmaintenanceamounts')
        .doc(documentId)
        .get();

    // Get the usedamount field from the document
    double usedAmount = docSnapshot.get('usedamount') ?? 0.0;

    // Calculate the remainingboatmaintenanceamount by subtracting usedAmount from newAmount
    double remainingAmount = newAmount - usedAmount;

    // Update the remainingboatmaintenanceamount field in the boatmaintenanceamounts subcollection
    await FirebaseFirestore.instance
        .collection('organizations')
        .doc(organizationId)
        .collection('boatmaintenanceamounts')
        .doc(documentId)
        .update({'remainingboatmaintenanceamount': remainingAmount,'boatmaintenanceamount':newAmount});
  } catch (e) {
    print('Error updating remaining boat maintenance amount: $e');
    // Handle error, show a snackbar, or any other appropriate action
  }
}


  Widget _buildDateField(
      String label, Timestamp date, VoidCallback editFunction) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Row(
          children: [
            Text(_formatDate(date), style: TextStyle(fontWeight: FontWeight.bold)),
            if (role == 'Headowner')
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: editFunction,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMonthConsideredField(
      String label, String monthConsidered, VoidCallback editFunction) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Row(
          children: [
            Text(monthConsidered, style: TextStyle(fontWeight: FontWeight.bold)),
            if (role == 'Headowner')
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: editFunction,
            ),
          ],
        ),
      ],
    );
  }

double _calculateCrewMemberSalary(QuerySnapshot salarySnapshot) {
  double totalSalary = salarySnapshot.docs
      .map((doc) => (doc['amount'] as double?) ?? 0.0)
      .fold(0.0, (sum, amount) => sum + amount);

  return totalSalary;
}

double _calculateRemainingAmount(double totalProfit, double crewMemberSalary, double boatMaintenanceAmount) {
  return totalProfit - crewMemberSalary - boatMaintenanceAmount;
}


Future<void> _updateRemainingAmount(String documentId) async {
  try {
    var revenueSnapshot = await FirebaseFirestore.instance
        .collection('organizations')
        .doc(organizationId)
        .collection('newentry')
        .doc(documentId)
        .collection('revenue')
        .get();

    var expenseSnapshot = await FirebaseFirestore.instance
        .collection('organizations')
        .doc(organizationId)
        .collection('newentry')
        .doc(documentId)
        .collection('expense')
        .get();

    var salarySnapshot = await FirebaseFirestore.instance
        .collection('organizations')
        .doc(organizationId)
        .collection('newentry')
        .doc(documentId)
        .collection('salarytocrewmembers')
        .get();

    double totalRevenue = revenueSnapshot.docs
        .map((doc) => (doc['amount'] as double?) ?? 0.0)
        .fold(0.0, (sum, amount) => sum + amount);

    double totalExpense = expenseSnapshot.docs
        .map((doc) => (doc['expenseamount'] as double?) ?? 0.0)
        .fold(0.0, (sum, amount) => sum + amount);

    double totalProfit = totalRevenue - totalExpense;

    double crewMemberSalary = _calculateCrewMemberSalary(salarySnapshot);

    var documentSnapshot = await FirebaseFirestore.instance
        .collection('organizations')
        .doc(organizationId)
        .collection('newentry')
        .doc(documentId)
        .get();

    double boatMaintenanceAmount =
        (documentSnapshot['boatmaintenanceamount'] as double?) ?? 0.0;

    double remainingAmount =
        totalProfit - crewMemberSalary - boatMaintenanceAmount;

    await FirebaseFirestore.instance
        .collection('organizations')
        .doc(organizationId)
        .collection('newentry')
        .doc(documentId)
        .update({'remainingamount': remainingAmount});

    await _updateRemainingAmountShare(documentId);

    setState(() {});
  } catch (e) {
    print('Error updating remaining amount: $e');
    // Handle error, show a snackbar, or any other appropriate action
  }
}



 void _editSailingDate(
    String documentId, Timestamp sailingDate, String userRole) async {
  if (userRole != 'Headowner') {
    print('You do not have access to edit the sailing date.');
    return;
  }

  DateTime currentDate = sailingDate.toDate();
  DateTime? pickedDate = await showDatePicker(
    context: context,
    initialDate: currentDate,
    firstDate: DateTime(2000),
    lastDate: DateTime(2101),
  );

  if (pickedDate != null && pickedDate != currentDate) {
    try {
      // Update Firestore with edited sailing date
      await FirebaseFirestore.instance
          .collection('organizations')
          .doc(organizationId)
          .collection('newentry')
          .doc(documentId)
          .update({'sailingdate': pickedDate});

      // Reload the data after editing
      setState(() {});
    } catch (e) {
      print('Error updating sailing date: $e');
      // Handle error, show a snackbar, or any other appropriate action
    }
  }
}

 void _editReturnDate(
    String documentId, Timestamp returnDate, String userRole) async {
  if (userRole != 'Headowner') {
    print('You do not have access to edit the return date.');
    return;
  }

  DateTime currentDate = returnDate.toDate();
  DateTime? pickedDate = await showDatePicker(
    context: context,
    initialDate: currentDate,
    firstDate: DateTime(2000),
    lastDate: DateTime(2101),
  );

  if (pickedDate != null && pickedDate != currentDate) {
    try {
      // Update Firestore with edited return date
      await FirebaseFirestore.instance
          .collection('organizations')
          .doc(organizationId)
          .collection('newentry')
          .doc(documentId)
          .update({'returndate': pickedDate});

      // Reload the data after editing
      setState(() {});
    } catch (e) {
      print('Error updating return date: $e');
      // Handle error, show a snackbar, or any other appropriate action
    }
  }
}

void _editMonthConsidered(
    String documentId, String monthConsidered, String userRole) async {
  if (userRole != 'Headowner') {
    print('You do not have access to edit the month considered.');
    return;
  }

  List<String> monthsList = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  int selectedMonthIndex = monthsList.indexOf(monthConsidered);

  if (selectedMonthIndex != -1) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Month Considered'),
          content: DropdownButton<String>(
            value: monthsList[selectedMonthIndex],
            items: monthsList.map((String month) {
              return DropdownMenuItem<String>(
                value: month,
                child: Text(month),
              );
            }).toList(),
            onChanged: (String? selectedMonth) async {
              if (selectedMonth != null) {
                try {
                  // Update Firestore with edited month considered
                  await FirebaseFirestore.instance
                      .collection('organizations')
                      .doc(organizationId)
                      .collection('newentry')
                      .doc(documentId)
                      .update({'monthconsidered': selectedMonth});

                  // Reload the data after editing
                  setState(() {});
                } catch (e) {
                  print('Error updating month considered: $e');
                  // Handle error, show a snackbar, or any other appropriate action
                }
              }
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  } else {
    // Handle the case where the selected month is not found in the list
    print('Error: Selected month not found in the list.');
    // You can display a message or take other appropriate actions.
  }
}

Widget _buildRevenueExpenseTable(String documentId) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      FutureBuilder(
        future: _fetchRevenueExpenseSubcollections(documentId),
        builder: (context, AsyncSnapshot<List<QuerySnapshot>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }

          var revenueSnapshot = snapshot.data![0];
          var expenseSnapshot = snapshot.data![1];

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
                DataColumn(label: Text('Revenue Amount')),
                DataColumn(label: Text('Expense Name')),
                DataColumn(label: Text('Expense Amount')),
                if (role == 'Headowner')
                DataColumn(label: Text('Actions')),
              ],
              rows: _buildRevenueExpenseRows(
                documentId, revenueSnapshot, expenseSnapshot),
            ),
          ),),);
        },
      ),
      SizedBox(height: 10),
      Padding(
        padding: const EdgeInsets.only(left: 16.0),
         child: Visibility(
        visible: role == 'Headowner',
        child: ElevatedButton(
          onPressed: () => _addRevenueExpense(documentId),
          child: Text('Add Revenue/Expense'),
        ),
        ),
      ),
    ],
  );
}

List<DataRow> _buildRevenueExpenseRows(
    String documentId, QuerySnapshot? revenue, QuerySnapshot? expense) {
  List<DataRow> rows = [];

  // Check if both revenue and expense snapshots are not null
  if (revenue != null && expense != null) {
    int rowCount = max(revenue.docs.length, expense.docs.length);
    for (int i = 0; i < rowCount; i++) {
      var revenueDoc = i < revenue.docs.length ? revenue.docs[i] : null;
      var expenseDoc = i < expense.docs.length ? expense.docs[i] : null;

      double revenueAmount = revenueDoc != null ? (revenueDoc['amount'] as num?)?.toDouble() ?? 0.0 : 0.0;
      String expenseName = expenseDoc != null ? expenseDoc['expensename']?.toString() ?? '' : 'N/A';
      double expenseAmount = expenseDoc != null ? (expenseDoc['expenseamount'] as num?)?.toDouble() ?? 0.0 : 0.0;

      rows.add(DataRow(cells: [
        DataCell(Text('$revenueAmount')), // Convert to String for display
        DataCell(Text(expenseName)),
        DataCell(Text('$expenseAmount')), // Convert to String for display
        DataCell(
          Row(
            children: [
              if (role == 'Headowner') // Always show action icons
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    _editRevenueExpense(documentId, revenueDoc, expenseDoc, role);
                  },
                ),
              if (role == 'Headowner') // Always show action icons
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    _deleteRevenueExpense(documentId, revenueDoc, expenseDoc, role);
                  },
                ),
            ],
          ),
        ),
      ]));
    }
  }

  return rows;
}


void _addRevenueExpense(String documentId) {
    TextEditingController revenueController =
        TextEditingController();
    TextEditingController expenseNameController =
        TextEditingController();
    TextEditingController expenseAmountController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Revenue/Expense'),
          content: Column(
            children: [
              TextField(
                controller: revenueController,
                decoration: InputDecoration(labelText: 'Revenue Amount'),
              ),
              TextField(
                controller: expenseNameController,
                decoration: InputDecoration(labelText: 'Expense Name'),
              ),
              TextField(
                controller: expenseAmountController,
                decoration: InputDecoration(labelText: 'Expense Amount'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                double revenueAmount =
                    double.tryParse(revenueController.text) ?? 0.0;
                String expenseName = expenseNameController.text.isNotEmpty
                    ? expenseNameController.text
                    : 'N/A';
                double expenseAmount =
                    double.tryParse(expenseAmountController.text) ?? 0.0;

                // Add data to Firestore
                await FirebaseFirestore.instance
                    .collection('organizations')
                    .doc(organizationId)
                    .collection('newentry')
                    .doc(documentId)
                    .collection('revenue')
                    .add({
                  'amount': revenueAmount,
                });

                await FirebaseFirestore.instance
                    .collection('organizations')
                    .doc(organizationId)
                    .collection('newentry')
                    .doc(documentId)
                    .collection('expense')
                    .add({
                  'expensename': expenseName,
                  'expenseamount': expenseAmount,
                });

                Navigator.pop(context);

                // Reload the data after adding
                      if (mounted) { // Check if the widget is still mounted
        setState(() {});
      }             

                // Update totalprofit after adding
                await _updateTotalProfit(documentId);
                _updateRemainingAmount(documentId);
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

void _editRevenueExpense(String documentId, DocumentSnapshot? revenue,
    DocumentSnapshot? expense, String userRole) async {
  if (userRole != 'Headowner') {
    print('You do not have access to edit revenue and expense.');
    return;
  }

  TextEditingController revenueController =
      TextEditingController(text: revenue?['amount']?.toString() ?? '0');
  TextEditingController expenseNameController =
      TextEditingController(text: expense?['expensename']?.toString() ?? '');
  TextEditingController expenseAmountController = TextEditingController(
      text: expense?['expenseamount']?.toString() ?? '0');

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Edit Revenue and Expense'),
        content: Column(
          children: [
            TextField(
              controller: revenueController,
              decoration: InputDecoration(labelText: 'Revenue Amount'),
            ),
            TextField(
              controller: expenseNameController,
              decoration: InputDecoration(labelText: 'Expense Name'),
            ),
            TextField(
              controller: expenseAmountController,
              decoration: InputDecoration(labelText: 'Expense Amount'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                // Parse revenue amount to double, set to 0 if empty
                double parsedRevenueAmount =
                    double.tryParse(revenueController.text) ?? 0.0;

                // Parse expense amount to double, set to 0 if empty
                double parsedExpenseAmount =
                    double.tryParse(expenseAmountController.text) ?? 0.0;

                // Update Firestore with edited data
                await FirebaseFirestore.instance
                    .collection('organizations')
                    .doc(organizationId)
                    .collection('newentry')
                    .doc(documentId)
                    .collection('revenue')
                    .doc(revenue?.id ?? 'revenue_document')
                    .set({
                  'amount': parsedRevenueAmount,
                }, SetOptions(merge: true));

                await FirebaseFirestore.instance
                    .collection('organizations')
                    .doc(organizationId)
                    .collection('newentry')
                    .doc(documentId)
                    .collection('expense')
                    .doc(expense?.id ?? 'expense_document')
                    .set({
                  'expensename': expenseNameController.text,
                  'expenseamount': parsedExpenseAmount,
                }, SetOptions(merge: true));

                Navigator.pop(context);

                // Reload the data after editing
                if (mounted) {
                  setState(() {});
                }
                // Update total profit after editing
                await _updateTotalProfit(documentId);
                _updateRemainingAmount(documentId);
              } catch (e) {
                print('Error updating revenue and expense: $e');
                // Handle error, show a snackbar, or any other appropriate action
              }
            },
            child: Text('Update'),
          ),
        ],
      );
    },
  );
}

void _deleteRevenueExpense(String documentId, DocumentSnapshot? revenue,
    DocumentSnapshot? expense, String userRole) async {
  if (userRole != 'Headowner') {
    print('You do not have access to delete revenue and expense.');
    return;
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Confirm Deletion'),
        content: Text(
            'Are you sure you want to delete this revenue and expense entries?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                // Delete the revenue document if not null
                if (revenue != null) {
                  await FirebaseFirestore.instance
                      .collection('organizations')
                      .doc(organizationId)
                      .collection('newentry')
                      .doc(documentId)
                      .collection('revenue')
                      .doc(revenue.id)
                      .delete();
                }

                // Delete the expense document if not null
                if (expense != null) {
                  await FirebaseFirestore.instance
                      .collection('organizations')
                      .doc(organizationId)
                      .collection('newentry')
                      .doc(documentId)
                      .collection('expense')
                      .doc(expense.id)
                      .delete();
                }

                Navigator.pop(context); // Close the dialog

                // Reload the data after deleting
                if (mounted) {
                  setState(() {});
                }

                // Update total profit after deleting
                await _updateTotalProfit(documentId);
                await _updateRemainingAmount(documentId);
              } catch (e) {
                print('Error deleting revenue and expense: $e');
                // Handle error, show a snackbar, or any other appropriate action
              }
            },
            child: Text('Delete'),
          ),
        ],
      );
    },
  );
}

  Future<List<QuerySnapshot>> _fetchRevenueExpenseSubcollections(
      String documentId) async {
    try {
      var revenue = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(organizationId)
          .collection('newentry')
          .doc(documentId)
          .collection('revenue')
          .get();

      var expense = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(organizationId)
          .collection('newentry')
          .doc(documentId)
          .collection('expense')
          .get();

      return [revenue, expense];
    } catch (e) {
      print('Error fetching subcollections: $e');
      return [];
    }
  }

Widget _buildCrewMembersTable(String documentId) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      FutureBuilder(
        future: _fetchCrewMembersSalarySubcollection(documentId),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }

          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          var documents = snapshot.data!.docs;

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
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('Phone')),
                DataColumn(label: Text('Amount')),
                if (role == 'Headowner')
                DataColumn(label: Text('Actions')),
              ],
              rows: _buildCrewMembersRows(documents,documentId),
            ),
          ),),);
        },
      ),
      SizedBox(height: 20), // Add spacing between DataTable and button
      Padding(
        padding: const EdgeInsets.only(left: 16.0),
         child: Visibility(
        visible: role == 'Headowner',
        child: ElevatedButton(
          onPressed: () => _addCrewMemberToSalary(documentId),
          
          child: Text('Add Crew Member'),
        ),
        ),
      ),
    ],
  );
}

List<DataRow> _buildCrewMembersRows(List<DocumentSnapshot> documents, String documentId) {
  List<DataRow> rows = [];

  documents.forEach((doc) {
    String name = doc['name'] ?? 'N/A'; // Handle null name
    String email = doc['email'] ?? 'N/A'; // Handle null email
    String phone = doc['phone'] ?? 'N/A'; // Handle null phone
    double amount = (doc['amount'] as num?)?.toDouble() ?? 0.0; // Parse as double and handle null amount

    // Add a DataRow for each crew member
    DataRow row = DataRow(cells: [
      DataCell(Text(name)),
      DataCell(Text(email)),
      DataCell(Text(phone)),
      DataCell(Text(amount.toString())),
      if (role == 'Headowner')
      DataCell(Row(
        // Create a row for action buttons
        children: [
          if (role == 'Headowner')
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              // Implement edit functionality
              _editCrewMemberSalary(doc.reference, role, documentId); // Pass the document ID for editing
            },
          ),
          if (role == 'Headowner')
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              // Implement delete functionality
              _deleteCrewMemberSalary(doc.reference, role, documentId); // Pass the document ID for deletion
            },
          ),
        ],
      )),
    ]);

    rows.add(row);
  });

  return rows;
}

void _editCrewMemberSalary(DocumentReference documentReference, String userRole, String documentId) {
  if (userRole != 'Headowner') {
    print('You do not have access to edit crew member salaries.');
    return;
  }

  TextEditingController amountController = TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Edit Crew Member Salary'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              decoration: InputDecoration(labelText: 'New Amount'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                // Check if the text field is empty, set newAmount to 0 if it's empty
                double newAmount = amountController.text.isNotEmpty ? double.parse(amountController.text) : 0.0;

                // Update the amount field in Firestore for salarytocrewmembers
                await documentReference.update({'amount': newAmount});

                // Fetch corresponding documents from paymentdetails
                QuerySnapshot paymentDetailsSnapshot = await FirebaseFirestore.instance
                    .collection('organizations')
                    .doc(organizationId)
                    .collection('paymentdetails')
                    .get();

                // Iterate through each payment detail document
                for (var paymentDetailDoc in paymentDetailsSnapshot.docs) {
                  String inchargeId = paymentDetailDoc['inchargeid'];
                  String newEntryId = paymentDetailDoc['newentryid'];

                  if (inchargeId == documentReference.id && newEntryId == documentId) {
                    // Calculate pending amount
                    double paidAmount = double.tryParse(paymentDetailDoc['paidamount'] ?? '0.0') ?? 0.0;
                    double pendingAmount = newAmount - paidAmount;

                    // Update pending amount in the paymentdetails document
                    await paymentDetailDoc.reference.update({'amount': newAmount.toString(), 'pendingamount': pendingAmount.toString()});
                  }
                }

                // Show a success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Crew member salary updated successfully'),
                  ),
                );

                Navigator.pop(context); // Close the dialog

                await _updateRemainingAmount(documentId);
                // Refresh the UI
                if (mounted) {
                  setState(() {});
                }

              } catch (e) {
                print('Error updating crew member salary: $e');
                // Show an error message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error updating crew member salary. Please try again.'),
                  ),
                );
              }
            },
            child: Text('Save'),
          ),
        ],
      );
    },
  );
}


void _deleteCrewMemberSalary(DocumentReference documentReference, String userRole, String documentId) {
  if (userRole != 'Headowner') {
    print('You do not have access to delete crew member salary entries.');
    return;
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete this crew member salary entry?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                // Delete the document from Firestore for salarytocrewmembers
                await documentReference.delete();

                // Delete the corresponding documents from paymentdetails
                QuerySnapshot paymentDetailsSnapshot = await FirebaseFirestore.instance
                    .collection('organizations')
                    .doc(organizationId)
                    .collection('paymentdetails')
                    .get();

                for (var paymentDetailDoc in paymentDetailsSnapshot.docs) {
                  String newEntryId = paymentDetailDoc['newentryid'];
                  String inchargeId = paymentDetailDoc['inchargeid'];

                  if (newEntryId == documentId && inchargeId == documentReference.id) {
                    await paymentDetailDoc.reference.delete();
                  }
                }

                // Show a success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Crew member salary entry deleted successfully'),
                  ),
                );

                Navigator.pop(context); // Close the dialog
                // Update the remaining amount
                await _updateRemainingAmount(documentId);

                // Refresh the UI
                    if (mounted) { // Check if the widget is still mounted
        setState(() {});
      }
              } catch (e) {
                print('Error deleting crew member salary entry: $e');
                // Show an error message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting crew member salary entry. Please try again.'),
                  ),
                );
              }
            },
            child: Text('Delete'),
          ),
        ],
      );
    },
  );
}

Future<QuerySnapshot> _fetchCrewMembersSalarySubcollection(String documentId) async {
  try {
    return await FirebaseFirestore.instance
        .collection('organizations')
        .doc(organizationId)
        .collection('newentry')
        .doc(documentId)
        .collection('salarytocrewmembers')
        .get();
  } catch (e) {
    print('Error fetching crew members salary: $e');
    throw e;
  }
}

Future<void> _addCrewMemberToSalary(String documentId) async {
  List<String> selectedCrewMembers = [];
  Map<String, double> crewMembersAmount = {};
  Map<String, Map<String, dynamic>> crewMembersDetails = {};

  // Get the current datetime
  DateTime currentDate = DateTime.now();

  try {
    // Fetch crew members' details (name, email, phone) from the subcollection
    QuerySnapshot crewMembersSnapshot = await FirebaseFirestore.instance
        .collection('organizations')
        .doc(organizationId)
        .collection('crewmemberdetails')
        .get();

    // Show dialog to select crew members and enter amounts
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Crew Members to Salary'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // List of crew members with checkboxes
                  for (var crewMember in crewMembersSnapshot.docs) ...[
                    CheckboxListTile(
                      title: Text(crewMember['name']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Email: ${crewMember['email']}'),
                          Text('Phone: ${crewMember['phone']}'),
                        ],
                      ),
                      value: selectedCrewMembers.contains(crewMember.id),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value!) {
                            selectedCrewMembers.add(crewMember.id);
                            crewMembersDetails[crewMember.id] = {
                              'name': crewMember['name'],
                              'email': crewMember['email'],
                              'phone': crewMember['phone'],
                            };
                          } else {
                            selectedCrewMembers.remove(crewMember.id);
                            crewMembersDetails.remove(crewMember.id);
                          }
                        });
                      },
                    ),
                  ],
                  // Input field for amount
                  TextField(
  decoration: InputDecoration(labelText: 'Amount'),
  keyboardType: TextInputType.number,
  onChanged: (value) {
    // Update amounts for selected crew members
    for (var crewMemberId in selectedCrewMembers) {
      // Check if value is null or empty, if so, set amount to 0.0
      double amount = (value != null && value.isNotEmpty) ? double.parse(value) : 0.0;
      crewMembersAmount[crewMemberId] = amount;
    }
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  // Check if crew members already exist in salarytocrewmembers
                  QuerySnapshot existingMembersSnapshot = await FirebaseFirestore.instance
                      .collection('organizations')
                      .doc(organizationId)
                      .collection('newentry')
                      .doc(documentId)
                      .collection('salarytocrewmembers')
                      .where(FieldPath.documentId, whereIn: selectedCrewMembers)
                      .get();

                  List<String> existingMembersIds =
                      existingMembersSnapshot.docs.map((e) => e.id).toList();

                  for (var crewMemberId in selectedCrewMembers) {
                    if (!existingMembersIds.contains(crewMemberId)) {
                      // Generate unique ID for paymentdetails document
                      String paymentDetailId = FirebaseFirestore.instance.collection('organizations').doc().id;

                      // Add to salarytocrewmembers subcollection
                      await FirebaseFirestore.instance
                          .collection('organizations')
                          .doc(organizationId)
                          .collection('newentry')
                          .doc(documentId)
                          .collection('salarytocrewmembers')
                          .doc(crewMemberId)
                          .set({
                        'name': crewMembersDetails[crewMemberId]!['name'],
                        'email': crewMembersDetails[crewMemberId]!['email'],
                        'phone': crewMembersDetails[crewMemberId]!['phone'],
                        'amount': crewMembersAmount[crewMemberId],
                      });

                      // Check if paymentdetails document already exists
                      QuerySnapshot paymentDetailsSnapshot = await FirebaseFirestore.instance
                          .collection('organizations')
                          .doc(organizationId)
                          .collection('paymentdetails')
                          .where('newentryid', isEqualTo: documentId)
                          .where('inchargeid', isEqualTo: crewMemberId)
                          .get();

                      if (paymentDetailsSnapshot.docs.isEmpty) {
                        // Add to paymentdetails subcollection with inchargeid and newentryid
                        await FirebaseFirestore.instance
                            .collection('organizations')
                            .doc(organizationId)
                            .collection('paymentdetails')
                            .doc(paymentDetailId)
                            .set({
                          'name': crewMembersDetails[crewMemberId]!['name'],
                          'email': crewMembersDetails[crewMemberId]!['email'],
                          'phone': crewMembersDetails[crewMemberId]!['phone'],
                          'amount': crewMembersAmount[crewMemberId],
                          'user': 'Crew Member',
                          'payment': 'Not Paid',
                          'paidamount':'0.0',
                          'pendingamount':'0.0',
                          'modeofpayment':'Cash',
                          'date': Timestamp.fromDate(currentDate),
                          'inchargeid': crewMemberId,
                          'newentryid': documentId,
                        });
                      }
                    } else {
                      // Crew member already exists in salarytocrewmembers
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Crew member with ID $crewMemberId already exists in salarytocrewmembers'),
                        ),
                      );
                    }
                  }

                  Navigator.pop(context);
                  await _updateRemainingAmount(documentId);
                  // Update UI
                      if (mounted) { // Check if the widget is still mounted
        setState(() {});
      }
                } catch (e) {
                  print('Error adding crew members to salary: $e');
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  } catch (e) {
    print('Error adding crew members to salary: $e');
  }
}

Widget _buildOwnersShareTable(String documentId) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: FutureBuilder(
          future: _fetchOwnerShareSubcollection(documentId),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            }

            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }

            var documents = snapshot.data!.docs;

            return SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                ),
                child: DataTable(
                  showCheckboxColumn: false,
                  columnSpacing: 16.0,
                  headingRowColor: MaterialStateColor.resolveWith((states) => Color(0xFFF9D8C5)),
                  dividerThickness: 1.0,
                  columns: [
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Phone')),
                    DataColumn(label: Text('Invest')),
                    DataColumn(label: Text('Share')),
                      DataColumn(label: Text('Share Amount')),
                    if (role == 'Headowner') DataColumn(label: Text('Actions')),
                  ],
                  rows: _buildOwnersShareRows(documents, documentId),
                ),
              ),
            );
          },
        ),
      ),
      SizedBox(height: 20), // Adjust the spacing between the table and the button
      Visibility(
        visible: role == 'Headowner',
        child: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: ElevatedButton(
            onPressed: () => _addOwnerToShare(documentId),
            child: Text('Add Owner'),
          ),
        ),
      ),
    ],
  );
}

List<DataRow> _buildOwnersShareRows(List<QueryDocumentSnapshot> documents, String documentId) {
  List<DataRow> rows = [];

  for (var document in documents) {
    String ownerId = document.id;
    String name = document['name'] ?? '';
    String email = document['email'] ?? '';
    String phone = document['phone'] ?? '';
    String invest = document['invest'] ?? '0.0'; 
    String share = document['share'] ?? '0.0'; 
    String remainingAmountShare = document['remainingamountshare'] ?? '0.0'; 

    rows.add(DataRow(cells: [
      DataCell(Text(name)),
      DataCell(Text(email)),
      DataCell(Text(phone)),
      DataCell(Text(invest)),
      DataCell(Text(share)),
      DataCell(Text(remainingAmountShare)),
      if (role == 'Headowner')
        DataCell(Row(
          children: [
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => _deleteOwnerShare(documentId, ownerId, role),
            ),
          ],
        )),
    ]));
  }

  return rows;
}

Future<void> _deletePaymentDetails(String ownerId, String documentId) async {
  try {
    // Reference to the paymentdetails collection
    CollectionReference paymentDetailsCollection = FirebaseFirestore.instance
        .collection('organizations')
        .doc(organizationId)
        .collection('paymentdetails');

    // Get all documents from the paymentdetails collection
    QuerySnapshot paymentDetailsSnapshot = await paymentDetailsCollection.get();

    // Iterate through each document
    for (QueryDocumentSnapshot paymentDetailDoc in paymentDetailsSnapshot.docs) {
      // Explicitly cast the data to Map<String, dynamic>
      Map<String, dynamic> paymentDetailsData = paymentDetailDoc.data() as Map<String, dynamic>;

      if (paymentDetailsData.containsKey('newentryid') && paymentDetailsData.containsKey('inchargeid')) {
        String? newEntryId = paymentDetailsData['newentryid'];
        String? inchargeId = paymentDetailsData['inchargeid'];

        // Check if the newentryid matches the documentId and inchargeid matches the ownerId
        if (newEntryId == documentId && inchargeId == ownerId) {
          // Delete the document
          await paymentDetailDoc.reference.delete();
        }
      }
    }

    print('Payment details documents deleted successfully');
  } catch (e) {
    print('Error deleting payment details: $e');
  }
}


Future<void> _updateRemainingAmountShare(String documentId) async {
  try {
    // Fetch the remaining amount from the newentry document
    DocumentSnapshot entrySnapshot = await FirebaseFirestore.instance
        .collection('organizations')
        .doc(organizationId)
        .collection('newentry')
        .doc(documentId)
        .get();

    double remainingAmount = (entrySnapshot['remainingamount'] as double?) ?? 0.0;


    // Fetch owners from ownerdetails
    QuerySnapshot ownersSnapshot = await FirebaseFirestore.instance
        .collection('organizations')
        .doc(organizationId)
        .collection('newentry')
        .doc(documentId)
        .collection('ownershare')
        .get();

    // Update remaining amount share for each owner
    for (var owner in ownersSnapshot.docs) {
      String shareString = owner['share'] as String? ?? '0.0'; // Get share as a string
    double share = double.tryParse(shareString) ?? 0.0; // Parse share to double

    double remainingAmountShare = (share / 100.0) * remainingAmount;
    String remainingAmountShareString = remainingAmountShare.toStringAsFixed(2);

     
      // Update remaining amount share in Firestore
      await FirebaseFirestore.instance
          .collection('organizations')
          .doc(organizationId)
          .collection('newentry')
          .doc(documentId)
          .collection('ownershare')
          .doc(owner.id)
          .update({'remainingamountshare': remainingAmountShareString});
    }

    // Update payment details after updating remaining amount share
    await _updatePaymentDetails(documentId);
  } catch (e) {
    print('Error updating remaining amount share: $e');
  }
}

Future<void> _addOwnerToShare(String documentId) async {
  List<String> selectedOwners = [];
  Map<String, Map<String, dynamic>> ownersDetails = {};

  // Get the current datetime
  DateTime currentDate = DateTime.now();

  try {
    // Fetch owners' details (name, email, phone) from the subcollection
    QuerySnapshot ownersSnapshot = await FirebaseFirestore.instance
        .collection('organizations')
        .doc(organizationId)
        .collection('ownerdetails')
        .get();

    // Fetch the remaining amount from the newentry document
    DocumentSnapshot entrySnapshot = await FirebaseFirestore.instance
        .collection('organizations')
        .doc(organizationId)
        .collection('newentry')
        .doc(documentId)
        .get();

    double remainingAmount = (entrySnapshot['remainingamount'] as double?) ?? 0.0;

    // Show dialog to select owners and enter investments
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Owners to Share'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // List of owners with checkboxes
                  for (var owner in ownersSnapshot.docs) ...[
                    CheckboxListTile(
                      title: Text(owner['name']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Email: ${owner['email']}'),
                          Text('Phone: ${owner['phone']}'),
                          Text('Invest: ${owner['invest']}'),
                          Text('Share: ${owner['share']}'),
                        ],
                      ),
                      value: selectedOwners.contains(owner.id),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value!) {
                            selectedOwners.add(owner.id);
                            ownersDetails[owner.id] = {
                              'name': owner['name'],
                              'email': owner['email'],
                              'phone': owner['phone'],
                              'invest': owner['invest'],
                              'share': owner['share'],
                            };
                          } else {
                            selectedOwners.remove(owner.id);
                            ownersDetails.remove(owner.id);
                          }
                        });
                      },
                    ),
                  ],
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  for (var ownerId in selectedOwners) {
                    // Check if the owner already exists in ownershare
                    QuerySnapshot existingOwnerSnapshot = await FirebaseFirestore.instance
                        .collection('organizations')
                        .doc(organizationId)
                        .collection('newentry')
                        .doc(documentId)
                        .collection('ownershare')
                        .where(FieldPath.documentId, isEqualTo: ownerId)
                        .get();

                    if (existingOwnerSnapshot.docs.isEmpty) {
                      // Generate unique document ID for paymentdetails
                      DocumentReference paymentDocRef = FirebaseFirestore.instance
                          .collection('organizations')
                          .doc(organizationId)
                          .collection('paymentdetails')
                          .doc();

                     double share = double.parse(ownersDetails[ownerId]!['share'] as String);
                        double remainingAmountShareDouble = (share / 100.0) * remainingAmount;
                      String remainingAmountShare = remainingAmountShareDouble.toStringAsFixed(2);


                      // Add to ownershare subcollection
                      await FirebaseFirestore.instance
                          .collection('organizations')
                          .doc(organizationId)
                          .collection('newentry')
                          .doc(documentId)
                          .collection('ownershare')
                          .doc(ownerId)
                          .set({
                        'name': ownersDetails[ownerId]!['name'],
                        'email': ownersDetails[ownerId]!['email'],
                        'phone': ownersDetails[ownerId]!['phone'],
                        'invest': ownersDetails[ownerId]!['invest'],
                        'share': ownersDetails[ownerId]!['share'],
                        'remainingamountshare': remainingAmountShare, // Initialize remainingAmountShare
                      });

                      // Add to paymentdetails subcollection with unique ID
                      await paymentDocRef.set({
                        'name': ownersDetails[ownerId]!['name'],
                        'email': ownersDetails[ownerId]!['email'],
                        'phone': ownersDetails[ownerId]!['phone'],
                        'invest': ownersDetails[ownerId]!['invest'],
                        'share': ownersDetails[ownerId]!['share'],
                        'remainingamountshare': remainingAmountShare, // Initialize remainingAmountShare
                        'user': 'Owner',
                        'payment': 'Not Paid',
                        'paidamount': '0.0',
                        'pendingamount': '0.0',
                        'modeofpayment': 'Cash',
                        'date': Timestamp.fromDate(currentDate),
                        'inchargeid': ownerId, // Set inchargeid as ownerId
                        'newentryid': documentId, // Set newentryid as the documentId
                      });
                    } else {
                      // Show a SnackBar with a message indicating that the owner already exists
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Owner with ID $ownerId already exists in ownershare'),
                        ),
                      );
                    }
                  }

                  Navigator.pop(context);
                  // Recalculate owner share
                  await _updateRemainingAmountShare(documentId);

                  // Update UI
                  if (mounted) {
                    // Check if the widget is still mounted
                    setState(() {});
                  }
                } catch (e) {
                  print('Error adding owners to share: $e');
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  } catch (e) {
    print('Error fetching owner details: $e');
  }
}


Future<void> _deleteOwnerShare(String documentId, String ownerId, String userRole) async {
  if (userRole != 'Headowner') {
    print('You do not have access to delete owner shares.');
    return;
  }

  // Show the confirmation dialog
  bool confirmDelete = await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete this owner share entry?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false); // Return false to indicate cancellation
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true); // Return true to confirm deletion
            },
            child: Text('Delete'),
          ),
        ],
      );
    },
  );

  // Check if the user confirmed the deletion
  if (confirmDelete == true) {
    try {
      // Delete the owner share entry
      await FirebaseFirestore.instance
          .collection('organizations')
          .doc(organizationId)
          .collection('newentry')
          .doc(documentId)
          .collection('ownershare')
          .doc(ownerId)
          .delete();

      await _updateRemainingAmountShare(documentId);
      await _deletePaymentDetails(ownerId, documentId);

      // Refresh the UI
          if (mounted) { // Check if the widget is still mounted
        setState(() {});
      }
    } catch (e) {
      print('Error deleting owner share: $e');
    }
  }
}


Future<QuerySnapshot> _fetchOwnerShareSubcollection(String documentId) async {
  try {
    return await FirebaseFirestore.instance
        .collection('organizations')
        .doc(organizationId)
        .collection('newentry')
        .doc(documentId)
        .collection('ownershare')
        .get();
  } catch (e) {
    print('Error fetching owner share: $e');
    throw e;
  }
}

Future<void> _updatePaymentDetails(String documentId) async {
  try {
    // Fetch owners from ownershare
    QuerySnapshot ownersSnapshot = await FirebaseFirestore.instance
        .collection('organizations')
        .doc(organizationId)
        .collection('newentry')
        .doc(documentId)
        .collection('ownershare')
        .get();

    for (var owner in ownersSnapshot.docs) {
      String ownerId = owner.id;

      // Fetch corresponding paymentdetails document
      QuerySnapshot paymentDetailsSnapshot = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(organizationId)
          .collection('paymentdetails')
          .where('inchargeid', isEqualTo: ownerId) // Assuming ownerId is the inchargeid
          .where('newentryid', isEqualTo: documentId)
          .get();

      if (paymentDetailsSnapshot.docs.isNotEmpty) {
        var paymentDetailDoc = paymentDetailsSnapshot.docs.first;

        String investString = owner['invest'] ?? '0.0'; // Get invest as a string
        double invest = double.tryParse(investString) ?? 0.0; // Parse invest to double

        String shareString = owner['share'] ?? '0.0'; // Get share as a string
        double share = double.tryParse(shareString) ?? 0.0; // Parse share to double

        String remainingAmountShareString = owner['remainingamountshare'] ?? '0.0'; // Get remainingamountshare as a string
        double remainingAmountShare = double.tryParse(remainingAmountShareString) ?? 0.0; // Parse remainingamountshare to double

        // Calculate pending amount
        double paidAmount = double.tryParse(paymentDetailDoc['paidamount'] ?? '0.0') ?? 0.0;
        double pendingAmount = remainingAmountShare - paidAmount;

        // Update the corresponding document in paymentdetails including pending amount
        await paymentDetailDoc.reference.update({
          'share': share.toString(), // Update share as a string
          'remainingamountshare': remainingAmountShareString, // Keep remainingamountshare as a string
          'pendingamount': pendingAmount.toString(), // Update pending amount
        });
      }
    }
  } catch (e) {
    print('Error updating payment details: $e');
  }
}

String _formatDate(dynamic date) {
    if (date == null) return '';

    if (date is Timestamp) {
      var dateTime = date.toDate();
      return '${dateTime.day}-${dateTime.month}-${dateTime.year}';
    } else if (date is String) {
      return date;
    }

    return '';
  }
}
