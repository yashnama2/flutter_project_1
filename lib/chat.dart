import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:web_socket_channel/web_socket_channel.dart';

class Chat extends StatefulWidget {
  final Map channel;
  final int? userId;
  Chat({required this.channel, required this.userId});
  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  List chats = [];
  final _controller = StreamController<dynamic>();
  bool typing = false;
  bool loading = false;
  final _channel = WebSocketChannel.connect(
    Uri.parse(
        'ws://192.168.1.15:8000/ws/channel/21/937f1eb63d5668678a666d19198f2dad8016ee84/'),
  );
  final TextEditingController _textController = TextEditingController();
  // Timer? typingTimer;

  @override
  void initState() {
    super.initState();
    _channel.stream.listen(
      (message) {
        final jsonMessage = jsonDecode(message);
        handleChats(jsonMessage);
        _controller.add(message);
      },
      onDone: () {
        _controller.close();
      },
      onError: (error) {
        // Handle errors
      },
    );
    fetchChats();
  }

  handleChats(jsonMessage) {
    if (jsonMessage['type'] == 'message') {
      DateTime now = DateTime.now();
      DateTime currentDate = DateTime(now.year, now.month, now.day);
      String rdate = currentDate.toString().split(" ")[0];
      String ruser = jsonMessage['senders']['first_name'] +
          ' ' +
          jsonMessage['senders']['last_name'];
      String rtext = jsonMessage['message'];
      int rsender = jsonMessage['senders']['id'];
      // print('$rdate, $ruser, $rtext, $rsender');
      int todayIndex = chats.indexWhere((chat) => chat['date'] == rdate);
      if (todayIndex != -1) {
        if (mounted) {
        setState(() {
          chats[todayIndex]['data'].insert(
            0, // Assuming you want to add at the beginning of the data list
            {
              // 'id': sender,
              'senders': {
                'id': rsender,
                'display': ruser,
              },
              'message': rtext,
              'timestamp': jsonMessage['timestamp'],
              // 'status': 'Active',  // Adjust this as needed
              // 'parent': null,  // Adjust this as needed
              // 'channel': jsonMessage['channel'],  // Adjust this as needed
              // 'file': [],  // You may customize this based on your data structure
              // 'deliver': [],  // You may customize this based on your data structure
              // 'seen': [],  // You may customize this based on your data structure
              // 'star': [],  // You may customize this based on your data structure
            },
          );
        });}
      } else {
        if (mounted) {
        setState(() {
          chats.insert(
            0, // Assuming you want to add at the beginning of the chats list
            {
              'date': rdate,
              'data': [
                {
                  // 'id': sender,  // You may want to use a unique identifier here
                  'senders': {
                    'id': rsender,
                    'display': ruser,
                    // Add other sender details if needed
                  },
                  // 'files': [],  // You may customize this based on your data structure
                  // 'date': rdate,
                  'message': rtext,
                  'timestamp': jsonMessage['timestamp'],
                  // 'status': 'Active',  // Adjust this as needed
                  // 'parent': null,  // Adjust this as needed
                  // 'channel': jsonMessage['channel'],  // Adjust this as needed
                  // 'file': [],  // You may customize this based on your data structure
                  // 'deliver': [],  // You may customize this based on your data structure
                  // 'seen': [],  // You may customize this based on your data structure
                  // 'star': [],  // You may customize this based on your data structure
                },
              ],
            },
          );
        });}
      }
    } else if (jsonMessage['senders']['id'] != 2) {
      if (mounted) {
      setState(() {
        typing = true;
      });}
      Timer(Duration(seconds: 1), () {
        if (mounted) {
        setState(() {
          typing = false;
        });}
      });
    }
  }

