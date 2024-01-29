// ignore_for_file: unused_local_variable
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

  double _calculateShare(double invest, double totalInvest) {
    if (totalInvest == 0) {
      // To avoid division by zero
      return 0.0;
    }

    return (invest / totalInvest) * 100;
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
      ),
      body: organizationId.isEmpty
          ? Center(child: CircularProgressIndicator())
          : _buildDatabaseScreen(),
    );
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
                    child: ElevatedButton(
                      onPressed: () {
                        _deleteNewEntryDocument(document.id, role);
                      },
                      child: Text('Delete Entry'),
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

void _deleteNewEntryDocument(String documentId, String userRole) async {
  if (userRole != 'Headowner') {
    print('You do not have access to delete the entire entry.');
    return;
  }

  try {
    // Delete the entire newentry document
    await FirebaseFirestore.instance
        .collection('organizations')
        .doc(organizationId)
        .collection('newentry')
        .doc(documentId)
        .delete();

    // Refresh the UI
    setState(() {});

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
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () => _editMonthConsidered(
                    document.id, document['monthconsidered'] as String,role),
              ),
            ],
          ),
          Text('Total Profit: ${document['totalprofit']}'),
        ],
      ),
    );
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
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: editFunction,
            ),
          ],
        ),
      ],
    );
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
            child: DataTable(
              columnSpacing: 16.0, // Adjust the spacing between columns
              columns: [
                DataColumn(label: Text('Revenue Amount')),
                DataColumn(label: Text('Expense Name')),
                DataColumn(label: Text('Expense Amount')),
                DataColumn(label: Text('Actions')),
              ],
              rows: _buildRevenueExpenseRows(
                documentId, revenueSnapshot, expenseSnapshot),
            ),
          );
        },
      ),
      SizedBox(height: 10),
      Padding(
        padding: const EdgeInsets.only(left: 16.0),
        child: ElevatedButton(
          onPressed: () => _addRevenueExpense(documentId),
          child: Text('Add Revenue/Expense'),
        ),
      ),
    ],
  );
}


  List<DataRow> _buildRevenueExpenseRows(String documentId,
      QuerySnapshot revenue, QuerySnapshot expense) {
    List<DataRow> rows = [];

    if (revenue.docs.isNotEmpty && expense.docs.isNotEmpty) {
      for (int i = 0; i < revenue.docs.length; i++) {
        var revenueDoc = revenue.docs[i];
        var expenseDoc = expense.docs[i];

        String revenueAmount =
            revenueDoc['amount']?.toString() ?? '';
        String expenseName =
            expenseDoc['expensename']?.toString() ?? '';
        String expenseAmount =
            expenseDoc['expenseamount']?.toString() ?? '';

        rows.add(DataRow(cells: [
          DataCell(Text(revenueAmount)),
          DataCell(Text(expenseName)),
          DataCell(Text(expenseAmount)),
          DataCell(
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    _editRevenueExpense(
                        documentId, revenueDoc, expenseDoc,role);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    _deleteRevenueExpense(
                        documentId,
                        revenueDoc,
                        expenseDoc,
                        role,
                    );
                  },
                ),
              ],
            ),
          ),
        ]));
      }
    } else {
      rows.add(DataRow(cells: [
        DataCell(Text('N/A')),
        DataCell(Text('N/A')),
        DataCell(Text('N/A')),
        DataCell(Text('N/A')),
      ]));
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
                                setState(() {});

                // Update totalprofit after adding
                await _updateTotalProfit(documentId);
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

void _editRevenueExpense(String documentId, DocumentSnapshot revenue,
    DocumentSnapshot expense, String userRole) async {
  if (userRole != 'Headowner') {
    print('You do not have access to edit revenue and expense.');
    return;
  }

  TextEditingController revenueController =
      TextEditingController(text: revenue['amount']?.toString() ?? '');
  TextEditingController expenseNameController =
      TextEditingController(text: expense['expensename']?.toString() ?? '');
  TextEditingController expenseAmountController = TextEditingController(
      text: expense['expenseamount']?.toString() ?? '');

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
                // Update Firestore with edited data
                await FirebaseFirestore.instance
                    .collection('organizations')
                    .doc(organizationId)
                    .collection('newentry')
                    .doc(documentId)
                    .collection('revenue')
                    .doc(revenue.id)
                    .update({
                  'amount': double.parse(revenueController.text),
                });

                await FirebaseFirestore.instance
                    .collection('organizations')
                    .doc(organizationId)
                    .collection('newentry')
                    .doc(documentId)
                    .collection('expense')
                    .doc(expense.id)
                    .update({
                  'expensename': expenseNameController.text,
                  'expenseamount': double.parse(expenseAmountController.text),
                });

                Navigator.pop(context);

                // Reload the data after editing
                setState(() {});

                // Update totalprofit after editing
                await _updateTotalProfit(documentId);
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

 void _deleteRevenueExpense(String documentId, DocumentSnapshot revenue,
    DocumentSnapshot expense, String userRole) async {
  if (userRole != 'Headowner') {
    print('You do not have access to delete revenue and expense.');
    return;
  }

  try {
    // Delete the revenue document
    await FirebaseFirestore.instance
        .collection('organizations')
        .doc(organizationId)
        .collection('newentry')
        .doc(documentId)
        .collection('revenue')
        .doc(revenue.id)
        .delete();

    // Delete the expense document
    await FirebaseFirestore.instance
        .collection('organizations')
        .doc(organizationId)
        .collection('newentry')
        .doc(documentId)
        .collection('expense')
        .doc(expense.id)
        .delete();

    // Reload the data after deleting
    setState(() {});

    // Update totalprofit after deleting
    await _updateTotalProfit(documentId);
  } catch (e) {
    print('Error deleting revenue and expense: $e');
    // Handle error, show a snackbar, or any other appropriate action
  }
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
            child: DataTable(
              columnSpacing: 16.0, // Adjust the spacing between columns
              columns: [
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('Phone')),
                DataColumn(label: Text('Amount')),
                DataColumn(label: Text('Actions')),
              ],
              rows: _buildCrewMembersRows(documents),
            ),
          );
        },
      ),
      SizedBox(height: 20), // Add spacing between DataTable and button
      Padding(
        padding: const EdgeInsets.only(left: 16.0),
        child: ElevatedButton(
          onPressed: () => _addCrewMemberToSalary(documentId),
          child: Text('Add Crew Member'),
        ),
      ),
    ],
  );
}


