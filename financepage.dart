// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseScreen extends StatefulWidget {
  @override
  _DatabaseScreenState createState() => _DatabaseScreenState();
}

class _DatabaseScreenState extends State<DatabaseScreen> {
  CollectionReference newEntryCollection =
      FirebaseFirestore.instance.collection('newentry');


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
          .collection('newentry')
          .doc(documentId)
          .collection('revenue')
          .get();

      var expenseSnapshot = await FirebaseFirestore.instance
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
      body: FutureBuilder(
        future: newEntryCollection.get(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
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
                  _buildHorizontalScrollableTable(
                    'Revenue&Expense',
                    document.id,
                    _buildRevenueExpenseTable(document.id),
                  ),
                  SizedBox(height: 20),
                  _buildHorizontalScrollableTable(
                    'Crew Members Salary',
                    document.id,
                    _buildCrewMembersTable(document.id),
                  ),
                 
                  SizedBox(height: 20),
                  _buildHorizontalScrollableTable(
                    'Owners Share',
                    document.id,
                    _buildOwnersShareTable(document.id),
                  ),
                  SizedBox(height: 40),
                ],
              ],
            ),
          );
        },
      ),
    );
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
                onPressed: () =>
                    _editSailingDate(document.id, document['sailingdate'] as Timestamp),
              ),
            ],
          ),
          Row(
            children: [
              Text('Return Date: ${_formatDate(document['returndate'])}'),
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () =>
                    _editReturnDate(document.id, document['returndate'] as Timestamp),
              ),
            ],
          ),
          Row(
            children: [
              Text('Month Considered: ${document['monthconsidered']}'),
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () =>
                    _editMonthConsidered(document.id, document['monthconsidered'] as String),
              ),
            ],
          ),
          Text('Total Profit: ${document['totalprofit']}'),
        ],
      ),
    );
  }

  Widget _buildHorizontalScrollableTable(
      String tableName, String documentId, Widget tableWidget) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$tableName Table',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Container(
            width: MediaQuery.of(context).size.width,
            child: tableWidget,
          ),
        ],
      ),
    );
  }

  
  Widget _buildDateField(String label, Timestamp date, VoidCallback editFunction) {
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

  Widget _buildMonthConsideredField(String label, String monthConsidered, VoidCallback editFunction) {
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

  void _editSailingDate(String documentId, Timestamp sailingDate) async {
    DateTime currentDate = sailingDate.toDate();
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null && pickedDate != currentDate) {
      // Update Firestore with edited sailing date
      await FirebaseFirestore.instance
          .collection('newentry')
          .doc(documentId)
          .update({'sailingdate': pickedDate});
      
      // Reload the data after editing
      setState(() {});
    }
  }

  void _editReturnDate(String documentId, Timestamp returnDate) async {
    DateTime currentDate = returnDate.toDate();
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null && pickedDate != currentDate) {
      // Update Firestore with edited return date
      await FirebaseFirestore.instance
          .collection('newentry')
          .doc(documentId)
          .update({'returndate': pickedDate});

      // Reload the data after editing
      setState(() {});
    }
  }

  void _editMonthConsidered(String documentId, String monthConsidered) async {
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
                // Update Firestore with edited month considered
                await FirebaseFirestore.instance
                    .collection('newentry')
                    .doc(documentId)
                    .update({'monthconsidered': selectedMonth});

                // Reload the data after editing
                setState(() {});
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
    children: [
      FutureBuilder(
        future: _fetchRevenueExpenseSubcollections(documentId),
        builder: (context, AsyncSnapshot<List<QuerySnapshot>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }

          var revenueSnapshot = snapshot.data![0];
          var expenseSnapshot = snapshot.data![1];

          return DataTable(
            columns: [
              DataColumn(label: Text('Revenue Amount')),
              DataColumn(label: Text('Expense Name')),
              DataColumn(label: Text('Expense Amount')),
              DataColumn(label: Text('Actions')),
            ],
            rows: _buildRevenueExpenseRows(documentId, revenueSnapshot, expenseSnapshot),
          );
        },
      ),
      SizedBox(height: 10),
      ElevatedButton(
        onPressed: () => _addRevenueExpense(documentId),
        child: Text('Add Revenue/Expense'),
      ),
    ],
  );
}