  @override
  void dispose() {
    _channel.sink.close();
    _textController.dispose();
    // typingTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchChats() async {
    loading = true;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final response = await http.get(
        // Uri.parse(
        //     'https://test.securitytroops.in/stapi/v1/jabber/chatgroup/?channel=${widget.channel['id']}'),
        Uri.parse(
            'http://192.168.1.15:8000/stapi/v1/jabber/chatgroup/?channel=21'),
        headers: {
          'Authorization': 'token 937f1eb63d5668678a666d19198f2dad8016ee84'
        });
    if (response.statusCode == 200) {
      loading = false;
      final Map chatsData = json.decode(response.body);
      if (chatsData['results'].isNotEmpty) {
        setState(() {
          chats = chatsData['results'];
        });
      } else {
        chats = [];
      }
      // print('chats: $chats');
    } else {
      print('Failed. Status code: ${response.statusCode}');
    }
  }

  formatTime(String time) {
    tzdata.initializeTimeZones();
    tz.Location location = tz.getLocation('Asia/Kolkata');

    DateTime apiTime = DateTime.parse(time);
    tz.TZDateTime tzDateTime = tz.TZDateTime.from(apiTime, location);

    String formattedTime = DateFormat('h:mm a').format(tzDateTime);
    return formattedTime;
  }

