// ignore_for_file: unused_local_variable

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class NewEntryScreen extends StatefulWidget {
  @override
  _NewEntryScreenState createState() => _NewEntryScreenState();
}

class _NewEntryScreenState extends State<NewEntryScreen> {
 

  final FirebaseAuth _auth = FirebaseAuth.instance;
  TextEditingController returnDateController = TextEditingController();
  TextEditingController expenseNameController = TextEditingController();
  TextEditingController expenseAmountController = TextEditingController();
  TextEditingController revenueAmountController = TextEditingController();
  TextEditingController crewNameController = TextEditingController();
  TextEditingController crewPhoneController = TextEditingController();
  TextEditingController crewAmountController = TextEditingController();


  String selectedMonth = 'Jan';
  DateTime? selectedSailingDate;
  DateTime? selectedReturnDate;

  List<DocumentSnapshot> crewMembers = [];
  List<DocumentSnapshot> owners = [];
  Set<String> selectedCrewMemberIds = {};
  Set<String> selectedOwnerIds = {};
  Map<String, double> crewAmounts = {};
  Map<String, double> ownerInvestments = {};
  Map<String, double> ownerShares = {};
  double totalInvest = 0.0;

  List<Map<String, dynamic>> expensesList = [];
  List<Map<String, dynamic>> revenuesList = [];

// Define a Map to hold amount controllers for each crew member
Map<String, TextEditingController> crewAmountControllers = {};
Map<String, TextEditingController> ownerInvestmentControllers = {};