List<DataRow> _buildRevenueExpenseRows(
  String documentId, QuerySnapshot revenue, QuerySnapshot expense) {
  List<DataRow> rows = [];

  if (revenue.docs.isNotEmpty && expense.docs.isNotEmpty) {
    for (int i = 0; i < revenue.docs.length; i++) {
      var revenueDoc = revenue.docs[i];
      var expenseDoc = expense.docs[i];

      String revenueAmount = revenueDoc['amount']?.toString() ?? '';
      String expenseName = expenseDoc['expensename']?.toString() ?? '';
      String expenseAmount = expenseDoc['expenseamount']?.toString() ?? '';

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
                  _editRevenueExpense(documentId, revenueDoc, expenseDoc);
                },
              ),
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  _deleteRevenueExpense(
                    documentId,
                    revenueDoc,
                    expenseDoc,
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
  TextEditingController revenueController = TextEditingController();
  TextEditingController expenseNameController = TextEditingController();
  TextEditingController expenseAmountController = TextEditingController();

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
              double revenueAmount = double.tryParse(revenueController.text) ?? 0.0;
              String expenseName = expenseNameController.text.isNotEmpty ? expenseNameController.text : 'N/A';
              double expenseAmount = double.tryParse(expenseAmountController.text) ?? 0.0;

              // Add data to Firestore
              await FirebaseFirestore.instance
                  .collection('newentry')
                  .doc(documentId)
                  .collection('revenue')
                  .add({
                'amount': revenueAmount,
              });

              await FirebaseFirestore.instance
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

void _editRevenueExpense(
    String documentId, DocumentSnapshot revenue, DocumentSnapshot expense) async {
  TextEditingController revenueController =
      TextEditingController(text: revenue['amount']?.toString() ?? '');
  TextEditingController expenseNameController =
      TextEditingController(text: expense['expensename']?.toString() ?? '');
  TextEditingController expenseAmountController =
      TextEditingController(text: expense['expenseamount']?.toString() ?? '');

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
              // Update Firestore with edited data
              await FirebaseFirestore.instance
                  .collection('newentry')
                  .doc(documentId)
                  .collection('revenue')
                  .doc(revenue.id)
                  .update({
                'amount': double.parse(revenueController.text),
              });

              await FirebaseFirestore.instance
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
            },
            child: Text('Update'),
          ),
        ],
      );
    },
  );
}

void _deleteRevenueExpense(
    String documentId, DocumentSnapshot revenue, DocumentSnapshot expense) async {
  try {
    // Delete the revenue document
    await FirebaseFirestore.instance
        .collection('newentry')
        .doc(documentId)
        .collection('revenue')
        .doc(revenue.id)
        .delete();

    // Delete the expense document
    await FirebaseFirestore.instance
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
          .collection('newentry')
          .doc(documentId)
          .collection('revenue')
          .get();

      var expense = await FirebaseFirestore.instance
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
  return FutureBuilder(
    future: _fetchCrewMembersSubcollection(documentId),
    builder: (context, AsyncSnapshot<QuerySnapshot?> snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return CircularProgressIndicator();
      }

      var crewMembersSnapshot = snapshot.data;

      return Column(
        children: [
          DataTable(
            columns: [
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Phone')),
              DataColumn(label: Text('Email')),
              DataColumn(label: Text('Amount')),
              DataColumn(label: Text('Actions')),
            ],
            rows: _buildCrewMembersRows(documentId, crewMembersSnapshot),
          ),
          
           ElevatedButton(
            onPressed: () {
              _addCrewMember(documentId);
            },
            child: Text('Add Crew Member'),
          ),
        ],
      );
    },
  );
}

