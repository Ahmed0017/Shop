import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shop/providers/auth.dart';

import './product.dart';
import '../models/http_exception.dart';

class Products with ChangeNotifier {
  List<Product> _items = [];

  String _authToken;
  String _userId;

  void update(Auth auth, List<Product> preProducts) {
    _items = preProducts;
    _authToken = auth.token;
    _userId = auth.userId;
    // notifyListeners();
  }

  List<Product> get items {
    return [..._items];
  }

  List<Product> get favoriteItems {
    return _items.where((prod) => prod.isFavorite).toList();
  }

  Product findById(String id) {
    return _items.firstWhere((prod) => prod.id == id);
  }

  Future<void> fetchAndSetProducts([bool filterByUser = false]) async {
    final filterString =
        filterByUser ? 'orderBy="creatorId"&equalTo="$_userId"' : '';

    var url = Uri.parse(
        'https://flutter-update-95d81-default-rtdb.firebaseio.com/products.json?auth=$_authToken&$filterString');

    try {
      final response = await http.get(url);

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (data == null) return;

      url = Uri.parse(
        'https://flutter-update-95d81-default-rtdb.firebaseio.com/userFavorites/$_userId.json?auth=$_authToken',
      );

      final favoriteResponse = await http.get(url);

      final favoriteData = json.decode(favoriteResponse.body);

      List<Product> loadedProducts = [];
      data.forEach((productId, prod) {
        loadedProducts.add(
          Product(
            id: productId,
            title: prod['title'],
            description: prod['description'],
            price: prod['price'],
            imageUrl: prod['imageUrl'],
            isFavorite: favoriteData == null
                ? false
                : favoriteData[productId]['isFavorite'] ?? false,
          ),
        );
      });

      _items = loadedProducts;
      notifyListeners();
    } catch (err) {
      print('ERRORRRRRR $err');
      throw err;
    }
  }

  Future<void> addProduct(Product product) async {
    final url = Uri.parse(
      'https://flutter-update-95d81-default-rtdb.firebaseio.com/products.json?auth=$_authToken',
    );
    try {
      final response = await http.post(
        url,
        body: json.encode(
          {
            'title': product.title,
            'description': product.description,
            'price': product.price,
            'imageUrl': product.imageUrl,
            'creatorId': _userId
          },
        ),
      );

      final newProduct = Product(
        id: json.decode(response.body)['name'],
        title: product.title,
        description: product.description,
        price: product.price,
        imageUrl: product.imageUrl,
      );

      _items.add(newProduct);
      notifyListeners();
    } catch (err) {
      print('ERRORRRRRR $err');
      throw err;
    }
  }

  Future<void> updateProduct(String id, Product newProduct) async {
    final url = Uri.parse(
      'https://flutter-update-95d81-default-rtdb.firebaseio.com/products/$id.json?auth=$_authToken',
    );

    try {
      await http.patch(url,
          body: json.encode(
            {
              'title': newProduct.title,
              'description': newProduct.description,
              'price': newProduct.price,
              'imageUrl': newProduct.imageUrl,
            },
          ));

      final productIndex =
          _items.indexWhere((prod) => prod.id == newProduct.id);
      _items[productIndex] = newProduct;
      notifyListeners();
    } catch (err) {
      print('ERRORRRRRR $err');
      throw err;
    }
  }

  Future<void> deleteProduct(String productId) async {
    final url = Uri.parse(
      'https://flutter-update-95d81-default-rtdb.firebaseio.com/products/$productId.json?auth=$_authToken',
    );

    try {
      final response = await http.delete(url);

      if (response.statusCode >= 400) throw HttpException('Deleting faild!');

      _items.removeWhere((prod) => prod.id == productId);
      notifyListeners();
    } catch (err) {
      print('ERRORRRRRR $err');
      throw err;
    }
  }
}
