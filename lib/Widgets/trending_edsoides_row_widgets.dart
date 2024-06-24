
import 'package:aipod/Widgets/cards/episode_card_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TrendingEpisodes extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('podcasters').snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        final podcasters = snapshot.data!.docs;
        podcasters.shuffle(); // Randomize podcasters

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: getRandomEpisodes(podcasters),
          builder: (context, episodeSnapshot) {
            if (episodeSnapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            }
            if (episodeSnapshot.hasError) {
              return Text('Error: ${episodeSnapshot.error}');
            }

            final episodes = episodeSnapshot.data!;
            return Container(
              height: 240,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: episodes.length,
                itemBuilder: (context, index) {
                  final episode = episodes[index];
                  return EpisodeCard(
                    title: episode['title'],
                    transcript: episode['transcript'],
                    podcasterName: episode['podcasterName'],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> getRandomEpisodes(
      List<QueryDocumentSnapshot> podcasters) async {
    final List<Map<String, dynamic>> episodes = [];
    final Set<String> addedPodcasters = {}; // To keep track of added podcasters

    for (var podcaster in podcasters) {
      final podcasterData = podcaster.data() as Map<String, dynamic>;
      final podcasterId = podcaster.id;
      final podcasterName = podcasterData['name'];

      final episodesSnapshot = await FirebaseFirestore.instance
          .collection('podcasters')
          .doc(podcasterId)
          .collection('episodes')
          .get();

      final podcasterEpisodes = episodesSnapshot.docs;
      podcasterEpisodes.shuffle(); // Randomize episodes
      final selectedEpisodes =
          podcasterEpisodes.take(1).toList(); // Take 1 episode

      for (var episode in selectedEpisodes) {
        if (!addedPodcasters.contains(podcasterId)) {
          final episodeData = episode.data() as Map<String, dynamic>;
          episodeData['podcasterName'] =
              podcasterName; // Add podcaster name to episode data
          episodes.add(episodeData);
          addedPodcasters.add(podcasterId); // Mark this podcaster as added

          if (episodes.length >= 10) {
            return episodes;
          }
        }
      }
    }

    return episodes;
  }
}