List<DataRow> _buildCrewMembersRows(
    String documentId, QuerySnapshot? crewMembersSnapshot) {
  List<DataRow> rows = [];

  if (crewMembersSnapshot?.docs.isNotEmpty == true) {
    for (var crewMemberDoc in crewMembersSnapshot!.docs) {
      String name = crewMemberDoc['name']?.toString() ?? 'N/A';
      String phone = crewMemberDoc['phone']?.toString() ?? 'N/A';
      String email = crewMemberDoc['email']?.toString() ?? 'N/A';
      double amount = crewMemberDoc['amount']?.toDouble() ?? 0;

      rows.add(DataRow(cells: [
        DataCell(Text(name)),
        DataCell(Text(phone)),
        DataCell(Text(email)),
        DataCell(Text(amount.toString())),
        DataCell(
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  _editCrewMember(documentId, crewMemberDoc);
                },
              ),
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  _deleteCrewMember(documentId, crewMemberDoc);
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
      DataCell(Text('N/A')),
    ]));
  }

  return rows;
}

Future<bool> _isCrewMemberAlreadyAdded(String documentId, String crewMemberName, String crewMemberPhone, String crewMemberEmail) async {
  try {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('newentry')
        .doc(documentId)
        .collection('salarytocrewmembers')
        .where('name', isEqualTo: crewMemberName)
        .where('phone', isEqualTo: crewMemberPhone)
        .where('email', isEqualTo: crewMemberEmail)
        .get();

    return querySnapshot.docs.isNotEmpty;
  } catch (e) {
    print('Error checking if crew member already added: $e');
    return false;
  }
}

Future<bool> _isCrewMemberInSalaryToCrewMembers(String documentId, String crewMemberId) async {
  try {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('newentry')
        .doc(documentId)
        .collection('salarytocrewmembers')
        .where('crewMemberId', isEqualTo: crewMemberId)
        .get();

    return querySnapshot.docs.isNotEmpty;
  } catch (e) {
    print('Error checking if crew member is in salarytocrewmembers: $e');
    return false;
  }
}

void _addCrewMember(String documentId) {
  TextEditingController amountController = TextEditingController();
  DocumentSnapshot? selectedCrewMember;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return FutureBuilder(
        future: FirebaseFirestore.instance.collection('crewmembers').get(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }

          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          List<DocumentSnapshot> crewMembers = snapshot.data?.docs ?? [];

          return AlertDialog(
            title: Text('Add Crew Member'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<DocumentSnapshot>(
                  hint: Text('Select Crew Member'),
                  value: selectedCrewMember,
                  items: crewMembers.map((crewMember) {
                    return DropdownMenuItem<DocumentSnapshot>(
                      value: crewMember,
                      child: Text(crewMember['name']?.toString() ?? ''),
                    );
                  }).toList(),
                  onChanged: (DocumentSnapshot? crewMember) {
                    setState(() {
                      selectedCrewMember = crewMember;
                    });
                  },
                ),
                TextField(
                  controller: amountController,
                  decoration: InputDecoration(labelText: 'Amount'),
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
                  if (selectedCrewMember != null) {
                    double amount = double.tryParse(amountController.text) ?? 0.0;

                    bool isCrewMemberAlreadyAdded = await _isCrewMemberAlreadyAdded(
                      documentId,
                      selectedCrewMember!['name']?.toString() ?? '',
                      selectedCrewMember!['phone']?.toString() ?? '',
                      selectedCrewMember!['email']?.toString() ?? '',
                    );

                    if (isCrewMemberAlreadyAdded) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Crew member is already added to salarytocrewmembers.'),
                        ),
                      );
                    } else {
                      // Check if the crew member is already in the salarytocrewmembers
                      bool isInSalaryToCrewMembers = await _isCrewMemberInSalaryToCrewMembers(
                        documentId,
                        selectedCrewMember!.id,
                      );

                      if (isInSalaryToCrewMembers) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Crew member is already in salarytocrewmembers.'),
                          ),
                        );
                      } else {
                        DocumentReference crewMemberDocRef = await FirebaseFirestore.instance
                            .collection('newentry')
                            .doc(documentId)
                            .collection('salarytocrewmembers')
                            .add({
                          'name': selectedCrewMember!['name']?.toString() ?? 'N/A',
                          'phone': selectedCrewMember!['phone']?.toString() ?? 'N/A',
                          'email': selectedCrewMember!['email']?.toString() ?? 'N/A',
                          'amount': amount,
                          'crewMemberId': selectedCrewMember!.id,
                        });

                        Navigator.pop(context);
                        setState(() {});
                      }
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Please select a crew member.'),
                      ),
                    );
                  }
                },
                child: Text('Add'),
              ),
            ],
          );
        },
      );
    },
  );
}


