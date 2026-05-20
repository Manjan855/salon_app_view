// import 'package:flutter/material.dart';
// import 'package:salon_app_view/core/constants/app_colors.dart';
// import 'package:salon_app_view/core/constants/app_dimension.dart';


// class CustomTextField extends StatelessWidget {
//   final TextEditingController controller;
//   final String label;
//   final String hint;
//   final IconData? prefixIcon;
//   final Widget? suffixIcon;
//   final bool obscureText;
//   final TextInputType keyboardType;
//   final String? Function(String?)? validator;
//   final bool readOnly;
//   final VoidCallback? onTap;

//   const CustomTextField({
//     super.key,
//     required this.controller,
//     required this.label,
//     required this.hint,
//     this.prefixIcon,
//     this.suffixIcon,
//     this.obscureText = false,
//     this.keyboardType = TextInputType.text,
//     this.validator,
//     this.readOnly = false,
//     this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.w500,
//             color: AppColors.textPrimary,
//           ),
//         ),
//         const SizedBox(height: 8),
//         TextFormField(
//           controller: controller,
//           obscureText: obscureText,
//           keyboardType: keyboardType,
//           readOnly: readOnly,
//           onTap: onTap,
//           decoration: InputDecoration(
//             hintText: hint,
//             prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
//             suffixIcon: suffixIcon,
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(AppDimensions.radiusM),
//               borderSide: const BorderSide(color: AppColors.border),
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(AppDimensions.radiusM),
//               borderSide: const BorderSide(color: AppColors.border),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(AppDimensions.radiusM),
//               borderSide: const BorderSide(color: AppColors.primary, width: 2),
//             ),
//             errorBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(AppDimensions.radiusM),
//               borderSide: const BorderSide(color: AppColors.error),
//             ),
//             contentPadding: const EdgeInsets.symmetric(
//               horizontal: AppDimensions.paddingL,
//               vertical: AppDimensions.paddingM,
//             ),
//           ),
//           validator: validator,
//         ),
//       ],
//     );
//   }
// }
