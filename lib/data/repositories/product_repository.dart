import 'package:dio/dio.dart';
import '../models/product_model.dart';

abstract class ProductRepository {
  Future<List<ProductModel>> getProducts();
  Future<ProductModel> getProduct(String id);
}

class ProductRepositoryImpl implements ProductRepository {
  final Dio dio;

  ProductRepositoryImpl(this.dio);

  @override
  Future<List<ProductModel>> getProducts() async {
    final response = await dio.get('/Products');
    return (response.data as List)
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ProductModel> getProduct(String id) async {
    final response = await dio.get('/Products/$id');
    return ProductModel.fromJson(response.data);
  }
}