 @override
void dispose() {
  super.dispose();
 
  crewAmountControllers.values.forEach((controller) => controller.dispose());
  ownerInvestmentControllers.values.forEach((controller) => controller.dispose());
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Entry'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: selectedMonth,
                items: [
                  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
                ].map((String month) {
                  return DropdownMenuItem<String>(
                    value: month,
                    child: Text(month),
                  );
                }).toList(),
                onChanged: (String? value) {
                  setState(() {
                    selectedMonth = value ?? 'Jan';
                  });
                },
                decoration: InputDecoration(labelText: 'Month Considered'),
              ),
              SizedBox(height: 10),
              InkWell(
                onTap: () => _selectSailingDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Sailing Date',
                    border: OutlineInputBorder(),
                  ),
                  child: selectedSailingDate != null
                      ? Text(
                          "${selectedSailingDate!.day.toString().padLeft(2, '0')}-${selectedSailingDate!.month.toString().padLeft(2, '0')}-${selectedSailingDate!.year}",
                        )
                      : Text('Select Sailing Date'),
                ),
              ),
              SizedBox(height: 10),
              InkWell(
                onTap: () => _selectReturnDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Return Date',
                    border: OutlineInputBorder(),
                  ),
                  child: selectedReturnDate != null
                      ? Text(
                          "${selectedReturnDate!.day.toString().padLeft(2, '0')}-${selectedReturnDate!.month.toString().padLeft(2, '0')}-${selectedReturnDate!.year}",
                        )
                      : Text('Select Return Date'),
                ),
              ),
              SizedBox(height: 20),

              // Expenses
              TextFormField(
                controller: expenseNameController,
                decoration: InputDecoration(labelText: 'Expense Name'),
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: expenseAmountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Expense Amount'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  String expenseName = expenseNameController.text.isNotEmpty
                      ? expenseNameController.text
                      : 'n/a';

                  expensesList.add({
                    'expensename': expenseName,
                    'expenseamount': double.tryParse(expenseAmountController.text) ?? 0.0,
                  });

                  expenseNameController.clear();
                  expenseAmountController.clear();
                  setState(() {});
                },
                child: Text('Add Expense'),
              ),
              SizedBox(height: 20),

              // Revenues
              TextFormField(
                controller: revenueAmountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Revenue Amount'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  if (revenueAmountController.text.isNotEmpty) {
                    double amount = double.parse(revenueAmountController.text);
                    revenuesList.add({
                      'amount': amount,
                    });
                    revenueAmountController.clear();
                    setState(() {});
                  }
                },
                child: Text('Add Revenue'),
              ),
              

              // DataTable to display entered expenses and revenues
            SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: DataTable(
    columnSpacing: 16.0,
    columns: [
      DataColumn(label: Text('Revenue Amount')),
      DataColumn(label: Text('Expense Name')),
      DataColumn(label: Text('Expense Amount')),
      DataColumn(label: Text('Action')),
    ],
    rows: _buildDataRows(),
  ),
),

              SizedBox(height: 20),

              // Display Total Profit
              Text('Total Profit: ${_calculateTotalProfit().toStringAsFixed(2)}'),
              SizedBox(height: 20),

              // Select Crew Members
              ElevatedButton(
                onPressed: () async {
                  await _selectCrewMembers(context);
                },
                child: Text('Select/Unselect Crew Members'),
              ),

              if (selectedCrewMemberIds.isNotEmpty)
              SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: DataTable(
    columnSpacing: 16.0, // Adjust the spacing between columns as needed
    columns: [
      DataColumn(label: Text('Crew Member Name')),
      DataColumn(label: Text('Crew Member Phone')),
      DataColumn(label: Text('Crew Member Email')),
      DataColumn(label: Text('Amount')),
    ],
    rows: _buildCrewMembersRows(),
  ),
),

              SizedBox(height: 20),

              // Select Owners
              ElevatedButton(
                onPressed: () async {
                  await _selectOwners(context);
                },
                child: Text('Select/Unselect Owners'),
              ),

              if (selectedOwnerIds.isNotEmpty)
               SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: DataTable(
    columnSpacing: 16.0, // Adjust the spacing between columns as needed
    columns: [
      DataColumn(label: Text('Owner Name')),
      DataColumn(label: Text('Owner Phone')),
      DataColumn(label: Text('Owner Email')),
      DataColumn(label: Text('Invest')),
      DataColumn(label: Text('Share')),
    ],
    rows: _buildOwnersRows(),
  ),
),

             
              

              SizedBox(height: 20),

              // Calculate Share for Owners
              ElevatedButton(
                onPressed: () {
                  _calculateShareForOwners();
                  _addNewEntry();
                },
                child: Text('Calculate Share & Add to New Entry'),
              ),
            ],
          ),
        ),
      ),
    );
  }


  List<DataRow> _buildDataRows() {
    List<DataRow> rows = [];
    for (int i = 0; i < max(expensesList.length, revenuesList.length); i++) {
      Map<String, dynamic> expense = i < expensesList.length ? expensesList[i] : {};
      Map<String, dynamic> revenue = i < revenuesList.length ? revenuesList[i] : {};

      DataRow row = DataRow(cells: [
        DataCell(Text(revenue['amount']?.toString() ?? '')),
        DataCell(Text(expense['expensename'] ?? '')),
        DataCell(Text(expense['expenseamount']?.toString() ?? '')),
        
        DataCell(
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  _editTableRow(i, expense, revenue);
                },
              ),
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  _deleteTableRow(i);
                },
              ),
            ],
          ),
        ),
      ]);

      rows.add(row);
    }
    return rows;
  }

 
  void _editTableRow(int index, Map<String, dynamic> expense, Map<String, dynamic> revenue) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Row'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (revenue.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Edit Revenue:'),
                      TextFormField(
                        initialValue: revenue['amount']?.toString() ?? '',
                        onChanged: (value) {
                          revenue['amount'] = double.tryParse(value) ?? 0.0;
                        },
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: 'Revenue Amount'),
                      ),
                    ],
                  ),
                if (expense.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Edit Expense:'),
                      TextFormField(
                        initialValue: expense['expensename'] ?? '',
                        onChanged: (value) {
                          expense['expensename'] = value;
                        },
                        decoration: InputDecoration(labelText: 'Expense Name'),
                      ),
                      TextFormField(
                        initialValue: expense['expenseamount']?.toString() ?? '',
                        onChanged: (value) {
                          expense['expenseamount'] = double.tryParse(value) ?? 0.0;
                        },
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: 'Expense Amount'),
                      ),
                    ],
                  ),
                
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  // Update the edited values in the lists
                  if (expense.isNotEmpty) {
                    expensesList[index] = {...expense};
                  }
                  if (revenue.isNotEmpty) {
                    revenuesList[index] = {...revenue};
                  }
                });
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

 void _deleteTableRow(int index) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Delete Row'),
        content: Text('Are you sure you want to delete this row?'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                // Remove the selected row from the lists
                if (index >= 0 && index < expensesList.length) {
                  expensesList.removeAt(index);
                }

                if (index >= 0 && index < revenuesList.length) {
                  revenuesList.removeAt(index);
                }
              });
              Navigator.of(context).pop();
            },
            child: Text('Delete'),
          ),
        ],
      );
    },
  );
}

  double _calculateTotalProfit() {
    double totalExpenses = expensesList.fold(0, (sum, expense) => sum + (expense['expenseamount'] ?? 0.0));
    double totalRevenues = revenuesList.fold(0, (sum, revenue) => sum + (revenue['amount'] ?? 0.0));
    return totalRevenues - totalExpenses;
  }

  Future<void> _selectSailingDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark(), // Set the theme to dark
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedSailingDate) {
      setState(() {
        selectedSailingDate = picked;
      });
    }
  }

  Future<void> _selectReturnDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedSailingDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark(), // Set the theme to dark
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedReturnDate) {
      setState(() {
        selectedReturnDate = picked;
      });
    }
  }





