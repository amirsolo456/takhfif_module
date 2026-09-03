import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/document_model.dart';
import '../../data/repositories/document_api_repository.dart';
import '../../data/repositories/customer_repository.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  // This page will be wired to the real documents endpoint in the next commit.
  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: Text('تاریخچه اسناد')),
      );
}
