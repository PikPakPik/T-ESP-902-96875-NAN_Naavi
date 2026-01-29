import 'package:flutter/material.dart';

class RecapHikeBar extends StatelessWidget {
  const RecapHikeBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: Colors.white,
          width: double.infinity,
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(double.infinity)
          ),
        )
      ],
    );
  }
}