void _calculateShareForOwners() {
    totalInvest = _calculateTotalInvest();

    for (var owner in owners) {
      if (selectedOwnerIds.contains(owner.id)) {
        double ownerInvest = ownerInvestments[owner.id] ?? 0;
        double share = _calculateShare(ownerInvest, totalInvest);
        setState(() {
          ownerShares[owner.id] = share;
        });
      }
    }
  }

  double _calculateShare(double invest, double totalInvest) {
    return invest > 0 && totalInvest > 0 ? (invest / totalInvest) * 100 : 0;
  }

  double _calculateTotalInvest() {
    double total = 0;
    for (var ownerId in ownerInvestments.keys) {
      if (selectedOwnerIds.contains(ownerId)) {
        total += ownerInvestments[ownerId] ?? 0;
      }
    }
    return total;
  }

 List<DataRow> _buildCrewMembersRows() {
  return crewMembers
      .where((crewMember) => selectedCrewMemberIds.contains(crewMember.id))
      .map((crewMember) {
    String memberId = crewMember.id;
    late TextEditingController amountController;
    if (crewAmountControllers.containsKey(memberId)) {
      amountController = crewAmountControllers[memberId]!;
    } else {
      amountController = TextEditingController(
          text: (crewAmounts[memberId] ?? 0.0).toString());
      crewAmountControllers[memberId] = amountController;
    }

    return DataRow(
      cells: [
        DataCell(Text(crewMember['name']?.toString() ?? '')),
        DataCell(Text(crewMember['phone']?.toString() ?? '')),
        DataCell(Text(crewMember['email']?.toString() ?? '')),
        DataCell(
          TextFormField(
            controller: amountController,
            keyboardType: TextInputType.number,
            onChanged: (value) {
              double amount = double.tryParse(value) ?? 0.0;
              setState(() {
                crewAmounts[memberId] = amount;
              });
            },
           
          ),
        ),
      ],
    );
  }).toList();
}


