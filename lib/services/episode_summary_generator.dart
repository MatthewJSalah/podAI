import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert'; // For encoding the JSON

class EpisodeSummaryGenerator {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String apiKey = 'your_api_key_here'; // OPEN_API_KEY

  Future<void> addSummariesToEpisodes() async {
    final podcastersQuery = await _firestore.collection('podcasters').get();
    for (var doc in podcastersQuery.docs) {
      final episodesQuery = await doc.reference.collection('episodes').get();
      for (var episodeDoc in episodesQuery.docs) {
        final transcript = episodeDoc.data()['transcript'] as String;
        final summary = await summarizeText(transcript);
        await episodeDoc.reference.update({'summary': summary});
      }
    }
  }

  Future<String> summarizeText(String text) async {
    // Split the text into manageable chunks
    List<String> chunks = splitTextIntoChunks(text, 1000); // Assuming 1000 tokens per chunk

    // Process each chunk to summarize
    List<String> summaries = [];
    for (var chunk in chunks) {
      String summary = await fetchSummaryFromOpenAI(chunk);
      summaries.add(summary);
    }

    // Combine all summaries into a single summary
    return summaries.join(" ");
  }

  Future<String> fetchSummaryFromOpenAI(String text) async {
    final url = Uri.parse('https://api.openai.com/v1/completions');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey'
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'prompt': 'Summarize this transcript: $text',
        'max_tokens': 150,
      }),
    );

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      return responseBody['choices'][0]['text'];
    } else {
      throw Exception('Failed to fetch summary: ${response.body}');
    }
  }

  List<String> splitTextIntoChunks(String text, int chunkSize) {
    List<String> chunks = [];
    int index = 0;
    while (index < text.length) {
      int endIndex = index + chunkSize < text.length ? index + chunkSize : text.length;
      chunks.add(text.substring(index, endIndex));
      index += chunkSize;
    }
    return chunks;
  }
}
