import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;

class BlogPostsPage extends StatefulWidget {
  @override
  _BlogPostsPageState createState() => _BlogPostsPageState();
}

class _BlogPostsPageState extends State<BlogPostsPage> {
  List<dynamic> blogPosts = [];

  @override
  void initState() {
    super.initState();
    fetchBlogPosts();
  }

  Future<void> fetchBlogPosts() async {
    final response = await http.get(Uri.parse('http://192.168.1.17:8000/api/post/'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      if (responseData.containsKey("results")) {
        setState(() {
          blogPosts = responseData["results"];
        });
        print(blogPosts);
      } else {
        // Handle error: The 'posts' key is missing in the response.
        print("Error: The 'results' key is missing in the response.");
      }
      // setState(() {
      //   blogPosts = responseData[];
      // });
      
    } else {
      // Handle error
      print('Failed to fetch blog posts. Status code: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Blog Posts'),
      ),
      body: ListView.builder(
        itemCount: blogPosts.length,
        itemBuilder: (context, index) {
          final post = blogPosts[index];
          return ListTile(
            title: Text(post['title']),
            subtitle: Container(
                height: 200, // Set the height as needed
                child: WebView(
                  initialUrl: 'about:blank',
                  onWebViewCreated: (WebViewController controller) {
                    controller.loadUrl(Uri.dataFromString(
                      post['text'],
                      mimeType: 'text/html',
                      encoding: Encoding.getByName('utf-8'),
                    ).toString());
                  },
                ),
              ),
          );
        },
      ),
    );
  }
}
