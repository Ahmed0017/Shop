import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/http_exception.dart';

class Product with ChangeNotifier {
  final String id;
  final String title;
  final String description;
  final double price;
  final String imageUrl;
  bool isFavorite;

  Product({
    @required this.id,
    @required this.title,
    @required this.description,
    @required this.price,
    @required this.imageUrl,
    this.isFavorite = false,
  });

  void setFavValue(newValue) {
    isFavorite = newValue;
    notifyListeners();
  }

  Future<void> toggleFavoriteStatus(String token, String userId) async {
    final oldStatus = isFavorite;

    isFavorite = !isFavorite;
    notifyListeners();

    final url = Uri.parse(
      'https://flutter-update-95d81-default-rtdb.firebaseio.com/userFavorites/$userId/$id.json?auth=$token',
    );

    try {
      final response = await http.put(
        url,
        body: json.encode({
          'isFavorite': isFavorite,
        }),
      );
      if (response.statusCode >= 400) {
        setFavValue(oldStatus);
        throw HttpException('An error occurred!');
      }
    } catch (err) {
      setFavValue(oldStatus);
      print('ERRORRRRRR $err');
      throw err;
    }
  }
}