void _editCrewMember(String documentId, DocumentSnapshot crewMemberDoc) {
  TextEditingController nameController =
      TextEditingController(text: crewMemberDoc['name']?.toString() ?? '');
  TextEditingController phoneController =
      TextEditingController(text: crewMemberDoc['phone']?.toString() ?? '');
  TextEditingController emailController =
      TextEditingController(text: crewMemberDoc['email']?.toString() ?? '');
  TextEditingController amountController = TextEditingController(
      text: crewMemberDoc['amount']?.toStringAsFixed(2) ?? '');

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Edit Crew Member'),
        content: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(labelText: 'Phone'),
            ),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: amountController,
              decoration: InputDecoration(labelText: 'Amount'),
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
              // Update Firestore with edited data
              await FirebaseFirestore.instance
                  .collection('newentry')
                  .doc(documentId)
                  .collection('salarytocrewmembers')
                  .doc(crewMemberDoc.id)
                  .update({
                'name': nameController.text,
                'phone': phoneController.text,
                'email': emailController.text,
                'amount': double.parse(amountController.text),
              });

              Navigator.pop(context);

              // Reload the data after editing
              setState(() {});
            },
            child: Text('Update'),
          ),
        ],
      );
    },
  );
}


void _deleteCrewMember(String documentId, DocumentSnapshot crewMemberDoc) async {
  try {
    // Delete the crew member document
    await FirebaseFirestore.instance
        .collection('newentry')
        .doc(documentId)
        .collection('salarytocrewmembers')
        .doc(crewMemberDoc.id)
        .delete();

    // Reload the data after deleting
    setState(() {});
  } catch (e) {
    print('Error deleting crew member: $e');
    // Handle error, show a snackbar, or any other appropriate action
  }
}

Future<QuerySnapshot?> _fetchCrewMembersSubcollection(String documentId) async {
  try {
    var crewMembers = await FirebaseFirestore.instance
        .collection('newentry')
        .doc(documentId)
        .collection('salarytocrewmembers')
        .get();

    return crewMembers;
  } catch (e) {
    print('Error fetching crewMembers subcollection: $e');
    return null; // Return null in case of an error
  }
}

 
 Widget _buildOwnersShareTable(String documentId) {
  return FutureBuilder(
    future: _fetchOwnersShareSubcollection(documentId),
    builder: (context, AsyncSnapshot<QuerySnapshot?> snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return CircularProgressIndicator();
      }

      var ownerShareSnapshot = snapshot.data;

      return Column(
        children: [
          DataTable(
            columns: [
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Phone')),
              DataColumn(label: Text('Email')),
              DataColumn(label: Text('Invest')),
              DataColumn(label: Text('Share')),
              DataColumn(label: Text('Actions')),
            ],
            rows: _buildOwnersShareRows(documentId, ownerShareSnapshot),
          ),
          ElevatedButton(
            onPressed: () {
              _addOwnerShare(documentId);
            },
            child: Text('Add Owner'),
          ),
        ],
      );
    },
  );
}

