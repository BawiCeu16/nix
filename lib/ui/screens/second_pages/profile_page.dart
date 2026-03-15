import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isEditing = false;
  late TextEditingController _nameController;

  // Dummy data
  final List<String> _dummyTopTracks = [
    "Dernière Danse",
    "Starboy",
    "Blinding Lights",
    "Shape of You",
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: "Nix User");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? FlutterRemix.check_line : FlutterRemix.pencil_line,
            ),
            onPressed: () => setState(() => _isEditing = !_isEditing),
          ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 60,
                  child: const Icon(FlutterRemix.user_3_line, size: 50),
                ),
                const SizedBox(height: 16),
                _isEditing
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: TextField(
                          controller: _nameController,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(100),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      )
                    : Text(
                        _nameController.text,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'TOP LISTENED',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 8),

          ..._dummyTopTracks.map((track) {
            return ListTile(
              leading: const Icon(FlutterRemix.music_2_line),
              title: Text(track),
              subtitle: const Text("Dummy Artist"),
              trailing: const Icon(FlutterRemix.arrow_right_s_line),
            );
          }),
        ],
      ),
    );
  }
}
