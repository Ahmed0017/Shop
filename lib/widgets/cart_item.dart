import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart.dart';

class CartItem extends StatelessWidget {
  final String id;
  final String productId;
  final String title;
  final double price;
  final int quantity;

  const CartItem({
    @required this.id,
    @required this.productId,
    @required this.title,
    @required this.price,
    @required this.quantity,
  });

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<Cart>(context, listen: false);

    return Dismissible(
      key: ValueKey(id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        cart.removeItem(productId);
      },
      confirmDismiss: (direction) {
        return showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Are you sure?'),
            content: Text('Do you want to remove the item from the cart?'),
            actions: [
              TextButton(
                child: Text('No'),
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
              TextButton(
                child: Text('Yes'),
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
            ],
          ),
        );
      },
      background: Container(
        padding: EdgeInsets.only(right: 20),
        margin: EdgeInsets.all(15),
        color: Theme.of(context).errorColor,
        alignment: Alignment.centerRight,
        child: Icon(
          Icons.delete,
          size: 40,
          color: Colors.white,
        ),
      ),
      child: Card(
        margin: EdgeInsets.all(15),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 25, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: FittedBox(child: Text('\$$price')),
              ),
            ),
            title: Text(title),
            subtitle: Text('${(price * quantity)}'),
            trailing: Text('$quantity x'),
          ),
        ),
      ),
    );
  }
}
