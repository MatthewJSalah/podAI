import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class PodcasterEpisodesPage extends StatelessWidget {
  final Map<String, dynamic> podcaster;

  PodcasterEpisodesPage({required this.podcaster});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(podcaster['name']),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('podcasters')
              .doc(podcaster['id'])
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData || snapshot.data!.data() == null) {
              return Center(child: Text('No data available'));
            }

            final podcasterData = snapshot.data!.data() as Map<String, dynamic>;
            final episodeIds = podcasterData['episodeIds'] as List<dynamic>;

            return AnimationLimiter(
              child: ListView.builder(
                itemCount: episodeIds.length,
                itemBuilder: (context, index) {
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 800),
                    child: SlideAnimation(
                      horizontalOffset: 50.0,
                      child: FadeInAnimation(
                        child: FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('podcasters')
                              .doc(podcaster['id'])
                              .collection('episodes')
                              .doc(episodeIds[index])
                              .get(),
                          builder: (context, episodeSnapshot) {
                            if (episodeSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }
                            if (episodeSnapshot.hasError) {
                              return Center(
                                  child:
                                      Text('Error: ${episodeSnapshot.error}'));
                            }

                            if (!episodeSnapshot.hasData ||
                                episodeSnapshot.data!.data() == null) {
                              return Center(
                                  child: Text('No episode data available'));
                            }

                            final episodeData = episodeSnapshot.data!.data()
                                as Map<String, dynamic>;

                            return PodcastEpisodeCard(
                              title: episodeData['title'],
                              transcript: episodeData['transcript'],
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class PodcastEpisodeCard extends StatelessWidget {
  final String title;
  final String transcript;

  PodcastEpisodeCard({
    required this.title,
    required this.transcript,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 20),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              transcript,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 8),
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(title),
                    content: SingleChildScrollView(
                      child: Text(transcript),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Close'),
                      ),
                    ],
                  ),
                );
              },
              child: Text('Read More'),
            ),
          ],
        ),
      ),
    );
  }
}
