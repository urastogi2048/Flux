import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flux_app/services/taskgenerationservice.dart';

class NewsResultsScreen extends ConsumerStatefulWidget {
  final String state;

  const NewsResultsScreen({
    super.key,
    required this.state,
  });

  @override
  ConsumerState<NewsResultsScreen> createState() => _NewsResultsScreenState();
}

class _NewsResultsScreenState extends ConsumerState<NewsResultsScreen> {
  static const Color _navy = Color(0xFF002B9A);
  static const Color _sky = Color(0xFFCDE8FF);
  static const Color _completeGreen = Color(0xFF1B8A4A);
  static const Color _alertRed = Color(0xFFE53935);
  static const Color _labelGrey = Color(0xFF6B7280);

  late Future<dynamic> _newsFuture;

  @override
  void initState() {
    super.initState();
    _newsFuture = _fetchNews();
  }

  Future<dynamic> _fetchNews() async {
    final service = TaskGenerationService();
    return await service.getNewsByState(state: widget.state);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        title: Text('News - ${widget.state}'),
        elevation: 0,
      ),
      body: FutureBuilder<dynamic>(
        future: _newsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: _navy),
                  SizedBox(height: 16),
                  Text(
                    'Fetching news...',
                    style: TextStyle(
                      fontSize: 16,
                      color: _navy,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: _alertRed, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Error fetching news',
                    style: TextStyle(
                      fontSize: 16,
                      color: _alertRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _newsFuture = _fetchNews();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _navy,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, color: _navy, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'No news found',
                    style: TextStyle(
                      fontSize: 16,
                      color: _navy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }

          final newsData = snapshot.data;
          List<dynamic> articles = [];

          print('📰 NEWS DATA TYPE: ${newsData.runtimeType}');
          print('📰 NEWS DATA: $newsData');

          // Handle different response formats
          if (newsData is List) {
            articles = newsData;
          } else if (newsData is Map) {
            // Check for nested data structure
            if (newsData.containsKey('data')) {
              final dataField = newsData['data'];
              if (dataField is Map && dataField.containsKey('alerts')) {
                // Structure: {"data": {"alerts": [...]}}
                articles = dataField['alerts'] ?? [];
              } else if (dataField is List) {
                articles = dataField;
              }
            } else if (newsData.containsKey('alerts')) {
              // Direct alerts field
              articles = newsData['alerts'] ?? [];
            } else if (newsData.containsKey('articles')) {
              articles = newsData['articles'] ?? [];
            } else if (newsData.containsKey('news')) {
              articles = newsData['news'] ?? [];
            } else {
              // Last resort: use map values
              articles = newsData.values.toList();
            }
          }

          print('📰 ARTICLES COUNT: ${articles.length}');
          if (articles.isNotEmpty) {
            print('📰 FIRST ARTICLE: ${articles[0]}');
          }

          if (articles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.newspaper_outlined, color: _labelGrey, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'No articles found',
                    style: TextStyle(
                      fontSize: 16,
                      color: _labelGrey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: articles.length,
            itemBuilder: (context, index) {
              final article = articles[index];
              return _buildNewsCard(article);
            },
          );
        },
      ),
    );
  }

  Widget _buildNewsCard(dynamic article) {
    String title = '';
    String url = '';
    String priority = '';
    String category = '';

    if (article is Map) {
      title = article['title']?.toString() ?? 'Untitled';
      url = article['url']?.toString() ?? '';
      priority = article['priority']?.toString() ?? 'MEDIUM';
      category = article['category']?.toString() ?? 'General';

      print('📰 Parsed - Title: $title, Priority: $priority, Category: $category');
    } else if (article is String) {
      title = article;
      priority = 'MEDIUM';
      category = 'News';
    }

    // Color code by priority
    Color priorityColor = const Color(0xFFFF9800);
    if (priority.toUpperCase() == 'HIGH') {
      priorityColor = _alertRed;
    } else if (priority.toUpperCase() == 'LOW') {
      priorityColor = _completeGreen;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _sky,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: priorityColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _navy,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: priorityColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Priority: $priority',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _navy,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                if (url.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        print('🔗 Raw URL from API: "$url"');
                        print('🔗 URL isEmpty: ${url.isEmpty}');
                        print('🔗 URL length: ${url.length}');
                        
                        if (url.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No URL available for this article'),
                              backgroundColor: _alertRed,
                            ),
                          );
                          return;
                        }
                        
                        // Ensure URL has a scheme
                        String linkToOpen = url.trim();
                        if (!linkToOpen.startsWith('http://') && !linkToOpen.startsWith('https://')) {
                          linkToOpen = 'https://$linkToOpen';
                          print('🔗 Added https:// scheme');
                        }
                        
                        print('🔗 Final URL to launch: "$linkToOpen"');
                        
                        try {
                          final Uri uri = Uri.parse(linkToOpen);
                          print('🔗 URI parsed successfully: ${uri.toString()}');
                          
                          final canLaunch = await canLaunchUrl(uri);
                          print('🔗 canLaunchUrl result: $canLaunch');
                          
                          if (canLaunch) {
                            print('🔗 Launching URL...');
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          } else {
                            print('🔗 Device cannot launch this URL scheme');
                            // Try inAppWebView as fallback
                            print('🔗 Trying inAppWebView mode...');
                            await launchUrl(uri, mode: LaunchMode.inAppWebView);
                          }
                        } catch (e) {
                          print('🔗 Exception: $e');
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString()}'),
                                backgroundColor: _alertRed,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.link, size: 16),
                      label: const Text('View Source'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _navy,
                        side: const BorderSide(color: _navy),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
