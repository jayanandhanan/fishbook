// ignore_for_file: unused_local_variable, unnecessary_null_comparison
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fishbook/home_screen.dart';
import 'package:fishbook/login_screen.dart';
import 'package:fishbook/statementsscreen.dart';
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
  String? organizationId;
  bool isHomeScreen = false;

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
  double boatMaintenanceAmount = 0.0;
  
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
 _fetchOrganizationId();
  crewAmountControllers.values.forEach((controller) => controller.dispose());
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

@override
 Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Entry'),
       backgroundColor: Colors.blue,
      ),
      bottomNavigationBar: buildBottomNavigationBar(context,false),
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
              // DataTable to display entered expenses and revenues
            SingleChildScrollView(
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
      DataColumn(label: Text('Action')),
    ],
    rows: _buildDataRows(),
  ),),)
),SizedBox(height: 20),
 Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    _addBoatMaintenanceAmount(context);
                  },
                  child: Text('Add Boat Maintenance Amount'),
                ),
                SizedBox(width: 10),
                Text('Boat Maintenance Amount: $boatMaintenanceAmount'),
              ],
            ),
              SizedBox(height: 20),
              // Display Total Profit
              Text('Total Profit: ${_calculateRemainingAmount().toStringAsFixed(2)}'),
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
      DataColumn(label: Text('Phone')),
      DataColumn(label: Text('Email')),
      DataColumn(label: Text('Amount')),
    ],
    rows: _buildCrewMembersRows(),
  ),),)
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
      DataColumn(label: Text('Phone')),
      DataColumn(label: Text('Email')),
      DataColumn(label: Text('Invest')),
      DataColumn(label: Text('Share')),
       DataColumn(label: Text('Share Amount')),
    ],
    rows: _buildOwnersRows(),
  ),),)
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
    remainingAmount = totalProfit- boatMaintenanceAmount;
  }
  
  // Ensure _calculateShareForOwners() is called only when necessary
  if (!updatingShareForOwners) {
    updatingShareForOwners = true;
    updatingShareForOwners = false;
  }
  return totalProfit;
}
BottomNavigationBar buildBottomNavigationBar(BuildContext context, bool isHomeScreen) {
    return BottomNavigationBar(
      currentIndex: 0,
      fixedColor: Colors.grey, 
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

bool _isDialogOpen = false; // Boolean flag to track if the dialog is open
List<DataRow> _buildCrewMembersRows() {
  if (_isDialogOpen) {
    // Don't display the table if the dialog is open
    return [];
  } else {
    // Display the table only after the dialog is closed
    if (selectedCrewMemberIds.isNotEmpty) {
      return selectedCrewMemberIds.map((memberId) {
        DocumentSnapshot crewMember =
            crewMembers.firstWhere((member) => member.id == memberId);
        TextEditingController amountController =
            crewAmountControllers.putIfAbsent(memberId, () => TextEditingController());

        // Set the initial value of the text field
        amountController.text = crewAmounts[memberId]?.toString() ?? '';

        return DataRow(
          cells: [
            DataCell(Text(crewMember['name']?.toString() ?? '')),
            DataCell(Text(crewMember['phone']?.toString() ?? '')),
            DataCell(Text(crewMember['email']?.toString() ?? '')),
            DataCell(
              SizedBox(
                width: 100,
                child: Focus(
                  onFocusChange: (hasFocus) {
                    if (!hasFocus) {
                      // When focus is lost, update the crewAmounts
                      double amount = double.tryParse(amountController.text) ?? 0.0;
                      crewAmounts[memberId] = amount;
                      setState(() {
                        remainingAmount = _calculateRemainingAmount();
                      });
                    }
                  },
                  child: TextFormField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      // No need to update crewAmounts here
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      }).toList();
    } else {
      return [];
    }
  }
}

Future<void> _selectCrewMembers(BuildContext context) async {
  TextEditingController amountController = TextEditingController();
  double enteredAmount = 0.0; // Store the entered amount

  try {
    // Set the flag to true when the dialog is opened
    _isDialogOpen = true;

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
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return AlertDialog(
                  title: Text('Select Crew Members'),
                  content: Container(
                    height: 300,
                    width: double.maxFinite,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: 'Enter Amount'),
                          onChanged: (value) {
                            setState(() {
                              // Update entered amount
                              enteredAmount = double.tryParse(value) ?? 0.0;
                              // Update crew member amount based on entered amount
                              selectedCrewMemberIds.forEach((memberId) {
                                crewAmounts[memberId] = enteredAmount;
                              });
                            });
                          },
                        ),
                        SizedBox(height: 10),
                        Expanded(
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

                                  return Column(
                                    children: [
                                      CheckboxListTile(
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
                                              // Update crew member amount based on entered amount
                                              crewAmounts[crewMember.id] = enteredAmount;
                                              // Update remaining amount and shares
                                              double remainingAmount = _calculateRemainingAmount();
                                              _updateCrewAmountAndRemaining(remainingAmount);
                                              ownerRemainingAmountShares.forEach((ownerId, ownerShare) {
                                                ownerRemainingAmountShares[ownerId] =
                                                    _calculateRemainingAmountShares(ownerShares[ownerId]!, remainingAmount);
                                              });
                                            }
                                          });
                                        },
                                      ),
                                      SizedBox(height: 10),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // Recalculate remaining amount and shares
                            double remainingAmount = _calculateRemainingAmount();
                            _updateCrewAmountAndRemaining(remainingAmount);
                            ownerRemainingAmountShares.forEach((ownerId, ownerShare) {
                              ownerRemainingAmountShares[ownerId] =
                                  _calculateRemainingAmountShares(ownerShares[ownerId]!, remainingAmount);
                            });
                            // Set the flag to false when the dialog is closed
                            _isDialogOpen = false;
                            Navigator.pop(context);
                          },
                          child: Text('Done'),
                        ),
                      ],
                    ),
                  ),
                );
              },
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
  double remainingAmount = 0.0;

  // Subtract boat maintenance amount from the total profit
  totalProfit -= boatMaintenanceAmount;

  if (crewAmounts.isEmpty) {
    remainingAmount = totalProfit;
  } else {
    double totalCrewAmount = _calculateTotalCrewAmount();
    remainingAmount = totalProfit - totalCrewAmount;
  }

  setState(() {
    this.remainingAmount = remainingAmount;
  });

  return remainingAmount;
}