  formatDate(String date) {
    DateTime apiDate = DateTime.parse(date);
    DateFormat formatter = DateFormat('d MMMM yyyy');
    String formattedDate = formatter.format(apiDate);
    return formattedDate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.indigo,
        flexibleSpace: SafeArea(
          child: Container(
            padding: EdgeInsets.only(right: 16),
            child: Row(
              children: <Widget>[
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
                ),
                SizedBox(
                  width: 2,
                ),
                CircleAvatar(
                  maxRadius: 20,
                  child: widget.channel['display']['image'] == '' ||
                          widget.channel['display']['image'] ==
                              'https://test.securitytroops.in/media/default/st-logo.png'
                      ? ClipOval(
                          child: Image.asset(
                          'assets/images/app_logo.png',
                          //fit: BoxFit.cover,
                        ))
                      : ClipOval(
                          child: Image.network(
                          "${widget.channel['display']['image']}",
                          fit: BoxFit.cover,
                          height: 60,
                          width: 60,
                        )),
                ),
                SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        widget.channel['display']['name'],
                        style: TextStyle(color: Colors.white),
                      ),
                      SizedBox(
                        height: 6,
                      ),
                      Row(
                        children: [
                          Text(
                            typing ? 'typing...' : "Online",
                            style: TextStyle(
                                color: Colors.grey.shade300, fontSize: 13),
                          ),
                          SizedBox(
                            width: 4,
                          ),
                          if (!typing)
                            Icon(
                              Icons.circle,
                              color: Colors.green,
                              size: 7,
                            )
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: loading ? Center(child: CircularProgressIndicator(),) : Container(
        decoration: BoxDecoration(
          image: DecorationImage(
              image: AssetImage('assets/images/chatbg.png'), fit: BoxFit.cover),
        ),
        child: Column(
          children: [
            StreamBuilder<dynamic>(
              stream: _controller.stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.active) {
                  // Access snapshot.data to get the received message
                  final receivedMessage = snapshot.data;
                  // print('Received message: $receivedMessage');
                  return SizedBox.shrink();
                } else {
                  // Handle other connection states
                  return Container();
                }
              },
            ),
            Expanded(
              child: chats.isNotEmpty
                  ? Align(
                      alignment: Alignment.topCenter,
                      child: ListView.builder(
                        itemCount: chats.length,
                        shrinkWrap: true,
                        reverse: true,
                        itemBuilder: (context, chatIndex) {
                          final date = chats[chatIndex];
                          if (date.containsKey('data') &&
                              date['data'] is List &&
                              date['data'].isNotEmpty) {
                            // print('date: $date');
                            return Column(
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade400,
                                      borderRadius: BorderRadius.circular(7.0),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 5, horizontal: 7),
                                      child: Text(formatDate(date['date'])),
                                    ),
                                  ),
                                ),
                                ListView.builder(
                                    shrinkWrap: true,
                                    reverse: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemCount: date['data'].length,
                                    itemBuilder: (context, dataIndex) {
                                      // print('date: $date');
                                      final message = date['data'][dataIndex];
                                      // print('message $message');
                                      final user =
                                          message['senders']['display'];
                                      // print('user $user');
                                      final text = message['message'];
                                      final sender = message['senders']['id'];
                                      return Container(
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 5.0),
                                        child: Align(
                                          alignment: sender != 2
                                              ? Alignment.topLeft
                                              : Alignment.topRight,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8),
                                            child: Container(
                                              constraints: BoxConstraints(
                                                  maxWidth:
                                                      MediaQuery.of(context)
                                                              .size
                                                              .width *
                                                          0.7),
                                              padding: EdgeInsets.all(10.0),
                                              decoration: BoxDecoration(
                                                color: sender != 2
                                                    ? Colors.grey.shade200
                                                    : Colors.indigo,
                                                // borderRadius: BorderRadius.circular(20.0),
                                                borderRadius: BorderRadius.only(
                                                  topLeft: Radius.circular(
                                                      sender == 2 ? 20.0 : 0.0),
                                                  topRight: Radius.circular(
                                                      sender == 2 ? 0.0 : 20.0),
                                                  bottomLeft:
                                                      Radius.circular(20.0),
                                                  bottomRight:
                                                      Radius.circular(20.0),
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  if (sender != 2)
                                                    Text(
                                                      user,
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  Text(
                                                    text,
                                                    style: TextStyle(
                                                        color: sender == 2
                                                            ? Colors.white
                                                            : Colors.black),
                                                  ),
                                                  Align(
                                                    alignment:
                                                        Alignment.bottomRight,
                                                    child: Text(
                                                      formatTime(
                                                          message['timestamp']),
                                                      style: TextStyle(
                                                          fontSize: 10.0,
                                                          color: sender != 2
                                                              ? Colors.black54
                                                              : Colors.white54),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                              ],
                            );
                          } else {
                            return SizedBox.shrink();
                          }
                        },
                      ),
                    )
                  : Container(),
            ),
            _buildTextComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextComposer() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8),
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        // border: Border.all(color: Colors.indigo),
        borderRadius: BorderRadius.circular(30.0),
      ),
      child: Row(
        children: [
          Flexible(
            child: TextField(
              //   onChanged: (text) {
              //   if (text.isNotEmpty) {
              //     typingTimer?.cancel();
              //     typingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
              //       _handleTyping();
              //     });
              //   }
              // },
              controller: _textController,
              onChanged: (value) {
                _handleTyping();
              },

              onSubmitted: _handleSubmitted,
              decoration: InputDecoration(
                hintText: 'Send message...',
                border: InputBorder.none,
              ),
            ),
          ),
          SizedBox(width: 8.0),
          IconButton(
            icon: Icon(
              Icons.send,
              color: Colors.indigo,
            ),
            onPressed: () {
              // typingTimer?.cancel();
              _handleSubmitted(_textController.text);
            },
          ),
        ],
      ),
    );
  }

  void _handleSubmitted(String text) {
    if (_textController.text.isNotEmpty) {
      _channel.sink.add(
        jsonEncode({
          'message': _textController.text,
          'type': 'message',
          'parent': false,
          'files': []
        }),
      );
      _textController.clear();
    }
  }

  _handleTyping() {
    // print('typing');
    _channel.sink.add(jsonEncode(
        {'message': '', 'type': 'typing', 'parent': 0, 'files': ''}));
  }
}

// {"message": "", "type": "typing", "senders": {"id": 4, "email": "Kuldeel@segnotech.com", "first_name": "Kuldeep", "last_name": "Soni", "username": "kuldeep", "mobile": 78965482135, "image": "http://192.168.1.15:8000/media/default/st-logo.png"}, "timestamp": "2024-02-03 12:47:15", "file": false, "files": "", "id": 0, "parent": 0, "reply": ""}	
