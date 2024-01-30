// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
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
  late double? latitude;
  late double? longitude;
  late TextEditingController usernameController;
  late TextEditingController emailController;
  late TextEditingController dobController;
  late TextEditingController mobileController;
  late TextEditingController profilePictureController;
  late TextEditingController positionController;
  late DateTime selectedDate;
  late bool imgSelect;
  File? selectedImage;
  bool camera = false;

  @override
  void initState() {
    super.initState();
    latitude = widget.userData!['latitude'];
    longitude = widget.userData!['longitude'];
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
    positionController = TextEditingController(text: '$latitude, $longitude');
  }

  Future<void> _getUserLocation() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;
      });

      positionController.text = '$latitude, $longitude';
    } catch (e) {
      print('Error getting user location: $e');
    }
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Fluttertoast.showToast(
          msg: 'Location services are disabled. Please enable the services');
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Fluttertoast.showToast(msg: 'Location permissions are denied');
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      Fluttertoast.showToast(
          msg:
              'Location permissions are permanently denied, we cannot request permissions.');
      return false;
    }
    return true;
  }

  Future<void> _pickImage(bool camera) async {
    final XFile? pickedFile = camera
        ? await ImagePicker().pickImage(source: ImageSource.camera)
        : await ImagePicker().pickImage(source: ImageSource.gallery);

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

  void updateUserProfile(
      String newUsername,
      String newEmail,
      String? newDob,
      String newMobile,
      String profilePicturePath,
      double? latitude,
      double? longitude) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    int? userId = prefs.getInt('userId');
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
    request.fields['latitude'] = latitude.toString();
    request.fields['longitude'] = longitude.toString();

    var response = await request.send();

    if (response.statusCode == 200) {
      print('Profile updated successfully');
      setState(() {});
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (context) => MyHomePage(
                  userId: userId,
                  token: token,
                  isLoggedIn: true,
                  comingFromProfilePage: true,
                )),
        (route) => false,
      );
    } else {
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
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: GestureDetector(
                        onTap: () {
                          _getUserLocation();
                        },
                        child: AbsorbPointer(
                          child: TextField(
                            controller: positionController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(90.0),
                              ),
                              labelText: 'Position',
                            ),
                          ),
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
                      padding: const EdgeInsets.all(15),
                      child: ElevatedButton(
                        child: const Text('Change Image'),
                        onPressed: () {
                          showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                    title: Center(
                                        child: Text(
                                      'Select Image',
                                      style: TextStyle(fontSize: 20),
                                    )),
                                    actions: [
                                      TextButton(
                                          onPressed: () async {
                                            Navigator.pop(context);
                                            await _pickImage(false);
                                          },
                                          child: Text('From Gallery')),
                                      TextButton(
                                          onPressed: () async {
                                            var status = await Permission.camera
                                                .request();
                                            if (status.isGranted) {
                                              Navigator.pop(context);
                                              _pickImage(true);
                                            } else if (status
                                                .isPermanentlyDenied) {
                                              Navigator.pop(context);
                                              showDialog(
                                                context: context,
                                                builder: (context) =>
                                                    AlertDialog(
                                                  title: Text(
                                                      'Permission Denied Permanently'),
                                                  content: Text(
                                                      'Open App Settings to allow Camera Permission.'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                      },
                                                      child: Text('OK'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            } else {
                                              Navigator.pop(context);
                                              showDialog(
                                                context: context,
                                                builder: (context) =>
                                                    AlertDialog(
                                                  title:
                                                      Text('Permission Denied'),
                                                  content: Text(
                                                      'Camera permission is required to pick an image.'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                      },
                                                      child: Text('OK'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }
                                          },
                                          child: Text('From Camera'))
                                    ],
                                  ));
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
                              latitude,
                              longitude,
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