import 'package:aipod/services/data_page.dart';
import 'package:flutter/material.dart';
import 'package:aipod/pages/podcast_discovery_page.dart';

class AIHomePage extends StatefulWidget {
  @override
  _AIHomePageState createState() => _AIHomePageState();
}

class _AIHomePageState extends State<AIHomePage> with TickerProviderStateMixin {
  late AnimationController _imageController;
  late Animation<double> _imageAnimation;

  late AnimationController _textController;
  late Animation<double> _textAnimation;

  late AnimationController _buttonController;
  late Animation<double> _buttonAnimation;

  @override
  void initState() {
    super.initState();

    _imageController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _imageAnimation = Tween<double>(begin: 0, end: 1).animate(_imageController);

    _textController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _textAnimation = Tween<double>(begin: 0, end: 1).animate(_textController);

    _buttonController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _buttonAnimation =
        Tween<double>(begin: 0, end: 1).animate(_buttonController);

    _imageController.forward().then((_) {
      _textController.forward().then((_) {
        _buttonController.forward();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Podcast Discovery'),
        backgroundColor: Colors.indigo, // Change app bar color to indigo
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FadeTransition(
              opacity: _imageAnimation,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/podcast_logo.jpg',
                    width: 175,
                    height: 175,
                    fit: BoxFit.cover, // Ensure the logo fits the box perfectly
                  ),
                ),
              ),
            ),
            SizedBox(height: 40),
            FadeTransition(
              opacity: _textAnimation,
              child: Text(
                'Welcome to AI Podcast Discovery',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo, // Change text color to indigo
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 40),
            FadeTransition(
                opacity: _buttonAnimation,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PodcastDiscoveryPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.indigo, // Change button color to indigo
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'Discover Podcasts',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                    ),
                  ),
                )),
            SizedBox(height: 20),
            FadeTransition(
              opacity: _buttonAnimation,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WebScraping(),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.indigo,
                  textStyle: TextStyle(
                    fontSize: 16,
                  ),
                ),
                child: Text('Seed-Database'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _imageController.dispose();
    _textController.dispose();
    _buttonController.dispose();
    super.dispose();
  }
}
