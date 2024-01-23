// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class NewEntryScreen extends StatefulWidget {
  @override
  _NewEntryScreenState createState() => _NewEntryScreenState();
}

class _NewEntryScreenState extends State<NewEntryScreen> {
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

  CollectionReference newEntryCollection =
      FirebaseFirestore.instance.collection('newentry');

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
              DataTable(
                columns: [
                  DataColumn(label: Text(' Revenue Amount')),
                  DataColumn(label: Text('Expense Name')),
                  DataColumn(label: Text('Expense Amount')),
                  DataColumn(label: Text('Action')),
                ],
                rows: _buildDataRows(),
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
                DataTable(
                  columns: [
                    DataColumn(label: Text('Crew Member Name')),
                    DataColumn(label: Text('Crew Member Phone')),
                    DataColumn(label: Text('Crew Member Email')),
                    DataColumn(label: Text('Amount')),
                  
                  ],
                  rows: _buildCrewMembersRows(),
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
                DataTable(
                  columns: [
                    DataColumn(label: Text('Owner Name')),
                    DataColumn(label: Text('Owner Phone')),
                    DataColumn(label: Text('Owner Email')),
                    DataColumn(label: Text('Invest')),
                    DataColumn(label: Text('Share')),
                   
                  ],
                  rows: _buildOwnersRows(),
                ),
              SizedBox(height: 20),

              // Total Invest
              Text('Total Invest: $totalInvest'),

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

List<DataRow> _buildCrewMembersRows() {
  return crewMembers
      .where((crewMember) => selectedCrewMemberIds.contains(crewMember.id))
      .map((crewMember) {
    Map<String, dynamic>? crewMemberData = crewMember.data() as Map<String, dynamic>?;

    String name = crewMemberData?['name']?.toString() ?? '';
    String phone = crewMemberData?['phone']?.toString() ?? '';
    String email = crewMemberData?['email']?.toString() ?? '';
    double amount = crewAmounts[crewMember.id] ?? 0;

    return DataRow(
      cells: [
        DataCell(
          TextFormField(
            initialValue: name,
            onChanged: (value) {
              setState(() {
                crewMemberData?['name'] = value;
              });
            },
            decoration: InputDecoration(labelText: 'Crew Member Name'),
          ),
        ),
        DataCell(
          TextFormField(
            initialValue: phone,
            onChanged: (value) {
              setState(() {
                crewMemberData?['phone'] = value;
              });
            },
            decoration: InputDecoration(labelText: 'Crew Member Phone'),
          ),
        ),
        DataCell(
          TextFormField(
            initialValue: email,
            onChanged: (value) {
              setState(() {
                crewMemberData?['email'] = value;
              });
            },
            decoration: InputDecoration(labelText: 'Crew Member Email'),
          ),
        ),
        DataCell(
          TextFormField(
            initialValue: '0',  // Set initial value to '0'
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                crewAmounts[crewMember.id] = double.tryParse(value) ?? 0;
              });
            },
            decoration: InputDecoration(labelText: 'Enter Amount'),
          ),
        ),
       
      ],
    );
  }).toList();
}

List<DataRow> _buildOwnersRows() {
  return owners
      .where((owner) => selectedOwnerIds.contains(owner.id))
      .map((owner) {
    Map<String, dynamic>? ownerData = owner.data() as Map<String, dynamic>?;

    double share = ownerShares[owner.id] ?? 0;

    return DataRow(
      cells: [
        DataCell(
          TextFormField(
            initialValue: ownerData?['name']?.toString() ?? '',
            onChanged: (value) {
              setState(() {
                ownerData?['name'] = value;
              });
            },
            decoration: InputDecoration(labelText: 'Owner Name'),
          ),
        ),
        DataCell(
          TextFormField(
            initialValue: ownerData?['phone']?.toString() ?? '',
            onChanged: (value) {
              setState(() {
                ownerData?['phone'] = value;
              });
            },
            decoration: InputDecoration(labelText: 'Owner Phone'),
          ),
        ),
        DataCell(
          TextFormField(
            initialValue: ownerData?['email']?.toString() ?? '',
            onChanged: (value) {
              setState(() {
                ownerData?['email'] = value;
              });
            },
            decoration: InputDecoration(labelText: 'Owner Email'),
          ),
        ),
        DataCell(
          TextFormField(
            initialValue: '0',  // Set initial value to '0'
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                ownerInvestments[owner.id] = double.tryParse(value) ?? 0;
                _calculateShareForOwners();
              });
            },
            decoration: InputDecoration(labelText: 'Enter Invest'),
          ),
        ),
        DataCell(
          TextFormField(
            enabled: false,
            initialValue: '0.0',  // Set initial value to '0.0'
          ),
        ),
       
      ],
    );
  }).toList();
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




  Future<void> _selectCrewMembers(BuildContext context) async {
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
                  future: FirebaseFirestore.instance.collection('crewmembers').get(),
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
  }


 Future<void> _selectOwners(BuildContext context) async {
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
                future: FirebaseFirestore.instance.collection('owners').get(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }

                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }

                  owners = snapshot.data!.docs;

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
}

 Future<void> _addRevenueSubcollection(DocumentReference newEntryDocRef) async {
    CollectionReference revenueCollection = newEntryDocRef.collection('revenue');
    for (var revenueEntry in revenuesList) {
      await revenueCollection.add(revenueEntry);
    }
  }

  Future<void> _addSalaryToCrewMembersSubcollection(DocumentReference newEntryDocRef) async {
    CollectionReference salaryToCrewMembersCollection = newEntryDocRef.collection('salarytocrewmembers');
    for (var crewMemberId in selectedCrewMemberIds) {
      var crewMember = crewMembers.firstWhere((element) => element.id == crewMemberId);
      await salaryToCrewMembersCollection.add({
        'name': crewMember['name'],
        'phone': crewMember['phone'],
        'email' : crewMember['email'],
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
      await ownerShareCollection.add({
        'name': owner['name'],
        'phone': owner['phone'],
        'email': owner['email'],
        'invest': ownerInvestments[ownerId],
        'share': ownerShares[ownerId],
      });
    }
  }

  Future<void> _addNewEntry() async {
    try {
      if (selectedSailingDate != null && selectedReturnDate != null) {
        DocumentReference newEntryDocRef = await newEntryCollection.add({
          'monthconsidered': selectedMonth,
          'sailingdate': selectedSailingDate,
          'returndate': selectedReturnDate,
          'totalprofit': _calculateTotalProfit(),
        });

        await _addRevenueSubcollection(newEntryDocRef);
        await _addSalaryToCrewMembersSubcollection(newEntryDocRef);
        await _addExpenseSubcollection(newEntryDocRef);
        await _addOwnerShareSubcollection(newEntryDocRef);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added to New Entry'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please fill in all date fields.'),
          ),
        );
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

}