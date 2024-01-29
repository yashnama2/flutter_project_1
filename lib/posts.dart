import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_project_1/post_detail.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:intl/intl.dart';

class BlogPostsPage extends StatefulWidget {
  @override
  _BlogPostsPageState createState() => _BlogPostsPageState();
}

class _BlogPostsPageState extends State<BlogPostsPage> {
  List<dynamic> blogPosts = [];
  List<dynamic> categories = ['All'];
  List<dynamic> validPosts = [];
  List<dynamic> tag = [];
  String selectedCategory = "All";
  String searchQuery = "";
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    fetchBlogPosts();
  }

  Future<void> fetchBlogPosts() async {
    final response =
        await http.get(Uri.parse('http://192.168.1.17:8000/api/post/'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      //await Future.delayed(Duration(milliseconds: 500));
      if (responseData.containsKey("results")) {
        setState(() {
          blogPosts = responseData["results"];
        });
        categories.addAll(
            blogPosts.map((post) => post['category_name']).toSet().toList());
        //print(blogPosts);
        validPosts =
            blogPosts.where((post) => post['published_date'] != null).toList();
      } else {
        print("Error: The 'results' key is missing in the response.");
      }
    } else {
      print('Failed to fetch blog posts. Status code: ${response.statusCode}');
    }
  }

  truncate_text(String text) {
    if (text.length <= 200) {
      return text;
    } else {
      return text.substring(0, 182) + "...";
    }
  }

  formatDate(String date) {
    DateTime apiDate = DateTime.parse(date);
    DateFormat formatter = DateFormat('yyyy/MM/dd');
    String formattedDate = formatter.format(apiDate);
    return formattedDate;
  }

  postFilter() {
    String query = searchQuery.toLowerCase();
    if (selectedCategory == "All") {
      final RegExp regExp = RegExp(query, caseSensitive: false);
      return validPosts
          .where((post) =>
              regExp.hasMatch(post['title'].toLowerCase()) ||
              regExp.hasMatch(post['text'].toLowerCase()) ||
              post['tag_name'].any((tag) => regExp.hasMatch(tag.toLowerCase())))
          .toList();
    } else {
      final RegExp regExp = RegExp(query, caseSensitive: false);
      return validPosts
          .where((post) =>
              post['category_name'] == selectedCategory &&
              (regExp.hasMatch(post['title'].toLowerCase()) ||
                  regExp.hasMatch(post['text'].toLowerCase()) ||
                  post['tag_name']
                      .any((tag) => regExp.hasMatch(tag.toLowerCase()))))
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (blogPosts.isEmpty) {
      return CircularProgressIndicator.adaptive();
    } else {
      return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: !isSearching
              ? Text('Blog')
              : TextField(
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                  style: TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    icon: Icon(Icons.search, color: Colors.black),
                    hintText: 'Search...',
                    hintStyle: TextStyle(color: Colors.black),
                  ),
                ),
          actions: [
            IconButton(
              icon: Icon(isSearching ? Icons.cancel : Icons.search),
              onPressed: () {
                setState(() {
                  isSearching = !isSearching;
                  if (!isSearching) {
                    // Clear the search query and refresh the posts
                    searchQuery = "";
                  }
                });
              },
            ),
          ],
        ),
        body: Flex(
          direction: Axis.vertical,
          children: [
            Expanded(
              flex: 1,
              child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCategory = categories[index];
                        });
                      },
                      child: Container(
                        margin: EdgeInsets.only(top: 12, bottom: 12, right: 12),
                        //height: 10,
                        decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.all(Radius.elliptical(20, 18)),
                            color: selectedCategory == categories[index]
                                ? Colors.indigo
                                : Colors.grey.shade300),
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: Center(
                            child: Text(
                              category,
                              style: TextStyle(
                                  color: selectedCategory == categories[index]
                                      ? Colors.white
                                      : Colors.black),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
            ),
            Expanded(
              flex: 9,
              child: ListView.builder(
                itemCount: postFilter().length,
                itemBuilder: (context, index) {
                  final List<dynamic> sortedPost = postFilter();
                  sortedPost.sort((a, b) {
                    DateTime dateA = DateTime.parse(a['published_date']);
                    DateTime dateB = DateTime.parse(b['published_date']);
                    return dateB.compareTo(dateA);
                  });
                  final post = sortedPost[index];
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            CupertinoPageRoute(
                                builder: (context) =>
                                    PostDetail(postId: post['id'])));
                      },
                      child: Card(
                        elevation: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Stack(children: [
                                Container(
                                  constraints: BoxConstraints(maxWidth: 500),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      post['image'],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Container(
                                    constraints: BoxConstraints(maxWidth: 100),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.all(
                                            Radius.elliptical(5, 3)),
                                        color: Colors.yellow,
                                        boxShadow: [
                                          BoxShadow(
                                              color: const Color.fromARGB(
                                                  122, 0, 0, 0),
                                              blurRadius: 10)
                                        ]),
                                    child: Padding(
                                      padding: EdgeInsets.all(4),
                                      child: Center(
                                        child: Text(
                                          post['category_name'],
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              ]),
                            ),
                            SizedBox(height: 8),
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  HtmlWidget(
                                    post['title'],
                                    textStyle:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 8),
                                  Container(
                                    constraints: BoxConstraints(maxHeight: 100),
                                    child:
                                        HtmlWidget(truncate_text(post['text'])),
                                  ),
                                ]),
                            SizedBox(
                              height: 12,
                            ),
                            /* Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text('Published On : '),
                                Text(formatDate(post['published_date'])),
                              ],
                            ) */
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }
  }
}
