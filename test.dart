import 'package:flutter/material.dart';

void main() {
  DropdownButton<int>(
    value: 1,
    items: const [],
    onChanged: (v){},
  );
  Radio<int>(
    value: 1,
    groupValue: 1,
    onChanged: (v){},
  );
}