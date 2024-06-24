import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as htmlParser;
import 'package:cloud_firestore/cloud_firestore.dart';

class WebScraping extends StatefulWidget {
  @override
  _WebScrapingState createState() => _WebScrapingState();
}

class _WebScrapingState extends State<WebScraping> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true; // State variable to control loading state

  @override
  void initState() {
    super.initState();
    fetchDataAndSaveToFirestore();
  }

  Future<void> fetchDataAndSaveToFirestore() async {
    try {
      // Fetch podcasters s
      final podcasters = await fetchPodcasters();

      // Iterate through each podcaster and fetch episodes and transcripts
      for (var podcaster in podcasters) {
        final episodes = await fetchEpisodes(podcaster['link']!);
        for (var episode in episodes) {
          final transcript = await fetchTranscript(episode['link']!);
          // Save podcaster, episode, and transcript to Firestore
          await saveDataToFirestore(podcaster, episode, transcript);
        }
      }

      print('Data fetched and saved successfully!');
    } catch (error) {
      print('Error: $error');
    } finally {
      // Update the state to indicate loading is finished
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> fetchPodcasters() async {
    List<Map<String, dynamic>> podcasters = [];
    try {
      for (int page = 1; page <= 33; page++) {
        final url =
            Uri.parse('https://www.happyscribe.com/public/podcasts?page=$page');
        final response = await http.get(url);

        if (response.statusCode == 200) {
          final document = htmlParser.parse(response.body);
          final podcasterElements =
              document.querySelectorAll('.hsp-card-podcast');

          final podcastersList = podcasterElements
              .map((element) {
                final link = element.attributes['href'];
                final title = element.querySelector('h3')?.text.trim();
                if (link != null && title != null) {
                  final podcasterUrl = 'https://www.happyscribe.com$link';
                  return fetchPodcasterDetails(podcasterUrl);
                }
                return null;
              })
              .where((podcaster) => podcaster != null)
              .toList();

          podcasters.addAll(await Future.wait(
              List<Future<Map<String, dynamic>>>.from(podcastersList)));
        } else {
          print('Failed to load podcasters from page $page');
        }
      }
    } catch (error) {
      print('Error fetching podcasters: $error');
    }
    return podcasters;
  }

  Future<Map<String, dynamic>> fetchPodcasterDetails(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final document = htmlParser.parse(response.body);
        final titleElement = document.querySelector('header h1');
        final title = titleElement?.text.trim();

        final descriptionElement = document.querySelector('#description p');
        final description = descriptionElement?.text.trim();

        // Fetch the image in the second header tag
        final headerElements = document.querySelectorAll('header');
        final imageElement = headerElements.length > 1
            ? headerElements[1].querySelector('img')
            : null;
        final imageUrl = imageElement?.attributes['src'];

        return {
          'link': url,
          'name': title,
          'imageUrl': imageUrl,
          'description': description,
          'episodeIds': [],
        };
      } else {
        print('Failed to fetch podcaster details for $url');
        return {};
      }
    } catch (error) {
      print('Error fetching podcaster details: $error');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> fetchEpisodes(String podcasterUrl) async {
    List<Map<String, dynamic>> episodes = [];
    try {
      for (int page = 1; page <= 11; page++) {
        final url = Uri.parse('$podcasterUrl?page=$page');
        final response = await http.get(url);

        if (response.statusCode == 200) {
          final document = htmlParser.parse(response.body);
          final episodeElements =
              document.querySelectorAll('.hsp-card-episode');

          final episodesList = episodeElements
              .map((element) {
                final link = element.attributes['href'];
                final title = element.querySelector('h3')?.text.trim();
                if (link != null && title != null) {
                  return {
                    'link': 'https://www.happyscribe.com$link',
                    'title': title,
                  };
                }
                return null;
              })
              .where((episode) => episode != null)
              .toList();

          episodes.addAll(List<Map<String, dynamic>>.from(episodesList));
        } else {
          print('Failed to load episodes from page $page');
        }
      }
    } catch (error) {
      print('Error fetching episodes: $error');
    }
    return episodes;
  }

  Future<String> fetchTranscript(String episodeUrl) async {
    try {
      final response = await http.get(Uri.parse(episodeUrl));
      if (response.statusCode == 200) {
        final document = htmlParser.parse(response.body);
        final transcriptElements =
            document.querySelectorAll('.hsp-transcript p');
        final transcript = transcriptElements.map((p) => p.text).join('\n\n');
        return transcript;
      } else {
        throw Exception('Failed to fetch transcript for episode: $episodeUrl');
      }
    } catch (error) {
      print('Error fetching transcript: $error');
      return '';
    }
  }

  Future<void> saveDataToFirestore(Map<String, dynamic> podcaster,
      Map<String, dynamic> episode, String transcript) async {
    try {
      // Check if podcaster already exists
      final existingPodcaster = await _firestore
          .collection('podcasters')
          .where('name', isEqualTo: podcaster['name'])
          .get();

      DocumentReference podcasterRef;

      if (existingPodcaster.docs.isNotEmpty) {
        // Update existing podcaster
        podcasterRef = existingPodcaster.docs.first.reference;
        await podcasterRef.update({
          'imageUrl': podcaster['imageUrl'],
          'description': podcaster['description'],
        });
      } else {
        // Add new podcaster
        podcasterRef = await _firestore.collection('podcasters').add({
          'name': podcaster['name'],
          'imageUrl': podcaster['imageUrl'],
          'description': podcaster['description'],
        });
      }

      // Check if the episode title already exists for this podcaster
      final existingEpisode = await podcasterRef
          .collection('episodes')
          .where('title', isEqualTo: episode['title'])
          .get();

      if (existingEpisode.docs.isEmpty) {
        // Add episode and transcript
        final episodeRef = await podcasterRef.collection('episodes').add({
          'title': episode['title'],
          'transcript': transcript,
        });

        // Update episode IDs array
        await podcasterRef.update({
          'episodeIds': FieldValue.arrayUnion([episodeRef.id]),
        });
      } else {
        print(
            'Episode "${episode['title']}" already exists for this podcaster.');
      }
    } catch (error) {
      print('Error saving data to Firestore: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fetching and Saving Data'),
      ),
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator()
            : Text('Data fetched and saved successfully!'),
      ),
    );
  }
}
