// ignore_for_file: use_build_context_synchronously

import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:flutter_project_1/introduction_page.dart';
import 'package:flutter_project_1/posts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'login.dart';
import 'profile.dart';
import 'map.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  bool firstTime = prefs.getBool('firstTime') ?? true;
  runApp(MyApp(isLoggedIn: isLoggedIn, firstTime: firstTime));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final bool firstTime;

  MyApp({required this.isLoggedIn, required this.firstTime});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        ),
        home: firstTime
            ? IntroductionPage(isLoggedIn: isLoggedIn)
            : LoginPage(isLoggedIn: isLoggedIn),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();

  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }

  var favorites = <WordPair>[];

  void toggleFavorite() {
    if (favorites.contains(current)) {
      favorites.remove(current);
    } else {
      favorites.add(current);
    }
    notifyListeners();
  }

  void removeFavorite(WordPair pair) {
    favorites.remove(pair);
    notifyListeners();
  }
}

// ignore: must_be_immutable
class MyHomePage extends StatefulWidget {
  int? userId;
  String? token;
  final bool isLoggedIn;
  bool comingFromProfilePage;
  MyHomePage({
    required this.userId,
    required this.token,
    required this.isLoggedIn,
    this.comingFromProfilePage = false,
  });
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.comingFromProfilePage ? 2 : 0;
    fetchUser();
  }

  void _onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  void _onBottomNavigationBarItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  Future<void> fetchUser() async {
    final userResponse = await http.get(
      Uri.parse('http://192.168.1.17:8000/api/users/${widget.userId}'),
      headers: {
        'Authorization': 'token ${widget.token}',
      },
    );

    if (userResponse.statusCode == 200) {
      setState(() {
        userData = json.decode(userResponse.body);
      });
      print('User data: $userData');
    } else {
      print(
          'Failed to fetch user data. Status code: ${userResponse.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userData == null) {
      return Center(child: CircularProgressIndicator());
    } else {
      Widget page;
      switch (selectedIndex) {
        case 2:
          page = UserDetailsPage(userData: userData);
        case 1:
          page = FavouritesPage();
        case 0:
          page = GeneratorPage();
        case 3:
          page = BlogPostsPage();
        default:
          throw UnimplementedError('no widget for $selectedIndex');
      }

      return Scaffold(
        appBar: AppBar(
          title: Text('Flutter App'),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: page,
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.indigo,
                ),
                child: UserAccountsDrawerHeader(
                  decoration: BoxDecoration(color: Colors.indigo),
                  accountName: Text(userData!['username']),
                  accountEmail: Text(userData!['email']),
                  currentAccountPictureSize: Size.square(50),
                  currentAccountPicture: CircleAvatar(
                      child: ClipOval(
                          child: Image.network(
                    "${userData!['avatar']}",
                    fit: BoxFit.cover,
                    width: 100,
                    height: 100,
                  ))),
                ),
              ),
              ListTile(
                title: const Text('Home'),
                leading: Icon(Icons.home),
                selected: selectedIndex == 0,
                onTap: () {
                  _onItemTapped(0);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Favourites'),
                leading: Icon(Icons.favorite),
                selected: selectedIndex == 1,
                onTap: () {
                  _onItemTapped(1);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('User Details'),
                leading: Icon(Icons.person),
                selected: selectedIndex == 2,
                onTap: () {
                  _onItemTapped(2);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Logout'),
                trailing: Icon(Icons.logout),
                onTap: () async {
                  const String logoutUrl =
                      'http://192.168.1.17:8000/api/logout/';
                  final logoutResponse = await http.post(Uri.parse(logoutUrl));
                  if (logoutResponse.statusCode == 200) {
                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    prefs.setBool('isLoggedIn', false);
                    prefs.remove('userId');
                    prefs.remove('token');
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoginPage(isLoggedIn: false),
                      ),
                    );
                  } else {
                    print(
                        'Logout failed. Status code: ${logoutResponse.statusCode}');
                  }
                },
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: selectedIndex,
          onTap: _onBottomNavigationBarItemTapped,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite),
              label: 'Favourite',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'User',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.article),
              label: 'Blogs',
            ),
          ],
        ),
      );
    }
  }
}

class GeneratorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;

    IconData icon;
    if (appState.favorites.contains(pair)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BigCard(pair: pair),
          SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  appState.toggleFavorite();
                },
                icon: Icon(icon),
                label: Text('Like'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  appState.getNext();
                },
                child: Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.pair,
  });

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );
    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          pair.asLowerCase,
          style: style,
          semanticsLabel: "${pair.first} ${pair.second}",
        ),
      ),
    );
  }
}

class FavouritesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var appState = context.watch<MyAppState>();

    if (appState.favorites.isEmpty) {
      return Center(
        child: Text('No favorites yet.'),
      );
    }

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text('You have '
              '${appState.favorites.length} favorites:'),
        ),
        for (var pair in appState.favorites)
          ListTile(
            leading: IconButton(
              icon: Icon(Icons.delete_outline, semanticLabel: 'Delete'),
              color: theme.colorScheme.primary,
              onPressed: () {
                appState.removeFavorite(pair);
              },
            ),
            title: Text(pair.asLowerCase),
          ),
      ],
    );
  }
}

class UserDetailsPage extends StatelessWidget {
  final Map<String, dynamic>? userData;

  UserDetailsPage({required this.userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('User Details'),
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: userData != null
            ? ListView(
                children: [
                  CircleAvatar(
                    radius: 70,
                    child: ClipOval(
                      child: Image.network(
                        "${userData!['avatar']}",
                        fit: BoxFit.cover,
                        height: 200,
                        width: 140,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 16,
                  ),
                  Card(
                    elevation: 5,
                    child: ListTile(
                      title: Text('Username'),
                      subtitle: Text(userData!['username']),
                    ),
                  ),
                  Card(
                    elevation: 5,
                    child: ListTile(
                      title: Text('Email'),
                      subtitle: Text(userData!['email']),
                    ),
                  ),
                  Card(
                    elevation: 5,
                    child: ListTile(
                      title: Text('Date of Birth'),
                      subtitle: Text(userData!['dob'] ?? 'Not Available'),
                    ),
                  ),
                  Card(
                    elevation: 5,
                    child: ListTile(
                      title: Text('Mobile'),
                      subtitle: Text(userData!['mobile'] ?? 'Not Available'),
                    ),
                  ),
                  Card(
                    elevation: 5,
                    child: ListTile(
                      title: Text('Latitude'),
                      subtitle: Text(userData!['latitude'].toString()),
                    ),
                  ),
                  Card(
                    elevation: 5,
                    child: ListTile(
                      title: Text('Longitude'),
                      subtitle: Text(userData!['longitude'].toString()),
                    ),
                  ),
                  SizedBox(height: 16),
                  Card(
                    elevation: 5,
                    child: userData!['latitude'] != null &&
                            userData!['longitude'] != null
                        ? Container(
                            height: 300,
                            child: MapScreen(
                              latitude: userData!['latitude'],
                              longitude: userData!['longitude'],
                            ),
                          )
                        : Container(
                          height: 100,
                          child: Center(
                              child: Text('Location not available'),
                            ),
                        ),
                  ),
                  // ElevatedButton(
                  //   onPressed: () {
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(
                  //         builder: (context) => MapScreen(
                  //           latitude: userData!['latitude'],
                  //           longitude: userData!['longitude'],
                  //         ),
                  //       ),
                  //     );
                  //   },
                  //   child: Text('Show on Map', style: TextStyle(fontSize: 14)),
                  // ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => Profile(
                                  userData: userData,
                                )),
                      );
                    },
                    child: Text('Update', style: TextStyle(fontSize: 14)),
                  ),
                  /* ElevatedButton(
                    onPressed: () async {
                      // Implement logout logic
                      final String logoutUrl =
                          'http://192.168.1.17:8000/api/logout/';
                      final logoutResponse =
                          await http.post(Uri.parse(logoutUrl));

                      if (logoutResponse.statusCode == 200) {
                        SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                        prefs.setBool('isLoggedIn', false);
                        prefs.remove('userId');
                        prefs.remove('token');
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoginPage(isLoggedIn: false),
                          ),
                        );
                      } else {
                        print(
                            'Logout failed. Status code: ${logoutResponse.statusCode}');
                      }
                    },
                    child: Text('Logout', style: TextStyle(fontSize: 14)),
                  ), */
                ],
              )
            : Center(
                child: CircularProgressIndicator(),
              ),
      ),
    );
  }
}
