import 'package:flutter/material.dart';
import 'package:flutter_project_1/main.dart';
import 'package:flutter_project_1/posts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

class PostDetail extends StatefulWidget {
  final int postId;
  PostDetail({required this.postId});

  @override
  State<PostDetail> createState() => _PostDetailState();
}

class _PostDetailState extends State<PostDetail> {
  Map<String, dynamic>? post;
  List<dynamic> tag = [];
  @override
  initState() {
    super.initState();
    _getPost();
  }

  Future<void> _getPost() async {
    final response = await http
        .get(Uri.parse('http://192.168.1.17:8000/api/post/${widget.postId}'));
    if (response.statusCode == 200) {
      setState(() {
        post = json.decode(response.body);
        tag = post!['tag_name'];
      });
    }
  }

  formatDate(String date) {
    DateTime apiDate = DateTime.parse(date);
    DateFormat formatter = DateFormat('MMM.dd,yyyy');
    String formattedDate = formatter.format(apiDate);
    return formattedDate;
  }

  @override
  Widget build(BuildContext context) {
    if (post == null) {
      return CircularProgressIndicator();
    } else {
      return Scaffold(
        appBar: AppBar(title: Text('Post Detail')),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HtmlWidget(
                  post!['title'],
                  textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                ),
                SizedBox(height: 12),
                Row(children: [
                  Text('Published : '),
                  Text(formatDate(post!['published_date'])),
                  Spacer(),
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.edit,
                      )),
                ]),
                SizedBox(
                  height: 4,
                ),
                Center(
                  child: Stack(children: [
                    Container(
                      constraints: BoxConstraints(maxWidth: 1200),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          post!['feature_image'],
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Container(
                          constraints: BoxConstraints(maxWidth: 100),
                          decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.elliptical(5, 3)),
                              color: Colors.yellow,
                              boxShadow: [
                                BoxShadow(
                                    color: const Color.fromARGB(122, 0, 0, 0),
                                    blurRadius: 10)
                              ]),
                          child: Padding(
                            padding: EdgeInsets.all(4),
                            child: Center(
                              child: Text(
                                post!['category_name'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  ]),
                ),
                SizedBox(
                  height: 16,
                ),
                HtmlWidget(
                  post!['text'],
                  textStyle: TextStyle(fontSize: 16),
                ),
                SizedBox(
                  height: 16,
                ),
                Row(
                  children: [
                    Text(
                      'Tags : ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Wrap(
                      spacing: 8.0, // Adjust the spacing between tags
                      runSpacing:
                          8.0, // Adjust the spacing between rows of tags
                      children: tag.map((tags) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.0, vertical: 8.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            color: Colors.black,
                          ),
                          child: Text(
                            tags,
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                SizedBox(height: 16,),
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Text('By : ${post!['author_name']}', ),
                ),
                Container(
                      constraints: BoxConstraints(maxWidth: 80),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          post!['author_image'],
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