Future<void> _selectCrewMembers(BuildContext context) async {
  try {
    // Retrieve the current user
    User? user = _auth.currentUser;

    if (user != null) {
      // Retrieve user's organization ID from Firestore
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        String organizationId = userDoc['organizationId'];

        // Proceed with your dialog to select crew members using the obtained organizationId
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Select Crew Members'),
              content: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return Container(
                    height: 300,
                    width: double.maxFinite,
                    child: FutureBuilder(
                      future: FirebaseFirestore.instance
                          .collection('organizations')
                          .doc(organizationId)
                          .collection('crewmemberdetails')
                          .get(),
                      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        }

                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }

                        crewMembers = snapshot.data?.docs ?? [];

                        return ListView.builder(
                          itemCount: crewMembers.length,
                          itemBuilder: (BuildContext context, int index) {
                            DocumentSnapshot crewMember = crewMembers[index];
                            bool isSelected = selectedCrewMemberIds.contains(crewMember.id);

                            return CheckboxListTile(
                              title: Text(crewMember['name']?.toString() ?? ''),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(crewMember['phone']?.toString() ?? ''),
                                  Text(crewMember['email']?.toString() ?? ''),
                                ],
                              ),
                              value: isSelected,
                              onChanged: (bool? newBool) {
                                setState(() {
                                  if (newBool != null) {
                                    if (newBool) {
                                      selectedCrewMemberIds.add(crewMember.id);
                                    } else {
                                      selectedCrewMemberIds.remove(crewMember.id);
                                      // Dispose of the amount controller when unselecting
                                      crewAmountControllers[crewMember.id]?.dispose();
                                      crewAmountControllers.remove(crewMember.id);
                                    }
                                  }
                                });
                              },
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {});
                  },
                  child: Text('Done'),
                ),
              ],
            );
          },
        );
      } else {
        print('User document does not exist.');
      }
    } else {
      print('User is not logged in.');
    }
  } catch (e) {
    print('Error selecting crew members: $e');
  }
}

List<DataRow> _buildOwnersRows() {
  return owners
      .where((owner) => selectedOwnerIds.contains(owner.id))
      .map((owner) {
    String ownerId = owner.id;
    late TextEditingController investmentController;
    if (ownerInvestmentControllers.containsKey(ownerId)) {
      investmentController = ownerInvestmentControllers[ownerId]!;
    } else {
      investmentController = TextEditingController(
          text: (ownerInvestments[ownerId] ?? 0.0).toString());
      ownerInvestmentControllers[ownerId] = investmentController;
    }

    return DataRow(
      cells: [
        DataCell(Text(owner['name']?.toString() ?? '')),
        DataCell(Text(owner['phone']?.toString() ?? '')),
        DataCell(Text(owner['email']?.toString() ?? '')),
        DataCell(
          TextFormField(
            controller: investmentController,
            keyboardType: TextInputType.number,
            onChanged: (value) {
              double investment = double.tryParse(value) ?? 0.0;
              setState(() {
                ownerInvestments[ownerId] = investment;
                  _calculateShareForOwners();
              });
            },
           
          ),
        ),
        DataCell(Text('0.0')), // Always display '0' for double share
      ],
    );
  }).toList();
}


Future<void> _selectOwners(BuildContext context) async {
  try {
    // Retrieve the current user
    User? user = _auth.currentUser;

    if (user != null) {
      // Retrieve user's organization ID from Firestore
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        String organizationId = userDoc['organizationId'];

        // Proceed with your dialog to select owners using the obtained organizationId
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Select Owners'),
              content: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return Container(
                    height: 300,
                    width: double.maxFinite,
                    child: FutureBuilder(
                      future: FirebaseFirestore.instance
                          .collection('organizations')
                          .doc(organizationId)
                          .collection('ownerdetails')
                          .get(),
                      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        }

                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }

                        owners = snapshot.data?.docs ?? [];

                        return ListView.builder(
                          itemCount: owners.length,
                          itemBuilder: (BuildContext context, int index) {
                            DocumentSnapshot owner = owners[index];
                            bool isChecked = selectedOwnerIds.contains(owner.id);

                            return CheckboxListTile(
                              title: Text(owner['name']?.toString() ?? ''),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(owner['phone']?.toString() ?? ''),
                                  Text(owner['email']?.toString() ?? ''),
                                ],
                              ),
                              value: isChecked,
                              onChanged: (bool? newBool) {
                                setState(() {
                                  if (newBool != null) {
                                    if (newBool) {
                                      selectedOwnerIds.add(owner.id);
                                    } else {
                                      selectedOwnerIds.remove(owner.id);
                                      // Dispose of the investment controller when unselecting
                                      ownerInvestmentControllers[owner.id]?.dispose();
                                      ownerInvestmentControllers.remove(owner.id);
                                    }
                                  }
                                });
                              },
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {});
                  },
                  child: Text('Done'),
                ),
              ],
            );
          },
        );
      } else {
        print('User document does not exist.');
      }
    } else {
      print('User is not logged in.');
    }
  } catch (e) {
    print('Error selecting owners: $e');
  }
}

