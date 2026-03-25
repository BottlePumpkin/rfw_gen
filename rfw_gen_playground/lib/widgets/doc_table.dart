import 'package:flutter/material.dart';

class DocTable extends StatelessWidget {
  const DocTable({super.key, required this.headers, required this.rows});

  final List<String> headers;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE8EBED)),
        borderRadius: BorderRadius.circular(8.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildRow(headers, isHeader: true),
          for (var i = 0; i < rows.length; i++)
            _buildRow(rows[i], isEven: i.isEven),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> cells, {bool isHeader = false, bool isEven = true}) {
    return Container(
      color: isHeader
          ? const Color(0xFFF5F6F8)
          : isEven ? Colors.white : const Color(0xFFFAFBFC),
      child: Row(
        children: cells.map((cell) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
            child: Text(cell, style: TextStyle(
              fontSize: 13.0,
              fontWeight: isHeader ? FontWeight.w600 : FontWeight.normal,
              color: const Color(0xFF49515A),
            )),
          ),
        )).toList(),
      ),
    );
  }
}
