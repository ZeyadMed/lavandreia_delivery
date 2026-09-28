import 'package:flutter/material.dart';
import 'package:lavanderia_delivery/core/common_widget/label.dart';
import 'package:lavanderia_delivery/core/style/app_colors.dart';
import 'package:lavanderia_delivery/core/theme/text_styles.dart';

class RowWidget extends StatelessWidget {
  final String title;
  const RowWidget({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        LocalizedLabel(text: title, style: TextStyles.blackBold20),
        LocalizedLabel(
          text: 'see_all',
          style: TextStyles.darkBold14.copyWith(color: AppColors.primaryColor),
        ),
      ],
    );
  }
}
