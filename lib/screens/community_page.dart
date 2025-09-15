import 'package:flutter/material.dart';
import 'package:wear_space/screens/chat_list_page.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/community',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color.fromARGB(255, 3, 112, 7),
      ),
      routes: {
        '/community': (context) => const CommunityPage(),
        '/chats': (context) =>  const ChatListPage(),
      },
    );
  }
}

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              const CircleAvatar(
                backgroundImage: NetworkImage('https://i.imgur.com/QCNbOAo.png'),
                radius: 20,
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Zachary Nelson',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    '@heads.net',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                ),
                child: const Text('Follow', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
                 backgroundColor: const Color.fromARGB(255, 3, 87, 5),
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Chats'),
              Tab(text: 'Community'),
            ],
            indicatorColor: Colors.blue,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
          ),
        ),
        body: TabBarView(
          children: [
            ListView(
              padding: const EdgeInsets.all(8.0),
              children: [
                const ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage('https://i.imgur.com/QCNbOAo.png'),
                  ),
                  title: Text(
                    'Designed by the PMMT Designer team, this is for educational purposes only and this design will not be used in any way.',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    '10:10 AM',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '591 replies • 1.9K likes',
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(width: 5),
                      Icon(Icons.favorite, color: Colors.red, size: 16),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Image.network(
                  'https://via.placeholder.com/300x200', // Replace with building image
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey,
                      child: const Center(child: Text('Image failed to load', style: TextStyle(color: Colors.white))),
                    );
                  },
                ),
                const ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage('https://i.imgur.com/QCNbOAo.png'),
                  ),
                  title: Text(
                    'Replying to @ZacharyNelson',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  subtitle: Text(
                    'Designed by the PMMT Designer team, this is for educational purposes only and this design will not be used in any way.',
                    style: TextStyle(color: Colors.white),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '591 replies • 1.9K likes',
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(width: 5),
                      Icon(Icons.favorite, color: Colors.red, size: 16),
                    ],
                  ),
                ),
                const ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage('https://i.imgur.com/QCNbOAo.png'),
                  ),
                  title: Text(
                    'Replying to @ZacharyNelson',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  subtitle: Text(
                    'Designed by the PMMT Designer team, this is for educational purposes only and this design will not be used in any way.',
                    style: TextStyle(color: Colors.white),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '591 replies • 1.9K likes',
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(width: 5),
                      Icon(Icons.favorite, color: Colors.red, size: 16),
                    ],
                  ),
                ),
              ],
            ),
            Container(), // Placeholder for Replies Tab
          ],
        ),
      ),
    );
  }
}