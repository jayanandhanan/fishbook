import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StatementScreen extends StatefulWidget {
  @override
  _StatementScreenState createState() => _StatementScreenState();
}

class _StatementScreenState extends State<StatementScreen> {
  List<DocumentSnapshot> crewMembers = [];
  List<DocumentSnapshot> owners = [];
  Set<String> selectedCrewMemberIds = {};
  Set<String> selectedOwnerIds = {};
  Map<String, double> crewAmounts = {};
  Map<String, double> ownerInvestments = {};
  Map<String, double> ownerShares = {};
  double totalInvest = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Statements'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          ElevatedButton(
            onPressed: () async {
              await _selectCrewMembers(context);
            },
            child: Text('Select Crew Members'),
          ),
               if (selectedCrewMemberIds.isNotEmpty)
            DataTable(
              columns: [
                DataColumn(label: Text('Crew Member Name')),
                DataColumn(label: Text('Crew Member Phone')),
                DataColumn(label: Text('Crew Member Email')),
                DataColumn(label: Text('Amount')),
                DataColumn(label: Text('Edit')),
                DataColumn(label: Text('Delete')),
              ],
              rows: _buildCrewMembersRows(),
            ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              await _selectOwners(context);
            },
            child: Text('Select Owners'),
          ),
          if (selectedOwnerIds.isNotEmpty)
            DataTable(
              columns: [
                DataColumn(label: Text('Owner Name')),
                DataColumn(label: Text('Owner Phone')),
                DataColumn(label: Text('Owner Email')),
                DataColumn(label: Text('Invest')),
                DataColumn(label: Text('Share')),
                DataColumn(label: Text('Edit')),
                DataColumn(label: Text('Delete')),
              ],
              rows: _buildOwnersRows(),
            ),
          SizedBox(height: 20),
          Text('Total Invest: $totalInvest'), // Display the total invest
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Calculate share for each owner based on their individual invest values
              _calculateShareForOwners();
            },
            child: Text('Calculate Share for Owners'),
          ),
        ],
      ),
    );
  }

  List<DataRow> _buildCrewMembersRows() {
    return crewMembers
        .where((crewMember) => selectedCrewMemberIds.contains(crewMember.id))
        .map((crewMember) {
      return DataRow(
        cells: [
          DataCell(Text(crewMember['name']?.toString() ?? '')),
          DataCell(Text(crewMember['phone']?.toString() ?? '')),
          DataCell(Text(crewMember['email']?.toString() ?? '')),
          DataCell(
            TextFormField(
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  crewAmounts[crewMember.id] = double.tryParse(value) ?? 0;
                });
              },
              decoration: InputDecoration(labelText: 'Enter Amount'),
            ),
          ),
          DataCell(
            ElevatedButton(
              onPressed: () {
                _editCrewMember(crewMember);
              },
              child: Text('Edit'),
            ),
          ),
          DataCell(
            ElevatedButton(
              onPressed: () {
                _deleteCrewMember(crewMember);
              },
              child: Text('Delete'),
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
      double share = ownerShares[owner.id] ?? 0;

      return DataRow(
        cells: [
          DataCell(Text(owner['name']?.toString() ?? '')),
          DataCell(Text(owner['phone']?.toString() ?? '')),
          DataCell(Text(owner['email']?.toString() ?? '')),
          DataCell(
            TextFormField(
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  ownerInvestments[owner.id] = double.tryParse(value) ?? 0;
                  totalInvest = _calculateTotalInvest();
                });
              },
              decoration: InputDecoration(labelText: 'Enter Invest'),
            ),
          ),
          DataCell(Text(share.toStringAsFixed(2))),
          DataCell(
            ElevatedButton(
              onPressed: () {
                _editOwner(owner);
              },
              child: Text('Edit'),
            ),
          ),
          DataCell(
            ElevatedButton(
              onPressed: () {
                _deleteOwner(owner);
              },
              child: Text('Delete'),
            ),
          ),
        ],
      );
    }).toList();
  }

  void _calculateShareForOwners() {
    // Calculate share for each owner based on their individual invest values
    for (var owner in owners) {
      if (selectedOwnerIds.contains(owner.id)) {
        double ownerInvest = ownerInvestments[owner.id] ?? 0;
        double share = _calculateShare(ownerInvest, totalInvest);
        // Update the share value in the corresponding cell
        setState(() {
          ownerShares[owner.id] = share;
        });
      }
    }
  }

  double _calculateShare(double invest, double totalInvest) {
    // Calculate and return the share based on the invest amount and totalInvest
    return invest > 0 && totalInvest > 0 ? (invest / totalInvest) * 100 : 0;
  }

  double _calculateTotalInvest() {
    // Calculate and return the total invest across all entered invest values in the table
    double total = 0;
    for (var ownerId in ownerInvestments.keys) {
      if (selectedOwnerIds.contains(ownerId)) {
        total += ownerInvestments[ownerId] ?? 0;
      }
    }
    return total;
  }

