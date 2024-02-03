// ignore_for_file: unused_local_variable, unnecessary_null_comparison
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
  Map<String, double> ownerProfitShares = {};
  Map<String, double> ownerRemainingAmountShares = {};
  Map<String, double> ownerInvestments = {};
  Map<String, double> ownerShares = {};
  double totalInvest = 0.0;
  double remainingAmount = 0.0; 
  double totalCrewAmount = 0.0;
  
  List<Map<String, dynamic>> expensesList = [];
  List<Map<String, dynamic>> revenuesList = [];

  bool updatingShareForOwners = false;
  bool isAddingEntry = false; // Add this line to declare the flag

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
              
 SizedBox(height: 20),
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
                  // Display Remaining Amount
              Text('Remaining Amount After Giving Crewmembers Salary: ${remainingAmount.toStringAsFixed(2)}'),
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
      DataColumn(label: Text('Name')),
      DataColumn(label: Text('Phone')),
      DataColumn(label: Text('Email')),
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
      DataColumn(label: Text('Name')),
      DataColumn(label: Text('Phone')),
      DataColumn(label: Text('Email')),
      DataColumn(label: Text('Invest')),
      DataColumn(label: Text('Share')),
      DataColumn(label: Text('Profit Amount Share')),
      DataColumn(label: Text('Remaining Amount Share')),
    ],
    rows: _buildOwnersRows(),
  ),
),
              SizedBox(height: 20),

              // Calculate Share for Owners
              ElevatedButton(
                onPressed: isAddingEntry ? null : _addNewEntry,
                child: Text('Add to Database'),
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
  double totalProfit = totalRevenues - totalExpenses;

  if (selectedCrewMemberIds.isEmpty) {
    // If there are no crew members selected, set remaining amount to total profit
    remainingAmount = totalProfit;
  }
  
  // Ensure _calculateShareForOwners() is called only when necessary
  if (!updatingShareForOwners) {
    updatingShareForOwners = true;
    _calculateShareForOwners();
    updatingShareForOwners = false;
  }
  return totalProfit;
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
            SizedBox(
              width: 100,
              child: TextFormField(
                controller: amountController,
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  double amount = double.tryParse(value) ?? 0.0;
                  crewAmounts[memberId] = amount;
                  setState(() {
                    remainingAmount = _calculateRemainingAmount();
                  });
                },
              ),
            ),
          ),
        ],
      );
    }).toList();
  }

