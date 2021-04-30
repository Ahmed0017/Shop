import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import './cart.dart';
import '../models/http_exception.dart';
import '../providers/auth.dart';

class OrderItem {
  final String id;
  final double amount;
  final List<CartItem> products;
  final DateTime dateTime;

  OrderItem({
    @required this.id,
    @required this.amount,
    @required this.products,
    @required this.dateTime,
  });
}

class Orders with ChangeNotifier {
  List<OrderItem> _items = [];

  List<OrderItem> get items {
    return [..._items];
  }

  String _authToken;
  String _userId;

  void update(Auth auth, List<OrderItem> preOrders) {
    _items = preOrders;
    _authToken = auth.token;
    _userId = auth.userId;
    // notifyListeners();
  }

  Future<void> fetchAndSetOrders() async {
    final url = Uri.parse(
      'https://flutter-update-95d81-default-rtdb.firebaseio.com/orders.json?auth=$_authToken&orderBy="creatorId"&equalTo="$_userId"',
    );

    try {
      final response = await http.get(url);

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (data == null) return;


      List<OrderItem> loadedOrders = [];

      data.forEach((orderId, order) {
        loadedOrders.add(
          OrderItem(
            id: orderId,
            amount: order['amount'],
            dateTime: DateTime.parse(order['dateTime']),
            products: (order['products'] as List<dynamic>)
                .map(
                  (cartItem) => CartItem(
                    id: cartItem['id'],
                    title: cartItem['title'],
                    price: cartItem['price'],
                    quantity: cartItem['quantity'],
                  ),
                )
                .toList(),
          ),
        );
      });

      _items = loadedOrders.reversed.toList();
      notifyListeners();
    } catch (err) {
      print('ERRORRRRRR $err');
      throw err;
    }
  }

  Future<void> addOrder(List<CartItem> cartProducts, double total) async {
    final url = Uri.parse(
      'https://flutter-update-95d81-default-rtdb.firebaseio.com/orders.json?auth=$_authToken',
    );

    final timestamp = DateTime.now();

    try {
      final response = await http.post(
        url,
        body: json.encode({
          'creatorId': _userId,
          'amount': total,
          'dateTime': timestamp.toIso8601String(),
          'products': cartProducts
              .map(
                (cartItem) => {
                  'id': cartItem.id,
                  'title': cartItem.title,
                  'price': cartItem.price,
                  'quantity': cartItem.quantity,
                },
              )
              .toList()
        }),
      );

      if (response.statusCode >= 400) throw HttpException('Added order faild!');

      _items.insert(
        0,
        OrderItem(
          id: json.decode(response.body)['name'],
          amount: total,
          products: cartProducts,
          dateTime: timestamp,
        ),
      );

      notifyListeners();
    } catch (err) {
      print('ERRORRRRRR $err');
      throw err;
    }
  }
}
