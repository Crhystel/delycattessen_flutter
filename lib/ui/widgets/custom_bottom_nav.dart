import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CustomBottomNav extends StatelessWidget {
  const CustomBottomNav({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: AppColors.primaryOrange,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.home_outlined, color: AppColors.white, size: 32),
            onPressed: () {
              // TODO: Navigate home
            },
          ),
          IconButton(
            icon: const Icon(Icons.restaurant, color: AppColors.white, size: 32),
            onPressed: () {
              // TODO: Navigate menu
            },
          ),
        ],
      ),
    );
  }
}
