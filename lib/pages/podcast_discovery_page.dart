import 'package:aipod/Widgets/cards/podcast_card_widget.dart';
import 'package:aipod/Widgets/trending_edsoides_row_widgets.dart';
import 'package:aipod/Widgets/trending_podcast_widget.dart';
import 'package:aipod/pages/podcaster_episodes_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PodcastDiscoveryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Discover Podcasts'),
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: AnimationLimiter(
            child: Column(
              children: AnimationConfiguration.toStaggeredList(
                duration: const Duration(milliseconds: 800),
                childAnimationBuilder: (widget) => SlideAnimation(
                  horizontalOffset: 50.0,
                  child: FadeInAnimation(
                    child: widget,
                    delay: Duration(milliseconds: 200),
                  ),
                ),
                children: <Widget>[
                  Text(
                    'Trending Podcasts',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  TrendingPodcasts(),
                  SizedBox(height: 20),
                  Text(
                    'Trending Episodes',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  TrendingEpisodes(),
                  SizedBox(height: 40),
                  Text(
                    'Recommended for You',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  RecommendedPodcasts(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RecommendedPodcasts extends StatelessWidget {
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
        final recommendedPodcasters = podcasters
            .where((podcaster) => podcasters.indexOf(podcaster) > 3)
            .toList()
          ..sort((a, b) => (b['episodeIds'] as List)
              .length
              .compareTo((a['episodeIds'] as List).length));

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          children: List.generate(
            recommendedPodcasters.length,
            (index) {
              final podcaster =
                  recommendedPodcasters[index].data() as Map<String, dynamic>;
              final podcasterId = recommendedPodcasters[index].id;
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