List<DataRow> _buildCrewMembersRows(List<DocumentSnapshot> documents) {
  List<DataRow> rows = [];

  documents.forEach((doc) {
    String name = doc['name'];
    String email = doc['email'];
    String phone = doc['phone'];
    double amount = (doc['amount'] as num).toDouble(); // Parse as double

    // Add a DataRow for each crew member
    DataRow row = DataRow(cells: [
      DataCell(Text(name)),
      DataCell(Text(email)),
      DataCell(Text(phone)),
      DataCell(Text(amount.toString())),
      DataCell(Row(
        // Create a row for action buttons
        children: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              // Implement edit functionality
              _editCrewMemberSalary(doc.reference, role); // Pass the document ID for editing
            },
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              // Implement delete functionality
              _deleteCrewMemberSalary(doc.reference, role); // Pass the document ID for deletion
            },
          ),
        ],
      )),
    ]);

    rows.add(row);
  });

  return rows;
}

void _editCrewMemberSalary(DocumentReference documentReference, String userRole) {
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
                double newAmount = double.parse(amountController.text);

                // Update the amount field in Firestore
                await documentReference.update({'amount': newAmount});

                // Show a success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Crew member salary updated successfully'),
                  ),
                );

                // Refresh the UI
                setState(() {});

                Navigator.pop(context); // Close the dialog
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