void _addBoatMaintenanceAmount(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      double? newAmount = 0.0;
      return AlertDialog(
        title: Text('Add Boat Maintenance Amount'),
        content: TextFormField(
          keyboardType: TextInputType.number,
          onChanged: (value) {
            newAmount = double.tryParse(value) ?? 0.0;
          },
          decoration: InputDecoration(labelText: 'Enter Amount'),
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
                boatMaintenanceAmount = newAmount ?? 0.0;
                remainingAmount = _calculateRemainingAmount();
                // Update remaining amount shares after updating remaining amount
                ownerRemainingAmountShares.forEach((ownerId, ownerShare) {
                  ownerRemainingAmountShares[ownerId] = _calculateRemainingAmountShares(ownerShares[ownerId]!, remainingAmount);
                });
              });
              Navigator.of(context).pop();
            },
            child: Text('Add'),
          ),
        ],
      );
    },
  );
}

void _updateCrewAmountAndRemaining(double remainingAmount) {
  setState(() {
    this.remainingAmount = remainingAmount;
  });
}

double _calculateRemainingAmountShares(double ownerShare, double remainingAmount) {
  double remainingAmountAfterMaintenance = remainingAmount ;
  double remainingAmountShare = remainingAmountAfterMaintenance > 0 ? (ownerShare / 100) * remainingAmountAfterMaintenance : 0;
  return double.parse(remainingAmountShare.toStringAsFixed(2));
}


