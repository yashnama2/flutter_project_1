import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'main.dart';

class Profile extends StatefulWidget {
  final Map<String, dynamic>? userData;

  Profile({
    required this.userData,
  });
  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  late TextEditingController usernameController;
  late TextEditingController emailController;
  late TextEditingController dobController;
  late TextEditingController mobileController;
  late TextEditingController profilePictureController;
  late DateTime selectedDate;
  late bool imgSelect;
  File? selectedImage;

  @override
  void initState() {
    super.initState();
    imgSelect = false;
    selectedDate = DateTime.parse(widget.userData!['dob'] ?? '2000-01-01');
    usernameController =
        TextEditingController(text: widget.userData!['username']);
    emailController = TextEditingController(text: widget.userData!['email']);
    dobController = TextEditingController(text: widget.userData!['dob'] ?? '');
    mobileController =
        TextEditingController(text: widget.userData!['mobile'] ?? '');
    profilePictureController =
        TextEditingController(text: widget.userData!['avatar']);
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      imgSelect = true;
      print('Picked image path: ${pickedFile.path}');
      setState(() {
        selectedImage = File(pickedFile.path);
      });
      profilePictureController.text = pickedFile.path;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        dobController.text = selectedDate.toLocal().toString().split(' ')[0];
      });
    }
  }

  void updateUserProfile(String newUsername, String newEmail, String? newDob,
      String newMobile, String profilePicturePath) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // if (newDob == '') {
    //   newDob = null;
    // }
    String? token = prefs.getString('token');
    int? userId = prefs.getInt('userId');
    //bool? isLoggedIn = prefs.getBool('isLoggedIn');
    final String updateProfileUrl =
        'http://192.168.1.17:8000/api/users/$userId/';

    final File imageFile = File(profilePicturePath);
    var request = http.MultipartRequest('PATCH', Uri.parse(updateProfileUrl));
    request.headers['Authorization'] = 'token $token';
    print(imgSelect);
    if (imgSelect == true) {
      request.files
          .add(await http.MultipartFile.fromPath('avatar', imageFile.path));
    }
    request.fields['username'] = newUsername;
    request.fields['email'] = newEmail;
    if (newDob != null) {
      request.fields['dob'] = newDob;
    }
    request.fields['mobile'] = newMobile;

    var response = await request.send();

    if (response.statusCode == 200) {
      // Update successful
      print('Profile updated successfully');

      // Navigate back to UserDetailsPage with updated user data
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => MyHomePage(
                  userId: userId,
                  token: token,
                  isLoggedIn: true,
                  comingFromProfilePage: true,
                )),
      );
    } else {
      // Handle update failure
      print('Failed to update user data. Status code: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('build made');
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: Scaffold(
            appBar: AppBar(
              title: Text('Update Profile'),
              centerTitle: true,
            ),
            body: SingleChildScrollView(
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 50),
                        child: selectedImage != null
                            ? CircleAvatar(
                              radius: 70,
                              child: ClipOval(
                                child: Image.file(
                                    selectedImage!,
                                    fit: BoxFit.cover,
                                    height: 200,
                                    width: 200,
                                  ),
                              ),
                            )
                            : CircleAvatar(
                              radius: 70,
                              child: ClipOval(
                                child: Image.network(
                                    "${widget.userData!['avatar']}",
                                    fit: BoxFit.cover,
                                    width: 200,
                                    height: 200,
                                  ),
                              ),
                            )),
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: TextField(
                        controller: usernameController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(90.0),
                          ),
                          labelText: 'Username',
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: TextField(
                        controller: emailController,
                        //obscureText: true,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(90.0),
                          ),
                          labelText: 'Email',
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: GestureDetector(
                        onTap: () => _selectDate(context),
                        child: AbsorbPointer(
                          child: TextField(
                            controller: dobController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(90.0),
                              ),
                              labelText: 'Date of Birth',
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: TextField(
                        controller: mobileController,
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          //FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(90.0),
                          ),
                          labelText: 'Mobile',
                        ),
                      ),
                    ),
                    Visibility(
                      visible: false,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: TextField(
                          controller: profilePictureController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(90.0),
                            ),
                            labelText: 'Profile Image',
                          ),
                        ),
                      ),
                    ),
                    
                    Container(
                      height: 80,
                      padding: const EdgeInsets.all(20),
                      child: ElevatedButton(
                        // style: ElevatedButton.styleFrom(
                        //   minimumSize: const Size.fromHeight(50),
                        // ),
                        child: const Text('Change Image'),
                        onPressed: () async {
                          await _pickImage();
                        },
                      ),
                    ),
                    Container(
                        height: 80,
                        padding: const EdgeInsets.all(20),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                          ),
                          child: const Text('Save Changes'),
                          onPressed: () {
                            updateUserProfile(
                              usernameController.text,
                              emailController.text,
                              dobController.text,
                              mobileController.text,
                              profilePictureController.text,
                            );
                          },
                        )),
                  ],
                ),
              ),
            )));
  }
}

/* void updateUserProfile(String newUsername, String newEmail, String? newDob,
      String newMobile) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (newDob == '') {
      newDob=null;
    }
    String? token = prefs.getString('token');
    int? userId = prefs.getInt('userId');
    //bool? isLoggedIn = prefs.getBool('isLoggedIn');
    final String updateProfileUrl =
        'http://192.168.1.17:8000/api/users/${userId}/';

    final response = await http.patch(
      Uri.parse(updateProfileUrl),
      headers: {
        'Authorization': 'token $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'username': newUsername,
        'email': newEmail,
        'dob': newDob,
        'mobile': newMobile,
        // Add more fields as needed for the update
      }),
    );

    if (response.statusCode == 200) {
      // Update successful
      Map<String, dynamic> updatedUserData = json.decode(response.body);
      print('User data updated: $updatedUserData');

      // Navigate back to UserDetailsPage with updated user data
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              MyHomePage(userId: updatedUserData['id'], token: token, isLoggedIn: true, comingFromProfilePage: true,)
        ),
      );
    } else {
      // Handle update failure
      print('Failed to update user data. Status code: ${response.statusCode}');
    }
  } */