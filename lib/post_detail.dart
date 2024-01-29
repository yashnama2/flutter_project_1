// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_project_1/comment.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
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
  int? id;
  String? token;
  List<dynamic> liked = [];
  // List<dynamic> comments = [];
  // List<dynamic>? commentsWithReplies;

  @override
  initState() {
    super.initState();
    _getPost();
    //_getComments();
  }

  /* Future<void> _getComments() async {
    final commentResponse = await http.get(
      Uri.parse('http://192.168.1.17:8000/api/comment/'),
    );

    if (commentResponse.statusCode == 200) {
      final Map<String, dynamic> responseData =
          json.decode(commentResponse.body);
      if (responseData.containsKey("results")) {
        setState(() {
          comments = responseData["results"]
              .where((comment) => comment['post'] == widget.postId)
              .toList();
          commentsWithReplies = _organizeComments(comments, null);
        });
        //print(commentsWithReplies);
      } else {
        print("Error: The 'results' key is missing in the response.");
      }
    } else {
      print(
          'Failed to load comments. Status code: ${commentResponse.statusCode}');
    }
  }

  List<dynamic> _organizeComments(List<dynamic> comments, int? parentId) {
    return comments
        .where((comment) => comment['parent'] == parentId)
        .map((comment) {
      final replies = _organizeComments(comments, comment['id']);
      return {
        'comment': comment,
        'replies': replies.isNotEmpty ? replies : null,
      };
    }).toList();
  } */

  /* void _showCommentsBottomSheet() {
    showModalBottomSheet(
      isScrollControlled: true,
      showDragHandle: true,
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height - 100,
            //padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'Comments',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ),
                SizedBox(height: 16),
                // Build a widget to display comments and their replies
                if (commentsWithReplies != null)
                  for (var commentData in commentsWithReplies!)
                    _buildCommentWidget(commentData, setState),
              ],
            ),
          );
        });
      },
    );
  } */

  /* Widget _buildCommentWidget(Map<String, dynamic> commentData) {
    final comment = commentData['comment'];
    final replies = commentData['replies'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: CircleAvatar(
              child: ClipOval(
                  child: Image.network(
            "${comment?['author_image']}",
            fit: BoxFit.cover,
            width: 100,
            height: 100,
          ))),
          title: Text(
            '${comment?['author_name']}',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            comment?['body'],
            style: TextStyle(fontSize: 16),
          ),
        ),
        if (replies != null && replies.isNotEmpty)
          GestureDetector(
            onTap: () {
              changeState();
              setState(() {
                commentData['showReplies'] =
                    !(commentData['showReplies'] ?? false);
              });
            },
            child: Padding(
              padding: EdgeInsets.only(left: 50),
              child: Text(
                commentData['showReplies'] == true
                    ? 'Hide Replies'
                    : 'Show Replies',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ),
        if (commentData['showReplies'] == true)
          ListView.builder(
            //key: ValueKey<int>(commentData.hashCode),
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: replies.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(left: 32),
                child: _buildCommentWidget(replies[index]),
              );
            },
          ),
      ],
    );
  } */

  Future<void> _getPost() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('userId');
    String? tokens = prefs.getString('token');
    final response = await http
        .get(Uri.parse('http://192.168.1.17:8000/api/post/${widget.postId}/'));
    if (response.statusCode == 200) {
      setState(() {
        post = json.decode(response.body);
        tag = post!['tag_name'];
        id = userId;
        token = tokens;
        liked = post!['likes'];
      });
    }
  }

  Future<void> _like() async {
    if (post!['likes'].contains(id)) {
      liked.remove(id);
    } else {
      liked.add(id);
    }
    //liked.add(id);
    final likeResponse = await http.patch(
      Uri.parse('http://192.168.1.17:8000/api/post/${widget.postId}/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'token $token',
      },
      body: jsonEncode({
        'likes': liked,
      }),
    );
    if (likeResponse.statusCode == 200) {
      setState(() {});
      print('success');
    } else {
      print('failed. Status code: ${likeResponse.statusCode}');
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
                  textStyle:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
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
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        _like();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          post!['likes'].contains(id)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: Colors.red,
                          size: 25,
                        ),
                      ),
                    ),
                    Text(
                      '${post!['likes'].length}',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
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
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Wrap(
                          spacing: 8.0, 
                          runSpacing:
                              8.0, 
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
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 16,
                ),
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Text(
                    'By : ${post!['author_name']}',
                  ),
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
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
              isScrollControlled: true,
              showDragHandle: true,
              context: context,
              builder: (context) {
                return Container(
                  padding: MediaQuery.of(context).viewInsets,
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height - 100,
                  child: CommentDisplay(userId: id, postId: widget.postId)
                );
              },
            );
          },
          elevation: 10,
          shape: CircleBorder(),
          child: Icon(Icons.comment_rounded),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      );
    }
  }
}
