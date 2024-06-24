import 'dart:math';
import 'package:aipod/Widgets/cards/podcast_card_widget.dart';
import 'package:aipod/pages/podcaster_episodes_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TrendingPodcasts extends StatelessWidget {
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
        final trendingPodcasters = podcasters..shuffle();
        return Container(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: min(trendingPodcasters.length, 4),
            itemBuilder: (context, index) {
              final podcaster =
                  trendingPodcasters[index].data() as Map<String, dynamic>;
              final podcasterId = trendingPodcasters[index].id;
              podcaster['id'] = podcasterId; // Add the id to the podcaster map
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PodcasterEpisodesPage(podcaster: podcaster),
                    ),
                  );
                },
                child: FutureBuilder<int>(
                  future: getEpisodeCount(podcasterId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return PodcastCard(
                        title: podcaster['name'],
                        episodeCount: 0,
                        imageUrl: podcaster['imageUrl'] ??
                            'https://via.placeholder.com/300x200?text=Placeholder',
                      );
                    } else {
                      return PodcastCard(
                        title: podcaster['name'],
                        episodeCount: snapshot.data ?? 0,
                        imageUrl: podcaster['imageUrl'] ??
                            'https://via.placeholder.com/300x200?text=Placeholder',
                      );
                    }
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<int> getEpisodeCount(String podcasterId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('podcasters')
        .doc(podcasterId)
        .get();
    final episodeIds = snapshot.data()?['episodeIds'] as List<dynamic>?;
    return episodeIds?.length ?? 0;
  }
}
