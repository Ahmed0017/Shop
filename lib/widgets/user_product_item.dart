import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/edit_product_screen.dart';
import '../providers/products.dart';

class UserProductItem extends StatefulWidget {
  final String id;
  final String title;
  final String imageUrl;

  UserProductItem({
    Key key,
    @required this.id,
    @required this.title,
    @required this.imageUrl,
  }) : super(key: key);

  @override
  _UserProductItemState createState() => _UserProductItemState();
}

class _UserProductItemState extends State<UserProductItem> {
  var _isLoading = false;

  Future<void> _deleteItem() async {
    final value = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Are you sure?'),
        content: Text('Do you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(false);
            },
            child: Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(true);
            },
            child: Text('Yes'),
          ),
        ],
      ),
    );

    if (value)
      try {
        setState(() {
          _isLoading = true;
        });

        await Provider.of<Products>(context, listen: false)
            .deleteProduct(widget.id);
      } catch (err) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Deleting faild!',
              textAlign: TextAlign.center,
            ),
          ),
        );
        // await showDialog(
        //   context: context,
        //   builder: (ctx) => AlertDialog(
        //     title: Text('An error occurred!'),
        //     content: Text('Something went wrong'),
        //     actions: [
        //       TextButton(
        //         child: Text('Okay'),
        //         onPressed: () => Navigator.of(ctx).pop(),
        //       ),
        //     ],
        //   ),
        // );
      }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(widget.imageUrl),
          ),
          title: Text(widget.title),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  Icons.edit,
                  color: Theme.of(context).primaryColor,
                ),
                onPressed: () {
                  Navigator.of(context).pushNamed(EditProductScreen.routeName,
                      arguments: widget.id);
                },
              ),
              _isLoading
                  ? CircularProgressIndicator()
                  : IconButton(
                      icon: Icon(
                        Icons.delete,
                        color: Theme.of(context).errorColor,
                      ),
                      onPressed: _deleteItem,
                    ),
            ],
          ),
        ),
        Divider()
      ],
    );
  }
}
