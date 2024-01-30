import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';

class CommentDisplay extends StatefulWidget {
  final int? userId;
  final int postId;

  const CommentDisplay({required this.userId, required this.postId});

  @override
  State<CommentDisplay> createState() => _CommentDisplayState();
}

class _CommentDisplayState extends State<CommentDisplay> {
  TextEditingController commentController = TextEditingController();
  List<dynamic> comments = [];
  List<dynamic>? commentsWithReplies;
  String hint = 'Enter comment...';
  FocusNode commentFocusNode = FocusNode();
  int? parentId;
  bool isReplying = false;

  @override
  initState() {
    super.initState();
    _getComments();
  }

  Future<void> _getComments() async {
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
  }

  Future<void> _addComment(
      int postId, String commentBody, int? userId, int? parent) async {
    final response = await http.post(
      Uri.parse('http://192.168.1.17:8000/api/comment/'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'post': postId,
        'body': commentBody,
        'author': userId,
        'active': true,
        'parent': parent,
      }),
    );

    if (response.statusCode == 201) {
      commentController.clear();
      setState(() {
        FocusScope.of(context).unfocus();
        hint = 'Enter comment...';
        parentId = null;
        isReplying = false;
        _getComments();
      });
      print('Comment added successfully');
    } else {
      print('Failed to add comment. Status code: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> commentWidgets = [];
    if (commentsWithReplies == null) {
      return CircularProgressIndicator();
    } else {
      if (commentsWithReplies!.isNotEmpty) {
        commentWidgets.add(Center(
          child: Text(
            'Comments',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ));

        for (var commentData in commentsWithReplies!) {
          commentWidgets.add(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: ClipOval(
                        child: Image.network(
                          "${commentData['comment']?['author_image']}",
                          fit: BoxFit.cover,
                          width: 100,
                          height: 100,
                        ),
                      ),
                    ),
                    title: Text(
                      '${commentData['comment']?['author_name']}',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          commentData['comment']?['body'],
                          style: TextStyle(fontSize: 16),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              hint =
                                  'replying to @${commentData['comment']?['author_name']}';
                              FocusScope.of(context)
                                  .requestFocus(commentFocusNode);
                              parentId = commentData['comment']?['id'];
                              isReplying = !isReplying;
                            });
                          },
                          /* onTap: () {
                            hint = 'replying to @${commentData['comment']?['author_name']}';
                            FocusScope.of(context).requestFocus(commentFocusNode);
                            setState(() {
                              parentId = commentData['comment']?['id'];
                            });
                          }, */
                          child: Padding(
                            padding: const EdgeInsets.only(left: 40),
                            child: Text(
                              'Reply...',
                              style:
                                  TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (commentData['replies'] != null &&
                    commentData['replies'].isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        commentData['showReplies'] =
                            !(commentData['showReplies'] ?? false);
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(left: 65),
                      child: Row(children: [
                        Text(
                          commentData['showReplies'] == true
                              ? 'hide reply'
                              : "view ${commentData['replies'].length} reply",
                          style: TextStyle(color: Colors.indigo),
                        ),
                        SizedBox(width: 2),
                        Icon(
                          commentData['showReplies'] == true
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: Colors.indigo,
                        ),
                      ]),
                    ),
                  ),
                if (commentData['showReplies'] == true)
                  Column(
                    children:
                        (commentData['replies'] as List).map<Widget>((reply) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 32),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: ClipOval(
                              child: Image.network(
                                "${reply['comment']?['author_image']}",
                                fit: BoxFit.cover,
                                width: 100,
                                height: 100,
                              ),
                            ),
                          ),
                          title: Text(
                            reply['comment']['author_name'],
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            reply['comment']['body'],
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          );
        }
      } else {
        commentWidgets.add(
          Center(
            child: Text(
              'No Comments Yet',
              style: TextStyle(fontSize: 20),
            ),
          ),
        );
      }
      return Column(
        children: [
          Flexible(
            flex: 6,
            child: ListView(children: commentWidgets),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 10, left: 4, right: 5),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    focusNode: commentFocusNode,
                    controller: commentController,
                    decoration: InputDecoration(
                      hintText: hint,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      suffixIcon: isReplying
                          ? IconButton(
                              icon: Icon(Icons.cancel, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  hint = 'Enter comment...';
                                  parentId = null;
                                  FocusScope.of(context).unfocus();
                                  commentController.clear();
                                  isReplying = !isReplying;
                                });
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                SizedBox(width: 4),
                CircleAvatar(
                  backgroundColor: Colors.indigo,
                  radius: 23,
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: () {
                      _addComment(
                        widget.postId,
                        commentController.text,
                        widget.userId,
                        parentId,
                      );
                    },
                  ),
                ),
              ],
            ),
          )
        ],
      );
    }
  }
}
