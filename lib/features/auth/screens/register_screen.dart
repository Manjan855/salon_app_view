// import 'package:flutter/material.dart';
// import 'package:salon_app_view/features/auth/screens/login_screen.dart';

// class RegisterScreen extends StatefulWidget {
//   const RegisterScreen({super.key});

//   @override
//   State<RegisterScreen> createState() => _RegisterScreenState();
// }

// class _RegisterScreenState extends State<RegisterScreen> {
//   final TextEditingController _emailcontroller = TextEditingController();
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(),
//       body: Column(
//         children: [
//           CustomTextField(
//             labelText: "Name",
//             controller: _emailcontroller,
//             validator: (value) {
//               if (value == null || value.isEmpty) {
//                 return 'Enter the name';
//               }
//               return null;
//             },
//             obscureText: false,
//           ),
//         ],
//       ),
//     );
//   }
// }