Future<void> _selectCrewMembers(BuildContext context) async {
    double totalProfit = _calculateTotalProfit();
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
 double remainingAmount = newBool
        ? _calculateRemainingAmount()
        : totalProfit - _calculateTotalCrewAmount(); // Subtract unselected crew member's amount
      _updateCrewAmountAndRemaining(remainingAmount);
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

double _calculateTotalCrewAmount() {
  return selectedCrewMemberIds.fold(0, (sum, memberId) => sum + (crewAmounts[memberId] ?? 0.0));
}

double _calculateRemainingAmount() {
  double totalExpenses = expensesList.fold(0, (sum, expense) => sum + (expense['expenseamount'] ?? 0.0));
  double totalRevenues = revenuesList.fold(0, (sum, revenue) => sum + (revenue['amount'] ?? 0.0));
  double totalProfit = totalRevenues - totalExpenses;
  double remainingAmount;
  if (crewAmounts.isEmpty) {
    // If there are no crew amounts, set remaining amount to total profit
     setState(() {
      remainingAmount = totalProfit;
    });
    return totalProfit;
  } else {
    // Calculate total crew amount if crew amounts are present
    double totalCrewAmount = _calculateTotalCrewAmount();
    remainingAmount = totalProfit - totalCrewAmount;
    setState(() {
      this.remainingAmount = remainingAmount;
    });
  }
  return remainingAmount;
}

void _updateCrewAmountAndRemaining(double remainingAmount) {
  setState(() {
    this.remainingAmount = remainingAmount;
  });
}

void _calculateShareForOwners() {
  double totalProfit = _calculateTotalProfit();
  double remainingAmount = _calculateRemainingAmount();
  totalInvest = _calculateTotalInvest();

  for (var owner in owners) {
    if (selectedOwnerIds.contains(owner.id)) {
      double ownerInvest = ownerInvestments[owner.id] ?? 0;
      double share = _calculateShare(ownerInvest, totalInvest);
      double profitShareAmount = totalProfit > 0 ? (share / 100) * totalProfit : 0; // Calculate profit share only if total profit is non-zero
      double remainingAmountShare = remainingAmount > 0 ? (share / 100) * remainingAmount : 0;
      setState(() {
        ownerShares[owner.id] = share;
        ownerProfitShares[owner.id] = profitShareAmount;
        ownerRemainingAmountShares[owner.id] = remainingAmountShare;
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
        DataCell(Text(ownerShares[owner.id]?.toString() ?? '0.0')), // Display owner's share
        DataCell(Text(ownerProfitShares[owner.id]?.toString() ?? '0.0')), // Display profit share amount // Always display '0' for double share
        DataCell(Text(ownerRemainingAmountShares[owner.id]?.toString() ?? '0.0')), // Display remaining amount share
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
                                     _calculateShareForOwners();
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
 // Prevent multiple submissions
  if (isAddingEntry) {
    return;
  }

  setState(() {
    isAddingEntry = true;
  });
  
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
          // Step 4: Allow Headowner to create new entry collection for their organization with four subcollections
          CollectionReference organizationCollection =
              FirebaseFirestore.instance.collection('organizations');
          DocumentReference organizationDocRef = organizationCollection.doc(organizationId);

          // Check if the organization already exists
          bool organizationExists =
              await organizationDocRef.get().then((doc) => doc.exists);

          if (organizationExists) {
            // Validate if necessary fields are selected
            if (selectedSailingDate == null ||
                selectedReturnDate == null ||
                selectedMonth == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Please select sailing date, return date, and month.'),
                ),
              );
              return; // Exit function if validation fails
            }

            // If the organization exists and necessary fields are selected, add new entry directly
            DocumentReference newEntryDocRef = organizationDocRef.collection('newentry').doc();

            // Add fields for the new entry
            await newEntryDocRef.set({
              'monthconsidered': selectedMonth,
              'sailingdate': selectedSailingDate,
              'returndate': selectedReturnDate,
              'totalprofit': _calculateTotalProfit(),
              'remainingamount': _calculateRemainingAmount(),
            });

            // Add subcollections
            await _addRevenueSubcollection(newEntryDocRef);
            await _addExpenseSubcollection(newEntryDocRef);
            await _addSalaryToCrewMembersSubcollection(newEntryDocRef,organizationId);
            await _addOwnerShareSubcollection(newEntryDocRef,organizationId);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Added to New Entry'),
              ),
            );

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
finally {
    setState(() {
      isAddingEntry = false;
    });
  }
}

Future<void> _addRevenueSubcollection(DocumentReference newEntryDocRef) async {
  CollectionReference revenueCollection = newEntryDocRef.collection('revenue');
  for (var revenueEntry in revenuesList) {
    await revenueCollection.add(revenueEntry);
  }
}

Future<void> _addSalaryToCrewMembersSubcollection(DocumentReference newEntryDocRef, String organizationId) async {
  CollectionReference salaryToCrewMembersCollection = newEntryDocRef.collection('salarytocrewmembers');
  CollectionReference paymentDetailsCollection = FirebaseFirestore.instance.collection('organizations').doc(organizationId).collection('paymentdetails');

  // Retrieve the ID of newEntryDocRef
  String newEntryDocId = newEntryDocRef.id;

  // Get the current datetime
  DateTime currentDate = DateTime.now();

  for (var crewMemberId in selectedCrewMemberIds) {
    var crewMember = crewMembers.firstWhere((element) => element.id == crewMemberId);

    // Use crewMemberId as the document ID for salarytocrewmembers
    DocumentReference salaryDocRef = salaryToCrewMembersCollection.doc(crewMemberId);

    // Generate unique document ID for paymentdetails
    DocumentReference paymentDocRef = paymentDetailsCollection.doc();

    await salaryDocRef.set({
      'name': crewMember['name'],
      'phone': crewMember['phone'],
      'email': crewMember['email'],
      'amount': crewAmounts[crewMemberId],
    });

    // Set inchargeId as crewMemberId in the paymentdetails document
    await paymentDocRef.set({
      'name': crewMember['name'],
      'phone': crewMember['phone'],
      'email': crewMember['email'],
      'amount': crewAmounts[crewMemberId],
      'user': 'Crew Member',
      'payment': 'Not Paid',
      'paidamount':'0.0',
      'pendingamount':'0.0',
      'modeofpayment':'Cash',
      'date': Timestamp.fromDate(currentDate),
      'inchargeid': crewMemberId, // Set inchargeId as crewMemberId
      'newentryid': newEntryDocId, // Set newentryid with the document ID of newEntryDocRef
    });
  }
}


Future<void> _addExpenseSubcollection(DocumentReference newEntryDocRef) async {
  CollectionReference expenseCollection = newEntryDocRef.collection('expense');
  for (var expenseEntry in expensesList) {
    await expenseCollection.add(expenseEntry);
  }
}

Future<void> _addOwnerShareSubcollection(DocumentReference newEntryDocRef, String organizationId) async {
  CollectionReference ownerShareCollection = newEntryDocRef.collection('ownershare');
  CollectionReference paymentDetailsCollection = FirebaseFirestore.instance.collection('organizations').doc(organizationId).collection('paymentdetails');

 // Retrieve the ID of newEntryDocRef
  String newEntryDocId = newEntryDocRef.id;

  // Get the current datetime
  DateTime currentDate = DateTime.now();

  for (var ownerId in selectedOwnerIds) {
    var owner = owners.firstWhere((element) => element.id == ownerId);

    // Use the ownerId as the document ID for ownerShareCollection
    DocumentReference ownerShareDocRef = ownerShareCollection.doc(ownerId);

    // Generate unique document ID for paymentdetails
    DocumentReference paymentDocRef = paymentDetailsCollection.doc();

    double totalProfit = _calculateTotalProfit();
    double profitShareAmount = _calculateProfitShareAmount(ownerShares[ownerId]!, totalProfit);
    double remainingAmountShare = _calculateRemainingAmountShare(ownerShares[ownerId]!, remainingAmount);

    await ownerShareDocRef.set({
      'name': owner['name'],
      'phone': owner['phone'],
      'email': owner['email'],
      'invest': ownerInvestments[ownerId],
      'share': ownerShares[ownerId],
      'profitshareamount': profitShareAmount,
      'remainingamountshare': remainingAmountShare,
    });

    // Set inchargeId as ownerId in the paymentdetails document
    await paymentDocRef.set({
      'name': owner['name'],
      'phone': owner['phone'],
      'email': owner['email'],
      'invest': ownerInvestments[ownerId],
      'share': ownerShares[ownerId],
      'profitshareamount': profitShareAmount,
      'remainingamountshare': remainingAmountShare,
      'user': 'Owner',
      'payment': 'Not Paid',
      'paidamount':'0.0',
      'pendingamount':'0.0',
      'modeofpayment':'Cash',
      'date': Timestamp.fromDate(currentDate),
      'inchargeid': ownerId, // Set inchargeId as ownerId
      'newentryid': newEntryDocId,
    });
  }
}


double _calculateRemainingAmountShare(double sharePercentage, double remainingAmount) {
  double remainingAmount = _calculateRemainingAmount();
  // Calculate the remaining amount share based on the share percentage and the remaining amount
  double remainingAmountShare = remainingAmount > 0 ? (sharePercentage / 100.0) * remainingAmount : 0;
  return remainingAmountShare;
}

double _calculateProfitShareAmount(double sharePercentage, double totalProfit) {
  double totalProfit = _calculateTotalProfit();
  // Calculate the profit share amount based on the share percentage and the total profit
  double profitShareAmount = totalProfit > 0 ? (sharePercentage / 100.0) * totalProfit : 0;
  return profitShareAmount;
}
}