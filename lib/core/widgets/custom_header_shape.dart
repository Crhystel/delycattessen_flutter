import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CustomHeaderShape extends StatelessWidget {
  final double height;

  const CustomHeaderShape({Key? key, this.height = 100}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -20,
            child: Container(
              width: 150,
              height: 150,
              decoration: const BoxDecoration(
                color: AppColors.teal500,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: -60,
            right: 40,
            child: Container(
              width: 130,
              height: 130,
              decoration: const BoxDecoration(
                color: AppColors.brand500,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
