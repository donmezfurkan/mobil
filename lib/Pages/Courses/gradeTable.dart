import 'package:flutter/material.dart';

class GradeTable extends StatelessWidget {
  final List<dynamic> data;

  GradeTable({required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Grade Table'),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: DataTable(
            columns: _createColumns(),
            rows: _createRows(),
          ),
        ),
      ),
    );
  }

  List<DataColumn> _createColumns() {
    return [
      DataColumn(label: Text('Student Number')),
      DataColumn(label: Text('Q1')),
      DataColumn(label: Text('Q2')),
      DataColumn(label: Text('Q3')),
      DataColumn(label: Text('Q4')),
      DataColumn(label: Text('Q5')),
      DataColumn(label: Text('Total')),
    ];
  }

  List<DataRow> _createRows() {
    // Assuming the data structure is [studentNumber, [questions], [grades], totalScore]
    List<DataRow> rows = [];

    if (data.isNotEmpty && data.length == 4) {
      String studentNumber = data[0] ?? '';
      List<String> questions = data[1] ?? [];
      List<String> grades = data[2] ?? [];
      String totalScore = data[3] ?? '';

      List<DataCell> cells = [
        DataCell(Text(studentNumber)),
        DataCell(Text(questions.isNotEmpty ? questions[0] : '')),
        DataCell(Text(questions.length > 1 ? questions[1] : '')),
        DataCell(Text(questions.length > 2 ? questions[2] : '')),
        DataCell(Text(questions.length > 3 ? questions[3] : '')),
        DataCell(Text(questions.length > 4 ? questions[4] : '')),
        DataCell(Text(totalScore)),
      ];

      rows.add(DataRow(cells: cells));
    }

    return rows;
  }
}

void main() {
  runApp(MaterialApp(
    home: GradeTable(
      data: const [
        'Student123', // Example student number
        ['Q1', 'Q2', 'Q3', 'Q4', 'Q5'], // Example questions
        ['85', '90', '78', '88', '92'], // Example grades
        '433', // Example total score
      ],
    ),
  ));
}