void _deleteCrewMemberSalary(DocumentReference documentReference, String userRole) {
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
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                // Delete the document from Firestore
                await documentReference.delete();

                // Show a success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Crew member salary entry deleted successfully'),
                  ),
                );

                // Refresh the UI
                setState(() {});

                Navigator.pop(context); // Close the dialog
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

Widget _buildOwnersShareTable(String documentId) {
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder(
              future: _fetchOwnerShareSubcollection(documentId),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }

                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                var documents = snapshot.data!.docs;

                return DataTable(
                  columnSpacing: 16.0,
                  columns: [
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Phone')),
                    DataColumn(label: Text('Invest')),
                    DataColumn(label: Text('Share')),
                    DataColumn(label: Text('Actions')), // New column for actions
                  ],
                  rows: _buildOwnersShareRows(documents, documentId),
                );
              },
            ),
            SizedBox(height: 20), // Add spacing between DataTable and button
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16.0), // Adjust the left padding as needed
          child: ElevatedButton(
            onPressed: () => _addOwnerToShare(documentId),
            child: Text('Add Owner'),
          ),
        ),
      ],
    ),
  );
}

List<DataRow> _buildOwnersShareRows(List<QueryDocumentSnapshot> documents, String documentId) {
  List<DataRow> rows = [];

  for (var document in documents) {
    String ownerId = document.id;
    String name = document['name'] ?? '';
    String email = document['email'] ?? '';
    String phone = document['phone'] ?? '';
    double invest = (document['invest'] ?? 0).toDouble(); // Parse as double
    double share = (document['share'] ?? 0).toDouble(); // Parse as double

    rows.add(DataRow(cells: [
      DataCell(Text(name)),
      DataCell(Text(email)),
      DataCell(Text(phone)),
      DataCell(Text(invest.toString())),
      DataCell(Text(share.toString())),
      DataCell(Row(
        children: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () => _editOwnerShare(documentId, ownerId, invest, role),
          ),
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

Future<void> _editOwnerShare(String documentId, String ownerId, double currentInvest, String userRole) async {
  if (userRole != 'Headowner') {
    print('You do not have access to edit owner shares.');
    return;
  }

  TextEditingController investController = TextEditingController(text: currentInvest.toString());

  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Edit Investment'),
        content: TextField(
          controller: investController,
          decoration: InputDecoration(labelText: 'Investment'),
          keyboardType: TextInputType.number,
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
              double newInvest = double.parse(investController.text);

              try {
                await FirebaseFirestore.instance
                    .collection('organizations')
                    .doc(organizationId)
                    .collection('newentry')
                    .doc(documentId)
                    .collection('ownershare')
                    .doc(ownerId)
                    .update({'invest': newInvest});

                // Recalculate share
                await _recalculateOwnerShare(documentId);

                // Refresh the UI
                setState(() {});

                Navigator.pop(context);
              } catch (e) {
                print('Error editing owner share: $e');
              }
            },
            child: Text('Save'),
          ),
        ],
      );
    },
  );
}

Future<void> _deleteOwnerShare(String documentId, String ownerId, String userRole) async {
  if (userRole != 'Headowner') {
    print('You do not have access to delete owner shares.');
    return;
  }

  try {
    await FirebaseFirestore.instance
        .collection('organizations')
        .doc(organizationId)
        .collection('newentry')
        .doc(documentId)
        .collection('ownershare')
        .doc(ownerId)
        .delete();

    // Recalculate share
    await _recalculateOwnerShare(documentId);

    // Refresh the UI
    setState(() {});

  } catch (e) {
    print('Error deleting owner share: $e');
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
// Function to add crew member to salarytocrewmembers subcollection
Future<void> _addCrewMemberToSalary(String documentId) async {
  List<String> selectedCrewMembers = [];
  Map<String, double> crewMembersAmount = {};
  Map<String, Map<String, dynamic>> crewMembersDetails = {};

  try {
    // Fetch crew members' details (name, email, phone) from the subcollection
    QuerySnapshot crewMembersSnapshot = await FirebaseFirestore.instance
        .collection('organizations')
        .doc(organizationId)
        .collection('crewmemberdetails')
        .get();

    // Show dialog to select crew members and enter amounts
    // ignore: use_build_context_synchronously
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
                        crewMembersAmount[crewMemberId] = double.parse(value);
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
                // Check if crew member already exists in salarytocrewmembers
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

                // Add selected crew members to salarytocrewmembers
                for (var crewMemberId in selectedCrewMembers) {
                  if (!existingMembersIds.contains(crewMemberId)) {
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
                    
                  }else {
    // Show a SnackBar with a message indicating that the crew member already exists
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Crew member with ID $crewMemberId already exists in salarytocrewmembers'),
      ),
    );
  }
                }

                // Update UI
                setState(() {});

                Navigator.pop(context);
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


// Function to add owner to ownershare subcollection
Future<void> _addOwnerToShare(String documentId) async {
  List<String> selectedOwners = [];
  Map<String, double> ownersInvestments = {};
  Map<String, Map<String, dynamic>> ownersDetails = {};

  try {
    // Fetch owners' details (name, email, phone) from the subcollection
    QuerySnapshot ownersSnapshot = await FirebaseFirestore.instance
        .collection('organizations')
        .doc(organizationId)
        .collection('ownerdetails')
        .get();

    // Show dialog to select owners and enter investments
    // ignore: use_build_context_synchronously
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
                            };
                          } else {
                            selectedOwners.remove(owner.id);
                            ownersDetails.remove(owner.id);
                          }
                        });
                      },
                    ),
                  ],
                  // Input field for investment
                  TextField(
                    decoration: InputDecoration(labelText: 'Investment'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      // Update investments for selected owners
                      for (var ownerId in selectedOwners) {
                        ownersInvestments[ownerId] = double.parse(value);
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
                  // Check if owner already exists in ownershare
                  QuerySnapshot existingOwnersSnapshot = await FirebaseFirestore.instance
                      .collection('organizations')
                      .doc(organizationId)
                      .collection('newentry')
                      .doc(documentId)
                      .collection('ownershare')
                      .where(FieldPath.documentId, whereIn: selectedOwners)
                      .get();

                  List<String> existingOwnersIds =
                      existingOwnersSnapshot.docs.map((e) => e.id).toList();

                  // Add selected owners to ownershare
                  for (var ownerId in selectedOwners) {
                    if (!existingOwnersIds.contains(ownerId)) {
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
                        'invest': ownersInvestments[ownerId],
                        'share': 0.0, // Initialize share to 0
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

                  // Recalculate owner share
                  await _recalculateOwnerShare(documentId);

                  // Update UI
                  setState(() {});

                  Navigator.pop(context);
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
Future<void> _recalculateOwnerShare(String documentId) async {
  try {
    // Fetch owners from ownershare
    QuerySnapshot ownersSnapshot = await FirebaseFirestore.instance
        .collection('organizations')
        .doc(organizationId)
        .collection('newentry')
        .doc(documentId)
        .collection('ownershare')
        .get();

    // Calculate total investment
    double totalInvestment = ownersSnapshot.docs
        .map((owner) => (owner['invest'] as double) ?? 0.0)
        .fold(0.0, (sum, invest) => sum + invest);

    // Update share for each owner based on total investment
    for (var owner in ownersSnapshot.docs) {
      double invest = (owner['invest'] as double?) ?? 0.0;
      double share = (invest / totalInvestment) * 100.0;

      // Update share in Firestore
      await FirebaseFirestore.instance
          .collection('organizations')
          .doc(organizationId)
          .collection('newentry')
          .doc(documentId)
          .collection('ownershare')
          .doc(owner.id)
          .update({'share': share});
    }
  } catch (e) {
    print('Error recalculating owner share: $e');
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
