import 'package:flutter/material.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/widgets/footer.dart';
import 'package:mobile/widgets/header.dart';

class VerifiedPostsScreen extends StatefulWidget {
  const VerifiedPostsScreen({super.key, required List<Map<String, dynamic>> posts});

  @override
  _VerifiedPostsScreenState createState() => _VerifiedPostsScreenState();
}

class _VerifiedPostsScreenState extends State<VerifiedPostsScreen> {
  int _currentIndex = 0;
  List<Map<String, dynamic>> posts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  Future<void> fetchPosts() async {
    try {
      final List<Map<String, dynamic>> fetchedPosts =
          await ApiService.fetchVerifiedPosts();
      setState(() {
        posts = fetchedPosts;
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching verified posts: $error');
    }
  }

  void _navigateTo(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100.0),
        child: Padding(
          padding: const EdgeInsets.only(top: 25.0),
          child: const Header(),
        ),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : posts.isEmpty
                ? const Center(child: Text('No verified posts available'))
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Verified Posts',
                                style: const TextStyle(
                                  fontSize: 35,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2B3674),
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                height: 4,
                                width: 150,
                                color: const Color(0xFFFC7753),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: posts.length,
                          itemBuilder: (context, index) {
                            final post = posts[index];
                            return PostCard(post: post);
                          },
                        ),
                      ],
                    ),
                  ),
      ),
      bottomNavigationBar: Footer(
        currentIndex: _currentIndex,
        onTap: _navigateTo,
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  final Map<String, dynamic> post;

  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(25.0),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(25.0),
                child: _buildImage(post),
              ),
              const SizedBox(height: 16),
              
              // Title/Heading
              if (post['title'] != null)
                Text(
                  post['title'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2B3674),
                  ),
                ),
              const SizedBox(height: 12),
              
              // Body
              if (post['body'] != null)
                Text(
                  post['body'],
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF2B3674),
                  ),
                ),
              const SizedBox(height: 12),
              
              // Time/Date
              if (post['date'] != null) ...[
                const Text(
                  'Date Posted',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2B3674),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  post['date'],
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF2B3674),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              
              // Location (Latitude and Longitude)
              if (post['location'] != null) ...[
                const Text(
                  'Location',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2B3674),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  post['location'],
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF2B3674),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              
              // Type
              if (post['type'] != null) ...[
                const Text(
                  'Type',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2B3674),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${post['type']}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF2B3674),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              
              // Source
              if (post['source'] != null) ...[
                const Text(
                  'Source',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2B3674),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${post['source']}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF2B3674),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(Map<String, dynamic> post) {
    if (post['image'] != null) {
      return Image.memory(
        post['image'],
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 200,
          width: double.infinity,
          color: Colors.grey[300],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.broken_image,
                size: 50,
                color: Colors.grey,
              ),
              const SizedBox(height: 10),
              Text(
                'Error loading image',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.grey[300],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.image_not_supported,
            size: 50,
            color: Colors.grey,
          ),
          const SizedBox(height: 10),
          Text(
            'No Image Available',
            style: TextStyle(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}