void _addOwnerShare(String documentId) {
  TextEditingController investController = TextEditingController();
  DocumentSnapshot? selectedOwner;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return FutureBuilder(
        future: FirebaseFirestore.instance.collection('owners').get(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }

          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          List<DocumentSnapshot> owners = snapshot.data?.docs ?? [];

          return AlertDialog(
            title: Text('Add Owner'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<DocumentSnapshot>(
                  hint: Text('Select Owner'),
                  value: selectedOwner,
                  items: owners.map((owner) {
                    return DropdownMenuItem<DocumentSnapshot>(
                      value: owner,
                      child: Text(owner['name']?.toString() ?? ''),
                    );
                  }).toList(),
                  onChanged: (DocumentSnapshot? owner) {
                    setState(() {
                      selectedOwner = owner;
                    });
                  },
                ),
                TextField(
                  controller: investController,
                  decoration: InputDecoration(labelText: 'Invest'),
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
                  if (selectedOwner != null) {
                    double invest = double.tryParse(investController.text) ?? 0.0;

                    bool isOwnerAlreadyAdded = await _isOwnerAlreadyAdded(documentId, selectedOwner!.id);

                    if (isOwnerAlreadyAdded) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Owner is already added to ownershare.'),
                        ),
                      );
                    } else {
                      bool isOwnerInOwnerShare = await _isOwnerInOwnerShare(
                        selectedOwner!['name']?.toString() ?? '',
                        selectedOwner!['phone']?.toString() ?? '',
                        selectedOwner!['email']?.toString() ?? '',
                        documentId,
                      );

                      if (isOwnerInOwnerShare) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Owner is already added to ownershare.'),
                          ),
                        );
                      } else {
                        DocumentReference newOwnerDocRef = await FirebaseFirestore.instance
                            .collection('newentry')
                            .doc(documentId)
                            .collection('ownershare')
                            .add({
                          'ownerId': selectedOwner!.id,
                          'name': selectedOwner!['name']?.toString() ?? 'N/A',
                          'phone': selectedOwner!['phone']?.toString() ?? 'N/A',
                          'email': selectedOwner!['email']?.toString() ?? 'N/A',
                          'invest': invest,
                        });

                        await _updateOwnerShare(newOwnerDocRef.id, invest, documentId);

                        Navigator.pop(context);
                        setState(() {});
                      }
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Please select an owner.'),
                      ),
                    );
                  }
                },
                child: Text('Add'),
              ),
            ],
          );
        },
      );
    },
  );
}

  Future<bool> _isOwnerAlreadyAdded(String documentId, String ownerId) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('newentry')
          .doc(documentId)
          .collection('ownershare')
          .where('ownerId', isEqualTo: ownerId)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking if owner already added: $e');
      return false;
    }
  }

  Future<bool> _isOwnerInOwnerShare(String name, String phone, String email, String documentId) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('newentry')
          .doc(documentId)
          .collection('ownershare')
          .where('name', isEqualTo: name)
          .where('phone', isEqualTo: phone)
          .where('email', isEqualTo: email)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking if owner is in ownershare: $e');
      return false;
    }
  }


List<DataRow> _buildOwnersShareRows(
    String documentId, QuerySnapshot? ownerShareSnapshot) {
  List<DataRow> rows = [];

  if (ownerShareSnapshot?.docs.isNotEmpty == true) {
    for (var ownerShareDoc in ownerShareSnapshot!.docs) {
      String name = ownerShareDoc['name']?.toString() ?? 'N/A';
      String phone = ownerShareDoc['phone']?.toString() ?? 'N/A';
      String email = ownerShareDoc['email']?.toString() ?? 'N/A';
      double invest = ownerShareDoc['invest']?.toDouble() ?? 0;
      double share = ownerShareDoc['share']?.toDouble() ?? 0;

      rows.add(DataRow(cells: [
        DataCell(Text(name)),
        DataCell(Text(phone)),
        DataCell(Text(email)),
        DataCell(Text(invest.toString())),
        DataCell(Text(share.toString())),
        DataCell(
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  _editOwnerShare(documentId, ownerShareDoc);
                },
              ),
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  _deleteOwnerShare(documentId, ownerShareDoc);
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
      DataCell(Text('N/A')),
      DataCell(Text('N/A')),
    ]));
  }

  return rows;
}