void _editOwner(DocumentSnapshot owner) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      String newName = owner['name']?.toString() ?? '';
      String newPhone = owner['phone']?.toString() ?? '';
      String newEmail = owner['email']?.toString() ?? '';
      double newInvestment = ownerInvestments[owner.id] ?? 0;

      return AlertDialog(
        title: Text('Edit Owner'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              initialValue: newName,
              onChanged: (value) {
                newName = value;
              },
              decoration: InputDecoration(labelText: 'Owner Name'),
            ),
            TextFormField(
              initialValue: newPhone,
              onChanged: (value) {
                newPhone = value;
              },
              decoration: InputDecoration(labelText: 'Owner Phone'),
            ),
            TextFormField(
              initialValue: newEmail,
              onChanged: (value) {
                newEmail = value;
              },
              decoration: InputDecoration(labelText: 'Owner Email'),
            ),
            TextFormField(
              initialValue: newInvestment.toString(),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                newInvestment = double.tryParse(value) ?? 0;
              },
              decoration: InputDecoration(labelText: 'Enter Invest'),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                (owner as Map<String, dynamic>)['name'] = newName;
                (owner as Map<String, dynamic>)['phone'] = newPhone;
                (owner as Map<String, dynamic>)['email'] = newEmail;
                ownerInvestments[owner.id] = newInvestment;
              });
            },
            child: Text('Save'),
          ),
        ],
      );
    },
  );
}

void _editCrewMember(DocumentSnapshot crewMember) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      String newName = crewMember['name']?.toString() ?? '';
      String newPhone = crewMember['phone']?.toString() ?? '';
      String newEmail = crewMember['email']?.toString() ?? '';
      double newAmount = crewAmounts[crewMember.id] ?? 0;

      return AlertDialog(
        title: Text('Edit Crew Member'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              initialValue: newName,
              onChanged: (value) {
                newName = value;
              },
              decoration: InputDecoration(labelText: 'Crew Member Name'),
            ),
            TextFormField(
              initialValue: newPhone,
              onChanged: (value) {
                newPhone = value;
              },
              decoration: InputDecoration(labelText: 'Crew Member Phone'),
            ),
            TextFormField(
              initialValue: newEmail,
              onChanged: (value) {
                newEmail = value;
              },
              decoration: InputDecoration(labelText: 'Crew Member Email'),
            ),
            TextFormField(
              initialValue: newAmount.toString(),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                newAmount = double.tryParse(value) ?? 0;
              },
              decoration: InputDecoration(labelText: 'Enter Amount'),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                (crewMember as Map<String, dynamic>)['name'] = newName;
                (crewMember as Map<String, dynamic>)['phone'] = newPhone;
                (crewMember as Map<String, dynamic>)['email'] = newEmail;
                crewAmounts[crewMember.id] = newAmount;
              });
            },
            child: Text('Save'),
          ),
        ],
      );
    },
  );
}

void _deleteOwner(DocumentSnapshot owner) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Delete Owner'),
        content: Text('Are you sure you want to delete this owner?'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                selectedOwnerIds.remove(owner.id);
                owners.remove(owner);
                totalInvest = _calculateTotalInvest();
              });
            },
            child: Text('Delete'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
        ],
      );
    },
  );
}

 
  void _deleteCrewMember(DocumentSnapshot crewMember) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Crew Member'),
          content: Text('Are you sure you want to delete this crew member?'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  selectedCrewMemberIds.remove(crewMember.id);
                  crewMembers.remove(crewMember);
                });
              },
              child: Text('Delete'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
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
}