List<DataRow> _buildOwnersRows() {
  return owners
      .where((owner) => selectedOwnerIds.contains(owner.id))
      .map((owner) {
    double share = double.parse(owner['share'] ?? '0.0'); // Convert share to double
    double remainingAmountShare = _calculateRemainingAmountShares(share, remainingAmount);

    // Format remainingAmountShare to display with two digits after the decimal point
    String formattedRemainingAmountShare = remainingAmountShare.toStringAsFixed(2);

    return DataRow(
      cells: [
        DataCell(Text(owner['name']?.toString() ?? '')),
        DataCell(Text(owner['phone']?.toString() ?? '')),
        DataCell(Text(owner['email']?.toString() ?? '')),
        DataCell(Text(owner['invest']?.toString() ?? '0.0')), // Display owner's investment from owner details
        DataCell(Text(share.toString())), // Display owner's share from owner details
        DataCell(Text(formattedRemainingAmountShare)), // Display remaining amount share with two digits after the decimal point
      ],
    );
  }).toList();
}


Future<void> _selectOwners(BuildContext context) async {
  try {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        String organizationId = userDoc['organizationId'];

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
                                  Text('Share: ${owner['share']?.toString() ?? '0.0'}'),
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
                                    }
                                    // Calculate remaining amount share when selecting/deselecting
                                    _calculateRemainingAmountShares(double.parse(owner['share'] ?? '0.0'), remainingAmount);
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

              // Create boatmaintenanceamounts subcollection
              CollectionReference boatMaintenanceCollection =
                  organizationDocRef.collection('boatmaintenanceamounts');

            // Add fields for the new entry
            await newEntryDocRef.set({
              'monthconsidered': selectedMonth,
              'sailingdate': selectedSailingDate,
              'returndate': selectedReturnDate,
              'totalprofit': _calculateTotalProfit(),
              'remainingamount': _calculateRemainingAmount(),
              'boatmaintenanceamount': boatMaintenanceAmount ?? 0.0,
            });

            // Add subcollections
            await _addRevenueSubcollection(newEntryDocRef);
            await _addExpenseSubcollection(newEntryDocRef);
            await _addSalaryToCrewMembersSubcollection(newEntryDocRef,organizationId);
            await _addOwnerShareSubcollection(newEntryDocRef,organizationId);

              // Create document in boatmaintenanceamounts subcollection
              await boatMaintenanceCollection.doc(newEntryDocRef.id).set({
                'sailingdate': selectedSailingDate,
                'returndate': selectedReturnDate,
                'boatmaintenanceamount': boatMaintenanceAmount ?? 0.0,
                'remainingboatmaintenanceamount':boatMaintenanceAmount ?? 0.0,
                'usedamount':0.0,
              });

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
DateTime currentDateWithoutTime = DateTime(currentDate.year, currentDate.month, currentDate.day);

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
      'paymentdate': Timestamp.fromDate(currentDateWithoutTime),
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
  DateTime currentDateWithoutTime = DateTime(currentDate.year, currentDate.month, currentDate.day);

  for (var ownerId in selectedOwnerIds) {
    var owner = owners.firstWhere((element) => element.id == ownerId);

    // Calculate remaining amount share
    double remainingAmountShare = _calculateRemainingAmountShares(double.parse(owner['share'] ?? '0.0'), remainingAmount);

    // Use the ownerId as the document ID for ownerShareCollection
    DocumentReference ownerShareDocRef = ownerShareCollection.doc(ownerId);

    // Generate unique document ID for paymentdetails
    DocumentReference paymentDocRef = paymentDetailsCollection.doc();

    await ownerShareDocRef.set({
      'name': owner['name'],
      'phone': owner['phone'],
      'email': owner['email'],
      'invest': owner['invest'],
      'share': owner['share'],
      'remainingamountshare': remainingAmountShare.toStringAsFixed(2), // Convert to string with two decimal places
    });

    // Set inchargeId as ownerId in the paymentdetails document
    await paymentDocRef.set({
      'name': owner['name'],
      'phone': owner['phone'],
      'email': owner['email'],
      'invest': owner['invest'],
      'share': owner['share'],
      'remainingamountshare': remainingAmountShare.toStringAsFixed(2), // Convert to string with two decimal places
      'user': 'Owner',
      'payment': 'Not Paid',
      'paidamount':'0.0',
      'pendingamount':'0.0',
      'modeofpayment':'Cash',
      'paymentdate': Timestamp.fromDate(currentDateWithoutTime),
      'inchargeid': ownerId, // Set inchargeId as ownerId
      'newentryid': newEntryDocId,
    });
  }
}

}