import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_project_1/chat.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

enum SampleItem { itemOne, itemTwo}

class Channel extends StatefulWidget {
  final String? token;
  final int? userId;

  Channel({required this.token, required this.userId});
  @override
  State<Channel> createState() => _ChannelState();
}

class _ChannelState extends State<Channel> {
  Map<String, dynamic> selectedCompany = {};
  Map<String, dynamic> companies = {};
  List<dynamic> companiesId = [];
  SampleItem? selectedMenu;
  List<dynamic> channels = [];
  Map<String, dynamic> teams = {};
  Map<String, dynamic>? userData;
  int? company;
  List<int> selectedUsers = [];
  String channelTitle = '';

  @override
  void initState() {
    super.initState();
    fetchCompanies();
  }

  setCompany(companyId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('companyId', companyId);
    setState(() {
      company = prefs.getInt('companyId');
    });
    print(company);
    fetchChannel(prefs.getInt('companyId'));
    fetchTeam(company);
  }

  Future<void> fetchCompanies() async {
    final response = await http.get(
        Uri.parse('https://test.securitytroops.in/stapi/v1/agency/company/'),
        headers: {'Authorization': 'token ${widget.token}'});

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data['results'].isEmpty) {
        setState(() {
          companies = {'1': 'No Company available'};
        });
      } else {
        if (mounted) {
          setState(() {
            companies = {
              for (var company in data['results'])
                company['id'].toString(): company['name']
            };
            // companies = data['results']
            //     .map<String>((company) => company['name'].toString())
            //     .toSet()
            //     .toList();
            // companiesId = data['results']
            //     .map<dynamic>((company) => company['id'])
            //     .toSet()
            //     .toList();
            selectedCompany = {
              'id': companies.keys.first,
              'name': companies[companies.keys.first],
            };
          });
        }

        setCompany(int.parse(selectedCompany['id']));
      }
    } else {
      throw Exception('Failed to load companies');
    }
  }

  Future<void> fetchChannel(companyId) async {
    final response = await http.get(
        Uri.parse(
            'https://test.securitytroops.in/stapi/v1/jabber/channel/?company=$companyId'),
        headers: {'Authorization': 'token ${widget.token}'});
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data['results'].isNotEmpty) {
        if (mounted) {
          setState(() {
            channels = data['results'];
          });
        }
      } else {
        setState(() {
          channels = [];
        });
      }
      print('got channels');
    } else {
      print('Failed. Status code: ${response.statusCode}');
    }
  }

  Future<void> fetchTeam(company) async {
    print('fetch team called');
    final response = await http.get(
      Uri.parse(
          'https://test.securitytroops.in/stapi/v1/agency/team/?suspend=false&company=$company'),
      headers: {
        'Authorization': 'token ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data['results'].isNotEmpty) {
        if (mounted) {
          setState(() {
            teams = {
              for (var user in data['results'])
                user['users']['id'].toString(): user['users']['display']
            };
          });
        }
      } else {
        setState(() {
          teams.clear();
        });
      }
      print('teams fetched');
      print(teams);
    } else {
      // Handle the error when fetching users
      print('Failed to load users. Status code: ${response.statusCode}');
    }
  }

  void handleItemSelected(SampleItem item) {
    print('Item selected: $item');
    if (item == SampleItem.itemOne) {
      _createNewChannel(context);
    } else {
      _createNewIndividual(context);
    }
  }

  void _createNewChannel(BuildContext context) {
    selectedUsers = [widget.userId!];
    channelTitle = '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Column(
            children: [
              Text('Select Users for New Channel'),
              SizedBox(height: 16,),
              TextField(
                onChanged: (value) {
                  setState(() {
                    channelTitle = value;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Channel Title',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.indigo),
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
              ),
            ],
          ),
          content: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return Container(
              width: double.maxFinite,
              height: 200,
              child: ListView.builder(
                physics: AlwaysScrollableScrollPhysics(),
                itemCount: teams.length,
                itemBuilder: (BuildContext context, int index) {
                  final String userId = teams.keys.elementAt(index);
                  final String userName = teams[userId]!;
                  if (int.parse(userId) == widget.userId) {
                    return SizedBox.shrink();
                  }
                  return CheckboxListTile(
                    // selectedTileColor: Colors.indigo,
                    title: Text(userName),
                    value: selectedUsers.contains(int.parse(userId)),
                    onChanged: (bool? value) {
                      setState(() {
                        print(value);
                        if (value != null) {
                          //final int userIdInt = int.parse(userId);

                          if (value) {
                            selectedUsers.add(int.parse(userId));
                          } else {
                            selectedUsers.remove(int.parse(userId));
                          }
                        }
                      });
                    },
                  );
                },
              ),
            );
          }),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                createChannel(false);
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _createNewIndividual(BuildContext context) {
    selectedUsers = [widget.userId!];
    int selectedUserId = widget.userId!;
    channelTitle = '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select User for Chat'),
          content: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return Container(
              width: double.maxFinite,
              height: 250,
              child: ListView.builder(
                itemCount: teams.length,
                itemBuilder: (BuildContext context, int index) {
                  final String userId = teams.keys.elementAt(index);
                  final String userName = teams[userId]!;
                  if (int.parse(userId) == widget.userId) {
                    return SizedBox.shrink();
                  }
                  return RadioListTile(
                    // selectedTileColor: Colors.indigo,
                    title: Text(userName),
                    value: int.parse(userId),
                    groupValue: selectedUserId,
                    onChanged: (int? value) {
                      setState(() {
                        selectedUserId = value!;
                      });
                    },
                  );
                },
              ),
            );
          }),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                selectedUsers.add(selectedUserId);
                channelTitle =
                    '$selectedUserId-${teams[widget.userId.toString()]}';
                createChannel(true);
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void createChannel(bool individual) async {
    print('Creating channel with users: $selectedUsers');
    print('Creating channel with title: $channelTitle');
    final response = await http.post(
      Uri.parse('https://test.securitytroops.in/stapi/v1/jabber/channel/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'token ${widget.token}',
      },
      body: jsonEncode({
        'title': channelTitle,
        'owner': widget.userId,
        'company': company,
        'content': '',
        'collaborators': selectedUsers.toString(),
        'locate': '',
        'indivisual': individual,
        'archive': false,
        'admin': false,
      }),
    );
    if (response.statusCode == 201) {
      setState(() {
        fetchChannel(company);
      });
      Fluttertoast.showToast(msg: "Channel Created Successfully");
      print('success');
    } else {
      print('failed. Status code: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (companies.isEmpty && channels.isEmpty) {
      return CircularProgressIndicator();
    }
    return Scaffold(
      appBar: AppBar(
        // title: Text('Channels'),
        flexibleSpace: companies.isNotEmpty
            ? DropdownMenu<String>(
                initialSelection: companies.keys.first,
                onSelected: (String? newValue) {
                  setState(() {
                    selectedCompany = {
                      'id': newValue,
                      'name': companies[newValue!],
                    };
                    setCompany(int.parse(selectedCompany['id']));
                  });
                },
                dropdownMenuEntries:
                    companies.keys.map<DropdownMenuEntry<String>>((String id) {
                  return DropdownMenuEntry<String>(
                      value: id, label: companies[id]);
                }).toList(),
              )
            : Container(),
        actions: [
            Visibility(
              child: PopupMenuButton<SampleItem>(
                // initialValue: selectedMenu,
                onSelected: (SampleItem item) {
                  setState(() {
                    selectedMenu = item;
                  });
                  handleItemSelected(item);
                },
                itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<SampleItem>>[
                  const PopupMenuItem<SampleItem>(
                    value: SampleItem.itemOne,
                    child: Text('New Channel'),
                  ),
                  const PopupMenuItem<SampleItem>(
                    value: SampleItem.itemTwo,
                    child: Text('New Individual'),
                  ),
                ],
              ),
            ),
          ],
      ),
      body: channels.isNotEmpty
          ? ListView.builder(
              itemCount: channels.length,
              itemBuilder: (context, index) {
                final channel = channels[index];
                if (channel['id'] == 69) {
                return Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(context,
                          CupertinoPageRoute(builder: (context) => Chat(channel: channel, userId: widget.userId)));
                    },
                    child: ListTile(
                      leading: channel['display']['image'] == '' ||
                              channel['display']['image'] ==
                                  'https://test.securitytroops.in/media/default/st-logo.png'
                          ? CircleAvatar(
                              radius: 30,
                              child: ClipOval(
                                  child: Image.asset(
                                'assets/images/app_logo.png',
                                //fit: BoxFit.cover,
                              )))
                          : CircleAvatar(
                              radius: 30,
                              child: ClipOval(
                                  child: Image.network(
                                "${channel['display']['image']}",
                                fit: BoxFit.cover,
                                height: 60,
                                width: 60,
                              ))),
                      title: Text(channel['display']['name']),
                    ),
                  ),
                );} else {return Container();}
              },
            )
          : Center(
              child: Text('No channels available.'),
            ),
    );
  }
}