Future<void> _updateOwnerShare(String ownerId, double newInvest, String documentId) async {
  try {
    // Fetch existing total invest and calculate new total invest
    var ownersShare = await FirebaseFirestore.instance
        .collection('newentry')
        .doc(documentId)
        .collection('ownershare')
        .get();

    double totalInvest = 0.0;
    ownersShare.docs.forEach((ownerDoc) {
      totalInvest += ownerDoc['invest']?.toDouble() ?? 0.0;
    });

    // Update share for each owner
    ownersShare.docs.forEach((ownerDoc) async {
      double invest = ownerDoc['invest']?.toDouble() ?? 0.0;
      double share = _calculateShare(invest, totalInvest);

      await FirebaseFirestore.instance
          .collection('newentry')
          .doc(documentId)
          .collection('ownershare')
          .doc(ownerDoc.id)
          .update({'share': share});
    });

    // Update share for the newly added owner
    double newTotalInvest = totalInvest + newInvest;

    ownersShare.docs.forEach((ownerDoc) async {
      double invest = ownerDoc['invest']?.toDouble() ?? 0.0;
      double share = _calculateShare(invest, newTotalInvest);

      await FirebaseFirestore.instance
          .collection('newentry')
          .doc(documentId)
          .collection('ownershare')
          .doc(ownerDoc.id)
          .update({'share': share});
    });

    double newShare = _calculateShare(newInvest, newTotalInvest);
    await FirebaseFirestore.instance
        .collection('newentry')
        .doc(documentId)
        .collection('ownershare')
        .doc(ownerId)
        .update({'invest': newInvest, 'share': newShare});
  } catch (e) {
    print('Error updating owner share: $e');
    // Handle error, show a snackbar, or any other appropriate action
  }
}

void _editOwnerShare(String documentId, DocumentSnapshot ownerShareDoc) {
  TextEditingController nameController =
      TextEditingController(text: ownerShareDoc['name']?.toString() ?? '');
  TextEditingController phoneController =
      TextEditingController(text: ownerShareDoc['phone']?.toString() ?? '');
  TextEditingController emailController =
      TextEditingController(text: ownerShareDoc['email']?.toString() ?? '');
  TextEditingController investController = TextEditingController(
      text: ownerShareDoc['invest']?.toStringAsFixed(2) ?? '');

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Edit Owner Share'),
        content: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(labelText: 'Phone'),
            ),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: investController,
              decoration: InputDecoration(labelText: 'Invest'),
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
              // Update Firestore with edited data
              await FirebaseFirestore.instance
                  .collection('newentry')
                  .doc(documentId)
                  .collection('ownershare')
                  .doc(ownerShareDoc.id)
                  .update({
                'name': nameController.text,
                'phone': phoneController.text,
                'email': emailController.text,
                'invest': double.parse(investController.text),
              });

              Navigator.pop(context);

              // Recalculate shares for all owner documents
              await _recalculateShares(documentId);

              // Reload the data after editing
              setState(() {});
            },
            child: Text('Update'),
          ),
        ],
      );
    },
  );
}

Future<void> _recalculateShares(String documentId) async {
  try {
    // Fetch existing total invest and calculate new total invest
    var ownersShare = await FirebaseFirestore.instance
        .collection('newentry')
        .doc(documentId)
        .collection('ownershare')
        .get();

    double totalInvest = 0.0;
    ownersShare.docs.forEach((ownerDoc) {
      totalInvest += ownerDoc['invest']?.toDouble() ?? 0.0;
    });

    // Update share for each owner
    ownersShare.docs.forEach((ownerDoc) async {
      double invest = ownerDoc['invest']?.toDouble() ?? 0.0;
      double share = _calculateShare(invest, totalInvest);

      await FirebaseFirestore.instance
          .collection('newentry')
          .doc(documentId)
          .collection('ownershare')
          .doc(ownerDoc.id)
          .update({'share': share});
    });
  } catch (e) {
    print('Error updating owner shares: $e');
    // Handle error, show a snackbar, or any other appropriate action
  }
}



void _deleteOwnerShare(String documentId, DocumentSnapshot ownerShareDoc) async {
  try {
    // Delete the owner share document
    await FirebaseFirestore.instance
        .collection('newentry')
        .doc(documentId)
        .collection('ownershare')
        .doc(ownerShareDoc.id)
        .delete();


  // Recalculate shares after deleting
    await _recalculateShares(documentId);

    // Reload the data after deleting
    setState(() {});
  } catch (e) {
    print('Error deleting owner share: $e');
    // Handle error, show a snackbar, or any other appropriate action
  }
}


  Future<QuerySnapshot?> _fetchOwnersShareSubcollection(String documentId) async {
    try {
      var ownerShare = await FirebaseFirestore.instance
          .collection('newentry')
          .doc(documentId)
          .collection('ownershare')
          .get();

      return ownerShare;
    } catch (e) {
      print('Error fetching ownerShare subcollection: $e');
      return null; // Return null in case of an error
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
