import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:nix/providers/user_provider.dart';
import 'package:provider/provider.dart';
import '../../providers/music_provider.dart';

class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MusicProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SearchBar(
        elevation: WidgetStateProperty.all(0),
        onChanged: provider.setSearchQuery,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Icon(FlutterRemix.search_line),
        ),
        hintText: 'Search..',
        enabled: provider.songs.isEmpty ? false : true,
        trailing: [
          // if (provider.searchQuery.isNotEmpty)
          //   IconButton(
          //     icon: const Icon(Icons.clear),
          //     onPressed: () {
          //       provider.clearSearch();
          //     },
          //   ),
          Tooltip(
            message: "Sort",
            child: IconButton(
              onPressed: () {
                showModalBottomSheet(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusGeometry.circular(15),
                  ),
                  context: context,
                  builder: (context) {
                    final provider = context.read<MusicProvider>();
                    return SizedBox(
                      width: MediaQuery.of(context).size.width / 1.3,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadiusGeometry.circular(10),
                              ),
                              leading: Icon(FlutterRemix.sort_asc),
                              title: const Text("Title (A-Z)"),
                              trailing:
                                  // Row(
                                  //   mainAxisSize: MainAxisSize.min,
                                  //   children: [
                                  Text("Default"),
                              // SizedBox(width: 5),
                              //    provider. Icon(FlutterRemix.check_fill),
                              //   ],
                              // ),
                              onTap: () {
                                provider.setSortOption(SortOption.titleAsc);
                                Navigator.pop(context);
                              },
                            ),
                            ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadiusGeometry.circular(10),
                              ),
                              leading: Icon(FlutterRemix.sort_desc),
                              title: const Text("Title (Z-A)"),
                              onTap: () {
                                provider.setSortOption(SortOption.titleDesc);
                                Navigator.pop(context);
                              },
                            ),
                            ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadiusGeometry.circular(10),
                              ),

                              leading: Icon(FlutterRemix.user_2_fill),
                              title: const Text("Artist (A-Z)"),
                              onTap: () {
                                provider.setSortOption(SortOption.artistAsc);
                                Navigator.pop(context);
                              },
                            ),
                            ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadiusGeometry.circular(10),
                              ),
                              leading: Icon(FlutterRemix.time_fill),
                              title: const Text("Duration (Shortest First)"),
                              onTap: () {
                                provider.setSortOption(SortOption.durationAsc);
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              icon: Icon(Icons.sort),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(100.0),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) {
                  return Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadiusGeometry.circular(15),
                    ),
                    child: Padding(
                      // padding: const EdgeInsets.all(10.0),
                      padding: const EdgeInsets.only(
                        left: 10.0,
                        top: 20.0,
                        right: 10.0,

                        // bottom: 10.0,
                        bottom: 20.0,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 80.0,
                            width: 80.0,
                            child: Hero(
                              tag: "profile12",
                              child: CircleAvatar(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.onInverseSurface,
                                child: const Icon(
                                  FlutterRemix.user_fill,
                                  size: 45,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            userProvider.username.toString(),
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),

                          // ListTile(
                          //   shape: RoundedRectangleBorder(
                          //     borderRadius: BorderRadiusGeometry.circular(10.0),
                          //   ),
                          //   leading: Icon(Icons.settings),
                          //   title: Text("data"),
                          //   subtitle: Text("data"),
                          //   onTap: () {},
                          // ),
                          // ListTile(
                          //   shape: RoundedRectangleBorder(
                          //     borderRadius: BorderRadiusGeometry.circular(10.0),
                          //   ),
                          //   leading: Icon(Icons.settings),
                          //   title: Text("data"),
                          //   subtitle: Text("data"),
                          //   onTap: () {},
                          // ),
                          // ListTile(
                          //   shape: RoundedRectangleBorder(
                          //     borderRadius: BorderRadiusGeometry.circular(10.0),
                          //   ),
                          //   leading: Icon(Icons.settings),
                          //   title: Text("data"),
                          //   subtitle: Text("data"),
                          //   onTap: () {},
                          // ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            child: Tooltip(
              message: 'UserS',
              child: Hero(
                tag: "profile12",
                child: CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.onInverseSurface,
                  child: const Icon(FlutterRemix.user_fill),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // return Padding(
    //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    //   child: TextField(
    //     onChanged: provider.setSearchQuery,
    //     decoration: InputDecoration(
    //       hintText: 'Search songs...',
    //       prefixIcon: const Icon(Icons.search),
    //       suffixIcon: provider.searchQuery.isNotEmpty
    //           ? IconButton(
    //               icon: const Icon(Icons.clear),
    //               onPressed: provider.clearSearch,
    //             )
    //           : null,
    //       filled: true,
    //       fillColor: Colors.grey[800],
    //       border: OutlineInputBorder(
    //         borderRadius: BorderRadius.circular(12),
    //         borderSide: BorderSide.none,
    //       ),
    //     ),
    //     style: const TextStyle(color: Colors.white),
    //   ),
    // );
  }
}
