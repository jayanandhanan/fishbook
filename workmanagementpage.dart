import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class WorkManagementPage extends StatefulWidget {
  @override
  _WorkManagementPageState createState() => _WorkManagementPageState();
}

class _WorkManagementPageState extends State<WorkManagementPage> {
  final CollectionReference workManagementCollection =
      FirebaseFirestore.instance.collection('workmanagement');

  TextEditingController dateController = TextEditingController();
  TextEditingController workController = TextEditingController();
  TextEditingController amountController = TextEditingController();
  TextEditingController paymentController = TextEditingController();
  TextEditingController progressController = TextEditingController();
  TextEditingController inchargeController = TextEditingController();
  TextEditingController filterValueController = TextEditingController();

  bool isEditing = false;
  String? editingWorkId;
  List<String> selectedRows = [];
  String? selectedColumn;
  late List<DocumentSnapshot> workItems;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Work Management'),
      ),
      body: Column(
        children: [
          _buildFilterRow(),
          _buildWorkTable(),
          _buildAddOrUpdateWorkRow(),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          DropdownButton<String>(
            value: selectedColumn,
            hint: Text('Select Column'),
            onChanged: (value) {
              setState(() {
                selectedColumn = value;
              });
            },
            items: [
              'Date',
              'Work',
              'Amount',
              'Payment',
              'Progress',
              'Incharge',
            ].map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          SizedBox(width: 16),
          Flexible(
            child: TextField(
              controller: filterValueController,
              decoration: InputDecoration(labelText: 'Filter Value'),
            ),
          ),
          SizedBox(width: 16),
          ElevatedButton(
            onPressed: () {
              _filterTable(selectedColumn, filterValueController.text);
            },
            child: Text('Filter'),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkTable() {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: workManagementCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState != ConnectionState.active) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          workItems = snapshot.data?.docs ?? [];

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              showCheckboxColumn: false,
              columns: _buildTableColumns(),
              rows: _buildTableRows(workItems),
            ),
          );
        },
      ),
    );
  }

  List<DataColumn> _buildTableColumns() {
    return [
      DataColumn(label: Text('Date')),
      DataColumn(label: Text('Work')),
      DataColumn(label: Text('Amount')),
      DataColumn(label: Text('Payment')),
      DataColumn(label: Text('Progress')),
      DataColumn(label: Text('Incharge')),
      DataColumn(label: Text('Actions')),
    ];
  }

  List<DataRow> _buildTableRows(List<DocumentSnapshot> workItems) {
    return workItems.map((workItem) {
      DateTime date = (workItem['date'] as Timestamp).toDate();

      return DataRow(
        selected: selectedRows.contains(workItem.id),
        onSelectChanged: (selected) {
          if (selected != null) {
            setState(() {
              if (selected) {
                selectedRows.add(workItem.id);
              } else {
                selectedRows.remove(workItem.id);
              }
            });
          }
        },
        cells: [
          DataCell(Text(DateFormat('dd-MM-yyyy').format(date))),
          DataCell(
            isEditing && editingWorkId == workItem.id
                ? TextField(
                    controller: workController,
                    onChanged: (value) {
                      workController.text = value;
                    },
                  )
                : Text(workItem['work'].toString()),
          ),
          DataCell(
            isEditing && editingWorkId == workItem.id
                ? TextField(
                    controller: amountController,
                    onChanged: (value) {
                      amountController.text = value;
                    },
                  )
                : Text(workItem['amount'].toString()),
          ),
          DataCell(
            isEditing && editingWorkId == workItem.id
                ? TextField(
                    controller: paymentController,
                    onChanged: (value) {
                      paymentController.text = value;
                    },
                  )
                : Text(workItem['payment'].toString()),
          ),
          DataCell(
            isEditing && editingWorkId == workItem.id
                ? TextField(
                    controller: progressController,
                    onChanged: (value) {
                      progressController.text = value;
                    },
                  )
                : Text(workItem['progress'].toString()),
          ),
          DataCell(
            isEditing && editingWorkId == workItem.id
                ? TextField(
                    controller: inchargeController,
                    onChanged: (value) {
                      inchargeController.text = value;
                    },
                  )
                : Text(workItem['incharge'].toString()),
          ),
          DataCell(
            Row(
              children: [
                isEditing && editingWorkId == workItem.id
                    ? IconButton(
                        icon: Icon(Icons.check),
                        onPressed: () {
                          updateWork(workItem.id);
                        },
                      )
                    : IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          editWork(workItem);
                        },
                      ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    deleteWork(workItem);
                  },
                ),
              ],
            ),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildAddOrUpdateWorkRow() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Flexible(
            child: TextField(
              controller: dateController,
              decoration: InputDecoration(labelText: 'Date'),
            ),
          ),
          Flexible(
            child: TextField(
              controller: workController,
              decoration: InputDecoration(labelText: 'Work'),
            ),
          ),
          Flexible(
            child: TextField(
              controller: amountController,
              decoration: InputDecoration(labelText: 'Amount'),
            ),
          ),
          Flexible(
            child: TextField(
              controller: paymentController,
              decoration: InputDecoration(labelText: 'Payment'),
            ),
          ),
          Flexible(
            child: TextField(
              controller: progressController,
              decoration: InputDecoration(labelText: 'Progress'),
            ),
          ),
          Flexible(
            child: TextField(
              controller: inchargeController,
              decoration: InputDecoration(labelText: 'Incharge'),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (isEditing) {
                updateWork(editingWorkId);
              } else {
                addWork();
              }
            },
            child: Text(isEditing ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

void _filterTable(String? selectedColumn, String? filterValue) {
  // Your filtering logic goes here based on the selectedColumn and filterValue
  // For simplicity, let's assume 'workItems' is a List<DocumentSnapshot> and filteredList is the result after filtering
  List<DocumentSnapshot> filteredList = workItems.where((workItem) {
    String columnValue = workItem[selectedColumn!].toString().toLowerCase();

    String formattedFilterValue = selectedColumn == 'Date'
        ? DateFormat('yyyy-MM-dd').format(DateFormat('dd-MM-yyyy').parse(filterValue!))
        : filterValue!.toLowerCase();

    return columnValue.contains(formattedFilterValue);
  }).toList();

  // Now update the state with the filtered list
  setState(() {
    workItems = filteredList;
  });
}


 void addWork() async {
  String enteredDate = dateController.text.trim();
  String work = workController.text.trim();
  String amount = amountController.text.trim();
  String payment = paymentController.text.trim();
  String progress = progressController.text.trim();
  String incharge = inchargeController.text.trim();

  DateTime parsedDate = DateFormat('dd-MM-yyyy').parse(enteredDate);
  Timestamp dateTimestamp = Timestamp.fromDate(parsedDate);

  await workManagementCollection.add({
    'date': dateTimestamp,
    'work': work,
    'amount': amount,
    'payment': payment,
    'progress': progress,
    'incharge': incharge,
  });

  setState(() {
    isEditing = false;
    editingWorkId = null;
    dateController.clear();
    workController.clear();
    amountController.clear();
    paymentController.clear();
    progressController.clear();
    inchargeController.clear();
    selectedRows.clear();
  });
}
  void updateWork(String? workId) async {
    if (workId != null) {
      String date = dateController.text.trim();
      String work = workController.text.trim();
      String amount = amountController.text.trim();
      String payment = paymentController.text.trim();
      String progress = progressController.text.trim();
      String incharge = inchargeController.text.trim();

      DateTime parsedDate = DateFormat('yyyy-MM-dd').parse(date);
      Timestamp dateTimestamp = Timestamp.fromDate(parsedDate);

      await workManagementCollection.doc(workId).update({
        'date': dateTimestamp,
        'work': work,
        'amount': amount,
        'payment': payment,
        'progress': progress,
        'incharge': incharge,
      });

      setState(() {
        isEditing = false;
        editingWorkId = null;
        dateController.clear();
        workController.clear();
        amountController.clear();
        paymentController.clear();
        progressController.clear();
        inchargeController.clear();
        selectedRows.clear();
      });
    }
  }

  void editWork(DocumentSnapshot workItem) {
    DateTime date = (workItem['date'] as Timestamp).toDate();

    setState(() {
      isEditing = true;
      editingWorkId = workItem.id;
      dateController.text = DateFormat('dd-MM-yyyy').format(date);
      workController.text = workItem['work'].toString();
      amountController.text = workItem['amount'].toString();
      paymentController.text = workItem['payment'].toString();
      progressController.text = workItem['progress'].toString();
      inchargeController.text = workItem['incharge'].toString();
      selectedRows.clear();
      selectedRows.add(workItem.id);
    });
  }

  void deleteWork(DocumentSnapshot workItem) async {
    await workManagementCollection.doc(workItem.id).delete();
    setState(() {
      selectedRows.remove(workItem.id);
    });
  }
}
