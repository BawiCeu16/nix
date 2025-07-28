// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../../providers/user_provider.dart';

// class NameInputScreen extends StatelessWidget {
//   const NameInputScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final TextEditingController nameController = TextEditingController();

//     return Scaffold(
//       body: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Text(
//               "Welcome to Nix!",
//               style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 40),

//             //Email TextField
//             Container(
//               margin: EdgeInsets.symmetric(horizontal: 40),
//               padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 3.0),
//               decoration: BoxDecoration(
//                 color: Theme.of(
//                   context,
//                   // ignore: deprecated_member_use
//                 ).colorScheme.surfaceContainerLow.withOpacity(0.7),
//                 borderRadius: BorderRadius.circular(100.0),
//               ),
//               child: TextField(
//                 controller: nameController,
//                 decoration: InputDecoration(
//                   // prefixIcon: Icon(FlutterRemix.user_line),
//                   border: InputBorder.none, // Removes the underline
//                   hintText: "Enter your name",
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//             FilledButton(
//               onPressed: () {
//                 if (nameController.text.trim().isNotEmpty) {
//                   context.read<UserProvider>().setUsername(
//                     nameController.text.trim(),
//                   );
//                 } else if (nameController.text.trim().isEmpty) {
//                   showDialog(
//                     context: context,
//                     builder: (context) => AlertDialog(
//                       // shape: RoundedRectangleBorder(
//                       //   borderRadius: BorderRadiusGeometry.circular(15),
//                       // ),
//                       title: Text("Please Give Attention!"),
//                       content: RichText(
//                         text: TextSpan(
//                           style: TextStyle(
//                             color: Theme.of(
//                               context,
//                             ).colorScheme.onPrimaryContainer,
//                           ),
//                           text:
//                               'if you do not fill your name,It will automatically set as ',
//                           children: const <TextSpan>[
//                             TextSpan(
//                               text: "User",
//                               style: TextStyle(
//                                 color: Colors.blue,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       actions: [
//                         FilledButton.tonal(
//                           onPressed: () {
//                             Navigator.pop(context);
//                           },
//                           child: Text("Re-write"),
//                         ),
//                         FilledButton(
//                           onPressed: () {
//                             context.read<UserProvider>().setUsername("User");
//                             Navigator.pop(context);
//                           },
//                           child: Text("Skip"),
//                         ),
//                       ],
//                     ),
//                   );
//                 }
//               },
//               child: const Text("Continue"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import 'home_screen.dart';

class NameInputScreen extends StatelessWidget {
  const NameInputScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("What's your name?", style: TextStyle(fontSize: 18)),
              const SizedBox(height: 20),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 40),
                padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 3.0),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                    // ignore: deprecated_member_use
                  ).colorScheme.surfaceContainerLow.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(100.0),
                ),
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    // prefixIcon: Icon(FlutterRemix.user_line),
                    border: InputBorder.none, // Removes the underline
                    hintText: "Enter your name",
                  ),
                ),
              ),

              const SizedBox(height: 20),
              SizedBox(
                height: 45,
                width: MediaQuery.of(context).size.width / 2.4,
                child: FilledButton(
                  onPressed: () async {
                    if (controller.text.trim().isNotEmpty) {
                      await context.read<UserProvider>().saveUsername(
                        controller.text,
                      );
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                      );
                    }
                  },
                  child: const Text("Continue"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
