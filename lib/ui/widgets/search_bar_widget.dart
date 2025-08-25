import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:nix/%20utils/translator.dart';
import 'package:nix/providers/user_provider.dart';
import 'package:nix/ui/pages/settings_page.dart';
import 'package:page_animation_transition/animations/right_to_left_transition.dart';
import 'package:page_animation_transition/page_animation_transition.dart';
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
        hintText: '${t(context, 'search_hint')}',
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
            message: "${t(context, 'sort')}",
            child: IconButton(
              onPressed: () {
                showModalBottomSheet(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusGeometry.circular(15),
                  ),
                  context: context,
                  builder: (context) {
                    final provider = context.read<MusicProvider>();
                    return SafeArea(
                      bottom: true,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width / 1.3,
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadiusGeometry.circular(
                                    10,
                                  ),
                                ),
                                leading: Icon(FlutterRemix.sort_asc),
                                title: Text(t(context, 'title_az_sort')),
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
                                  borderRadius: BorderRadiusGeometry.circular(
                                    10,
                                  ),
                                ),
                                leading: Icon(FlutterRemix.sort_desc),
                                title: Text(t(context, 'title_za_sort')),
                                onTap: () {
                                  provider.setSortOption(SortOption.titleDesc);
                                  Navigator.pop(context);
                                },
                              ),
                              ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadiusGeometry.circular(
                                    10,
                                  ),
                                ),

                                leading: Icon(FlutterRemix.user_2_fill),
                                title: Text(t(context, 'artist_sort')),
                                onTap: () {
                                  provider.setSortOption(SortOption.artistAsc);
                                  Navigator.pop(context);
                                },
                              ),
                              ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadiusGeometry.circular(
                                    10,
                                  ),
                                ),
                                leading: Icon(FlutterRemix.time_fill),
                                title: Text(t(context, 'duration_sort')),
                                onTap: () {
                                  provider.setSortOption(
                                    SortOption.durationAsc,
                                  );
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              icon: Icon(Icons.sort),
            ),
          ),
          //Profile Avartar
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
                        bottom: 10.0,
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
                                child: Icon(FlutterRemix.user_fill, size: 45),
                              ),
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            userProvider.username.toString(),
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),

                          SizedBox(height: 10),
                          //Setting Page
                          ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadiusGeometry.circular(10.0),
                            ),
                            leading: Icon(Icons.settings),
                            title: Text(t(context, 'settings')),
                            // subtitle: Text(""),
                            trailing: Icon(FlutterRemix.arrow_right_s_line),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SettingsPage(),
                                ),
                              );
                            },
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
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            child: Tooltip(
              message: '${t(context, 'user')}',
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
