import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';

class AdminDocumentsScreen extends ConsumerStatefulWidget {
  const AdminDocumentsScreen({super.key});

  @override
  ConsumerState<AdminDocumentsScreen> createState() => _AdminDocumentsScreenState();
}

class _AdminDocumentsScreenState extends ConsumerState<AdminDocumentsScreen> {
  static const Color _navy = Color(0xFF002B9A);
  static const Color _sky = Color(0xFFCDE8FF);
  static const Color _pageBg = Color(0xFFF4F6F9);
  static const Color _labelGrey = Color(0xFF6B7280);
  static const Color _completeGreen = Color(0xFF1B8A4A);
  static const Color _alertRed = Color(0xFFE53935);

  String _filterStatus = 'ALL';
  final List<String> _statusFilters = ['ALL', 'PENDING', 'PROCESSING', 'COMPLETED'];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final uid = ref.watch(currentUserUidProvider);
    final userAsync = ref.watch(userDetailsProvider(uid ?? ""));

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _navy,
        elevation: 0,
        title: const Text(
          'Documents',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null || user.ngoid.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open_outlined, size: 80, color: _navy),
                  const SizedBox(height: 16),
                  Text(
                    'No NGO assigned',
                    style: textTheme.titleLarge?.copyWith(color: _navy),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please set up your NGO first',
                    style: textTheme.bodyMedium?.copyWith(color: _labelGrey),
                  ),
                ],
              ),
            );
          }

          final ngoid = user.ngoid.first;
          final documentsAsync = ref.watch(ngoDocumentsProvider(ngoid));

          return documentsAsync.when(
            data: (documents) {
              if (documents == null || documents.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.description_outlined, size: 80, color: _labelGrey),
                      const SizedBox(height: 16),
                      Text(
                        'No documents uploaded',
                        style: textTheme.titleLarge?.copyWith(color: _navy),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Volunteers haven\'t uploaded any documents yet',
                        style: textTheme.bodyMedium?.copyWith(color: _labelGrey),
                      ),
                    ],
                  ),
                );
              }

              // Filter documents based on status
              final filteredDocs = _filterStatus == 'ALL'
                  ? documents
                  : documents
                      .where((doc) => (doc['status'] ?? '').toString() == _filterStatus)
                      .toList();

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Filter Chips
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _statusFilters.length,
                          itemBuilder: (context, index) {
                            final status = _statusFilters[index];
                            final isSelected = _filterStatus == status;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(status),
                                selected: isSelected,
                                onSelected: (_) {
                                  setState(() => _filterStatus = status);
                                },
                                backgroundColor: Colors.white,
                                selectedColor: _sky,
                                labelStyle: TextStyle(
                                  color: isSelected ? _navy : _labelGrey,
                                  fontWeight:
                                      isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                side: BorderSide(
                                  color: isSelected ? _navy : _labelGrey,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Documents Count
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Documents: ${filteredDocs.length}',
                            style: textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _navy,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Documents List
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          final doc = filteredDocs[index];
                          return _buildDocumentCard(doc, textTheme);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stackTrace) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 80, color: _alertRed),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading documents',
                    style: textTheme.titleLarge?.copyWith(color: _navy),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: textTheme.bodyMedium?.copyWith(color: _labelGrey),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> doc, TextTheme textTheme) {
    final fileName = _extractFileName(doc['file_url'] ?? '');
    final fileType = _getFileType(fileName);
    final status = doc['status'] ?? 'UNKNOWN';
    final userId = doc['user_id'] ?? 'Unknown';
    final createdAt = doc['created_at'] ?? 'Unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Icon, Name, and Status Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // File Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getFileIconColor(fileType).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getFileIcon(fileType),
                    color: _getFileIconColor(fileType),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // File Name and Type
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName,
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _navy,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fileType,
                        style: textTheme.labelSmall?.copyWith(
                          color: _labelGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getStatusColor(status),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    status,
                    style: textTheme.labelSmall?.copyWith(
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Meta Information
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Uploaded by',
                        style: textTheme.labelSmall?.copyWith(
                          color: _labelGrey,
                        ),
                      ),
                      Text(
                        userId,
                        style: textTheme.bodySmall?.copyWith(
                          color: _navy,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Uploaded at',
                        style: textTheme.labelSmall?.copyWith(
                          color: _labelGrey,
                        ),
                      ),
                      Text(
                        createdAt.toString(),
                        style: textTheme.bodySmall?.copyWith(
                          color: _navy,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // ML Result (if available)
            if (doc['ml_result'] != null && (doc['ml_result'] as String).isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ML Result',
                    style: textTheme.labelSmall?.copyWith(
                      color: _labelGrey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _sky.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      (doc['ml_result'] as String).length > 150
                          ? '${(doc['ml_result'] as String).substring(0, 150)}...'
                          : doc['ml_result'] as String,
                      style: textTheme.bodySmall?.copyWith(
                        color: _navy,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _viewDocument(doc['file_url'] ?? ''),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('View'),
                  style: TextButton.styleFrom(
                    foregroundColor: _navy,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _downloadDocument(doc['file_url'] ?? '', fileName),
                  icon: const Icon(Icons.download),
                  label: const Text('Download'),
                  style: TextButton.styleFrom(
                    foregroundColor: _completeGreen,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _extractFileName(String url) {
    try {
      return url.split('/').last.split('?').first;
    } catch (e) {
      return 'document';
    }
  }

  String _getFileType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    if (ext == 'pdf') return 'PDF Document';
    if (['jpg', 'jpeg', 'png', 'gif'].contains(ext)) return 'Image';
    return ext.toUpperCase();
  }

  IconData _getFileIcon(String fileType) {
    if (fileType.contains('PDF')) return Icons.picture_as_pdf;
    if (fileType.contains('Image')) return Icons.image_outlined;
    return Icons.description_outlined;
  }

  Color _getFileIconColor(String fileType) {
    if (fileType.contains('PDF')) return _alertRed;
    if (fileType.contains('Image')) return const Color(0xFF4CAF50);
    return _navy;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return const Color(0xFFFFA500);
      case 'PROCESSING':
        return const Color(0xFF2196F3);
      case 'COMPLETED':
        return _completeGreen;
      default:
        return _labelGrey;
    }
  }

  Future<void> _viewDocument(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.inAppWebView);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _downloadDocument(String url, String fileName) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.inAppWebView);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
