import 'package:dio/dio.dart';
import '../models/customer_model.dart';

abstract class CustomerRepository {
  Future<CustomerModel> getCustomerByMobile(String mobile);
  Future<CustomerModel> createCustomer(CustomerModel customer);
}

class CustomerRepositoryImpl implements CustomerRepository {
  final Dio dio;

  CustomerRepositoryImpl(this.dio);

  @override
  Future<CustomerModel> getCustomerByMobile(String mobile) async {
    final response = await dio.get('/Customers/by-mobile/$mobile');
    return CustomerModel.fromJson(response.data);
  }

  @override
  Future<CustomerModel> createCustomer(CustomerModel customer) async {
    final response = await dio.post('/Customers', data: customer.toJson());
    return CustomerModel.fromJson(response.data);
  }
}