Future<void> _addNewEntry() async {
  try {
    // Step 1: Retrieve the current user
    User? user = _auth.currentUser;

    if (user != null) {
      // Step 2: Retrieve user's role and organization ID from Firestore
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        String userRole = userDoc['role']; // Assuming you have a 'role' field for the user
        String organizationId =
            userDoc['organizationId']; // Assuming you have an 'organizationId' field for the user

        // Step 3: Check if the user's role is 'Headowner'
        if (userRole == 'Headowner') {
          // Step 4: Allow Headowner to create newentrycollection for their organization with four subcollections
          CollectionReference organizationCollection =
              FirebaseFirestore.instance.collection('organizations');
          DocumentReference organizationDocRef = organizationCollection.doc(organizationId);

          // Check if the organization already exists
          bool organizationExists =
              await organizationDocRef.get().then((doc) => doc.exists);

          if (organizationExists) {
            // If the organization exists, add new entry directly
            DocumentReference newEntryDocRef = organizationDocRef.collection('newentry').doc();

            // Add fields for the new entry
            await newEntryDocRef.set({
              'monthconsidered': selectedMonth,
              'sailingdate': selectedSailingDate,
              'returndate': selectedReturnDate,
              'totalprofit': _calculateTotalProfit(),
            });

            // Add subcollections
            await _addRevenueSubcollection(newEntryDocRef);
            await _addExpenseSubcollection(newEntryDocRef);
            await _addSalaryToCrewMembersSubcollection(newEntryDocRef);
            await _addOwnerShareSubcollection(newEntryDocRef);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Added to New Entry'),
              ),
            );
           // Navigate back to the home screen
            Navigator.pop(context);

          } else {
            print('Organization does not exist.');
          }
        } else {
          // If the user's role is not 'Headowner', display a message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You do not have permission to add new entries.'),
            ),
          );
        }
      } else {
        print('User document does not exist.');
      }
    } else {
      print('User is not logged in.');
    }
  } catch (e) {
    print('Error adding to New Entry: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error adding to New Entry. Please try again.'),
      ),
    );
  }
}

Future<void> _addRevenueSubcollection(DocumentReference newEntryDocRef) async {
  CollectionReference revenueCollection = newEntryDocRef.collection('revenue');
  for (var revenueEntry in revenuesList) {
    await revenueCollection.add(revenueEntry);
  }
}

Future<void> _addSalaryToCrewMembersSubcollection(
    DocumentReference newEntryDocRef) async {
  CollectionReference salaryToCrewMembersCollection =
      newEntryDocRef.collection('salarytocrewmembers');

  for (var crewMemberId in selectedCrewMemberIds) {
    var crewMember = crewMembers.firstWhere((element) => element.id == crewMemberId);

    // Use the same ID as the 'crewmembers' collection
    DocumentReference salaryDocRef = salaryToCrewMembersCollection.doc(crewMemberId);

    await salaryDocRef.set({
      'name': crewMember['name'],
      'phone': crewMember['phone'],
      'email': crewMember['email'],
      'amount': crewAmounts[crewMemberId],
    });
  }
}

Future<void> _addExpenseSubcollection(DocumentReference newEntryDocRef) async {
  CollectionReference expenseCollection = newEntryDocRef.collection('expense');
  for (var expenseEntry in expensesList) {
    await expenseCollection.add(expenseEntry);
  }
}

Future<void> _addOwnerShareSubcollection(DocumentReference newEntryDocRef) async {
  CollectionReference ownerShareCollection = newEntryDocRef.collection('ownershare');

  for (var ownerId in selectedOwnerIds) {
    var owner = owners.firstWhere((element) => element.id == ownerId);

    // Use the same ID as the 'owners' collection
    DocumentReference ownerShareDocRef = ownerShareCollection.doc(ownerId);

    await ownerShareDocRef.set({
      'name': owner['name'],
      'phone': owner['phone'],
      'email': owner['email'],
      'invest': ownerInvestments[ownerId],
      'share': ownerShares[ownerId],
    });
  }
}}