import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/product.dart';
import '../providers/products.dart';

class EditProductScreen extends StatefulWidget {
  static const routeName = '/edit-product';
  @override
  _EditProductScreenState createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  String _imageUrl;
  final _form = GlobalKey<FormState>();

  var _editedProduct = Product(
    id: null,
    title: '',
    description: '',
    price: 0.0,
    imageUrl: '',
  );

  var _initValues = {
    'title': '',
    'description': '',
    'price': '',
    'imageUrl': ''
  };

  var _isInit = true;
  var _isLoading = false;

  @override
  void didChangeDependencies() {
    if (_isInit) {
      final productId = ModalRoute.of(context).settings.arguments as String;

      if (productId != null) {
        _editedProduct = Provider.of<Products>(context).findById(productId);
        _initValues = {
          'title': _editedProduct.title,
          'description': _editedProduct.description,
          'price': _editedProduct.price.toString(),
          'imageUrl': _editedProduct.imageUrl,
        };
      }
      _isInit = false;
    }
    super.didChangeDependencies();
  }

  Future<void> _saveForm() async {
    final isValid = _form.currentState.validate();

    if (!isValid) return;

    _form.currentState.save();

    setState(() {
      _isLoading = true;
    });

    try {
      if (_editedProduct.id == null) {
        await Provider.of<Products>(context, listen: false)
            .addProduct(_editedProduct);
      } else {
        await Provider.of<Products>(context, listen: false)
            .updateProduct(_editedProduct.id, _editedProduct);
      }
    } catch (err) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('An error occurred!'),
          content: Text('Something went wrong'),
          actions: [
            TextButton(
              child: Text('Okay'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      );
    }

    // setState(() {
    //   _isLoading = false;
    // });

    Navigator.of(context).pop();
  }

  bool _setImageUrl() {
    if (_initValues['imageUrl'].isNotEmpty) {
      _imageUrl = _initValues['imageUrl'];
      return true;
    }
    if (_imageUrl == null) return false;
    if (!_imageUrl.startsWith('http') && !_imageUrl.startsWith('https'))
      return false;
    if (!_imageUrl.endsWith('.png') &&
        !_imageUrl.endsWith('.jpg') &&
        !_imageUrl.endsWith('.jpeg')) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit product'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveForm,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Padding(
              padding: const EdgeInsets.all(10),
              child: Form(
                key: _form,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextFormField(
                        initialValue: _initValues['title'],
                        decoration: InputDecoration(labelText: 'Title'),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value.isEmpty) return 'Please enter a title.';
                          return null;
                        },
                        onSaved: (value) {
                          _editedProduct = Product(
                            id: _editedProduct.id,
                            isFavorite: _editedProduct.isFavorite,
                            title: value,
                            description: _editedProduct.description,
                            price: _editedProduct.price,
                            imageUrl: _editedProduct.imageUrl,
                          );
                        },
                      ),
                      TextFormField(
                        initialValue: _initValues['price'],
                        decoration: InputDecoration(labelText: 'Price'),
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value.isEmpty) return 'Please enter a price.';
                          if (double.tryParse(value) == null)
                            return 'Please enter a valid number.';
                          if (double.parse(value) <= 0)
                            return 'Please enter a number greater than zero.';
                          return null;
                        },
                        onSaved: (value) {
                          _editedProduct = Product(
                            id: _editedProduct.id,
                            isFavorite: _editedProduct.isFavorite,
                            title: _editedProduct.title,
                            description: _editedProduct.description,
                            price: double.parse(value),
                            imageUrl: _editedProduct.imageUrl,
                          );
                        },
                      ),
                      TextFormField(
                        initialValue: _initValues['description'],
                        decoration: InputDecoration(labelText: 'Descriptiopn'),
                        maxLines: 3,
                        keyboardType: TextInputType.multiline,
                        validator: (value) {
                          if (value.isEmpty)
                            return 'Please enter a description.';
                          if (value.length < 10)
                            return 'Should be at least 10 characters long.';
                          return null;
                        },
                        onSaved: (value) {
                          _editedProduct = Product(
                            id: _editedProduct.id,
                            isFavorite: _editedProduct.isFavorite,
                            title: _editedProduct.title,
                            description: value,
                            price: _editedProduct.price,
                            imageUrl: _editedProduct.imageUrl,
                          );
                        },
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            margin: EdgeInsets.only(top: 8, right: 10),
                            height: 100,
                            width: 100,
                            decoration: BoxDecoration(
                              border: Border.all(
                                width: 1,
                                color: Colors.grey,
                              ),
                            ),
                            child: _setImageUrl()
                                ? Image.network(
                                    _imageUrl,
                                    fit: BoxFit.cover,
                                  )
                                : Text('Enter a URL'),
                          ),
                          Expanded(
                            child: TextFormField(
                              initialValue: _initValues['imageUrl'],
                              decoration:
                                  InputDecoration(labelText: 'Image Url'),
                              onFieldSubmitted: (_) => _saveForm(),
                              keyboardType: TextInputType.url,
                              onChanged: (val) {
                                setState(() {
                                  _imageUrl = val;
                                });
                              },
                              validator: (value) {
                                if (value.isEmpty)
                                  return 'Please enter an image URL.';
                                if (!value.startsWith('http') &&
                                    !value.startsWith('https'))
                                  return 'Please enter a valid image URL.';
                                if (!value.endsWith('.png') &&
                                    !value.endsWith('.jpg') &&
                                    !value.endsWith('.jpeg'))
                                  return 'Please enter a valid image URL.';
                                return null;
                              },
                              onSaved: (value) {
                                _editedProduct = Product(
                                  id: _editedProduct.id,
                                  isFavorite: _editedProduct.isFavorite,
                                  title: _editedProduct.title,
                                  description: _editedProduct.description,
                                  price: _editedProduct.price,
                                  imageUrl: value,
                                );
                              },
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
