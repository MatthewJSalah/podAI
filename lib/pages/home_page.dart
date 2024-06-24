import 'package:flutter/material.dart';
import 'package:aipod/constants.dart';
import 'package:aipod/services/podcast_data_scraper.dart';
import 'package:aipod/pages/podcast_discovery_page.dart';
import 'package:aipod/services/episode_summary_generator.dart'; // Import the summary generator service

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

  // Instance of the EpisodeSummaryGenerator
  final EpisodeSummaryGenerator _summaryGenerator = EpisodeSummaryGenerator();

  @override
  void initState() {
    super.initState();

    _imageController = AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _imageAnimation = Tween<double>(begin: 0, end: 1).animate(_imageController);

    _textController = AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _textAnimation = Tween<double>(begin: 0, end: 1).animate(_textController);

    _buttonController = AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _buttonAnimation = Tween<double>(begin: 0, end: 1).animate(_buttonController);

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
        title: Text('AI Podcast Discovery', style: fontStyle),
        backgroundColor: Colors.indigo,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FadeTransition(
              opacity: _imageAnimation,
              child: Container(
                decoration: boxStyle,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/podcast_logo.jpg',
                    width: 175,
                    height: 175,
                    fit: BoxFit.cover,
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
                  color: Colors.indigo,
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
                  backgroundColor: Colors.indigo,
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
              ),
            ),
            SizedBox(height: 20),
            FadeTransition(
              opacity: _buttonAnimation,
              child: TextButton(
                onPressed: _generateEpisodeSummaries,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.indigo,
                  textStyle: TextStyle(
                    fontSize: 16,
                  ),
                ),
                child: Text('Generate Summaries'),
              ),
            ),
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

  void _generateEpisodeSummaries() async {
    try {
      await _summaryGenerator.addSummariesToEpisodes();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Summaries generated successfully!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to generate summaries: $e')));
    }
  }

  @override
  void dispose() {
    _imageController.dispose();
    _textController.dispose();
    _buttonController.dispose();
    super.dispose();
  }
}
