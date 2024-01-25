import 'package:flutter/material.dart';
import 'package:flutter_project_1/login.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:animate_do/animate_do.dart';

class IntroductionPage extends StatefulWidget {
  final bool isLoggedIn;
  IntroductionPage({required this.isLoggedIn});
  @override
  _IntroductionPageState createState() => _IntroductionPageState();
}

class _IntroductionPageState extends State<IntroductionPage> {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;

  final List<Widget> _pages = [
    IntroductionScreen(
      title: 'Welcome to Our App',
      description: 'Discover amazing features.',
      image: 'assets/images/welcome-back.png', // Replace with your image asset
    ),
    IntroductionScreen(
      title: 'Easy to Use',
      description: 'Simple and intuitive interface.',
      image: 'assets/images/easy.png', // Replace with your image asset
    ),
    IntroductionScreen(
      title: 'Get Started',
      description: 'Start exploring now!',
      image: 'assets/images/start-button.png', // Replace with your image asset
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        PageView.builder(
          controller: _pageController,
          itemCount: _pages.length,
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
            });
          },
          itemBuilder: (context, index) {
            return _pages[index];
          },
        ),
        Positioned(
          bottom: 20.0,
          left: 0.0,
          right: 0.0,
          child: Column(
            children: [
              DotsIndicator(
                dotsCount: _pages.length,
                position: _currentPage.toDouble(),
                decorator: DotsDecorator(
                  size: const Size.square(8.0),
                  activeSize: const Size(16.0, 8.0),
                  activeColor: Colors.indigo,
                  color: Colors.grey,
                  spacing: const EdgeInsets.symmetric(horizontal: 4.0),
                  activeShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                ),
              ),
              _currentPage == _pages.length - 1
                    ? FadeInUp(
                        duration: Duration(milliseconds: 400),
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => LoginPage(isLoggedIn: widget.isLoggedIn,), // Replace with your main screen
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.0),
                              child: Text(
                                'Get Started',
                                style: TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    : SizedBox(height: 16.0),
            ],
          ),
        ),
      ]),
      // bottomSheet: _currentPage == _pages.length - 1
      //     ? ElevatedButton(
      //         onPressed: () {
      //           Navigator.of(context).pushReplacement(
      //             MaterialPageRoute(
      //               builder: (context) => LoginPage(
      //                 isLoggedIn: widget.isLoggedIn,
      //               ), // Replace with your main screen
      //             ),
      //           );
      //         },
      //         style: ElevatedButton.styleFrom(
      //           backgroundColor: Colors.indigo, // Customize the button color
      //           shape: RoundedRectangleBorder(
      //             borderRadius:
      //                 BorderRadius.circular(30.0), // Customize the button shape
      //           ),
      //         ),
      //         child: Padding(
      //           padding: EdgeInsets.symmetric(vertical: 12.0),
      //           child: Text(
      //             'Get Started',
      //             style: TextStyle(
      //               fontSize: 18.0,
      //               fontWeight: FontWeight.bold,
      //               color: Colors.white, // Customize the text color
      //             ),
      //           ),
      //         ),
      //       )
      //     : null,
    );
  }
}

class IntroductionScreen extends StatelessWidget {
  final String title;
  final String description;
  final String image;

  IntroductionScreen({
    required this.title,
    required this.description,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            image,
            height: 200,
          ),
          SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
