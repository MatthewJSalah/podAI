import 'dart:math';
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

class PodcastCard extends StatelessWidget {
  final String title;
  final int episodeCount;
  final String imageUrl;

  PodcastCard({
    required this.title,
    required this.episodeCount,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    print('Loading image from URL: $imageUrl'); // Log the image URL
    return SizedBox(
      width: 300,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                imageUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              (loadingProgress.expectedTotalBytes ?? 1)
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'assets/podcast_logo.jpg',
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    '$episodeCount Episodes',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EpisodeCard extends StatelessWidget {
  final String title;
  final String transcript;
  final String podcasterName;

  EpisodeCard({
    required this.title,
    required this.transcript,
    required this.podcasterName,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Card(
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
                'by $podcasterName',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
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
      ),
    );
  }
}
