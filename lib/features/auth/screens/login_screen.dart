// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:salon_app_view/features/onboarding/screens/onboarding_screen.dart';

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   final _formKey = GlobalKey<FormState>();

//   final TextEditingController _emailcontroller = TextEditingController();
//   // final TextEditingController _phoneController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.deepPurple,
//       body: SafeArea(
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: EdgeInsetsGeometry.symmetric(),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Image.asset("assets/hair2.png", width: 60),
//                     SizedBox(width: 4),
//                     SvgPicture.asset("assets/hair.svg", width: 60),
//                   ],
//                 ),
//                 SizedBox(height: 24),
//                 Stack(
//                   children: [
//                     Image.asset(
//                       "assets/first1.png",
//                       width: double.infinity,

//                       fit: BoxFit.cover,
//                     ),

//                     Positioned(
//                       top: 570,
//                       left: 10,
//                       child: Align(
//                         alignment: Alignment.center,
//                         child: Container(
//                           height: 340,
//                           width: 600,
//                           decoration: BoxDecoration(
//                             color: Colors.black87,
//                             borderRadius: BorderRadius.circular(14),
//                           ),

//                           child: Column(
//                             children: [
//                               const Text(
//                                 "HII",
//                                 style: TextStyle(
//                                   fontSize: 20,
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.white,
//                                 ),
//                               ),

//                               const SizedBox(height: 10),
//                               Form(
//                                 key: _formKey,
//                                 child: CustomTextField(
//                                   controller: _emailcontroller,
//                                   labelText: "Email",
//                                   obscureText: false,
//                                   validator: (value) {
//                                     if (value == null || value.isEmpty) {
//                                       return "Enter email";
//                                     }

//                                     if (!value.contains("@")) {
//                                       return "Enter valid email";
//                                     }

//                                     return null;
//                                   },
//                                 ),
//                               ),
//                               const SizedBox(height: 10),
//                               CustomTextField(
//                                 controller: _passwordController,
//                                 labelText: "Password",
//                                 obscureText: true,
//                                 validator: (value) {
//                                   if (value == null || value.isEmpty) {
//                                     return "Enter Password";
//                                   }
//                                   return null;
//                                 },
//                               ),

//                               const SizedBox(height: 10),
//                               ElevatedButton.icon(
                                
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: Colors.white,
//                                   foregroundColor: Colors.purpleAccent,
//                                   elevation: 8,
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(15),
//                                   ),
//                                 ),

//                                 onPressed: () {},

//                                 icon: Image.asset(
//                                   "assets/google2.png",
//                                   height: 24,
//                                   width: 24,
//                                 ),

//                                 label: const Text(
//                                   "Continue with Google",
//                                   style: TextStyle(
//                                     fontSize: 20,
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                                 ),
//                               ),
//                               Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                  const Text(
//                                     "Already a member?",
//                                     style: TextStyle(color: Colors.white),
//                                   ),
//                                   RichText(
//                                     text:const TextSpan(
//                                       text: 'Login',
//                                       style: TextStyle(color: Colors.purple),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 20),
//                               MyButton(
//                                 name: "Sign Up",
//                                 onTap: () {},
//                                 height: 45,
//                                 width: 170,
//                               ),
                              
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class CustomTextField extends StatelessWidget {
//   const CustomTextField({
//     super.key,
//     required this.labelText,
//     required this.controller,
//     required this.validator,
//     required this.obscureText, required IconData prefixIcon, required String label, required int maxLines, required String hint,
//   });

//   final TextEditingController? controller;
//   final String labelText;
//   final String? Function(String?) validator;
//   final bool obscureText;

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 14),
//       child: TextFormField(
//         obscureText: obscureText,
//         controller: controller,
//         keyboardType: TextInputType.text,

//         style:const TextStyle(color: Colors.white),
//         decoration: InputDecoration(
//           labelText: labelText,
//           border:const OutlineInputBorder(),
//           enabledBorder:cons OutlineInputBorder(
//             borderSide: BorderSide(color: Colors.white),
//           ),
//         ),
//         validator: validator,
//       ),
//     );
//   }
// }
