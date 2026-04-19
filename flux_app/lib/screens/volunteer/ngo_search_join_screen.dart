import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../models/ngomodel.dart';
import '../volunteer/volunteerlanding.dart';

class NGOSearchJoinScreen extends ConsumerStatefulWidget {
  final String volunteerUid;

  const NGOSearchJoinScreen({super.key, required this.volunteerUid});

  @override
  ConsumerState<NGOSearchJoinScreen> createState() => _NGOSearchJoinScreenState();
}

class _NGOSearchJoinScreenState extends ConsumerState<NGOSearchJoinScreen> {
  final _searchCtrl = TextEditingController();
  late FirebaseFirestore _firestore;
  
  static const Color _navy = Color(0xFF002B9A);
  static const Color _sky = Color(0xFFCDE8FF);
  static const Color _pageBg = Color(0xFFF4F6F9);
  static const Color _labelGrey = Color(0xFF6B7280);
  static const Color _completeGreen = Color(0xFF1B8A4A);

  List<Map<String, dynamic>> _allNGOs = [];
  List<Map<String, dynamic>> _filteredNGOs = [];
  List<String> _joinedNGOIds = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    _fetchNGOs();
  }

  Future<void> _fetchNGOs() async {
    try {
      // Fetch all active NGOs
      final snapshot = await _firestore
          .collection('ngos')
          .where('isActive', isEqualTo: true)
          .get();

      // Fetch user's joined NGOs
      final userDoc = await _firestore.collection('users').doc(widget.volunteerUid).get();
      final userNgoid = List<String>.from(userDoc.data()?['ngoid'] ?? []);

      setState(() {
        _allNGOs = snapshot.docs.map((doc) => doc.data()).toList();
        _joinedNGOIds = userNgoid;
        _filteredNGOs = _allNGOs;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching NGOs: $e");
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading NGOs: $e')),
        );
      }
    }
  }

  void _filterNGOs(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredNGOs = _allNGOs;
      } else {
        _filteredNGOs = _allNGOs
            .where((ngo) => (ngo['name'] ?? '').toLowerCase().contains(_searchQuery))
            .toList();
      }
    });
  }

  Future<void> _joinNGO(String ngoid) async {
    try {
      final authService = ref.read(authServiceProvider);
      final success = await authService.assignVolunteerToNGO(
        volunteerUid: widget.volunteerUid,
        ngoid: ngoid,
      );

      if (success) {
        setState(() {
          _joinedNGOIds.add(ngoid);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Successfully joined NGO!')),
          );

          // Refresh user details and navigate
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => VolunteerLanding(selectedNGOId: ngoid),
              ),
              (route) => false,
            );
          }
        }
      }
    } catch (e) {
      print("Error joining NGO: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error joining NGO: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _navy,
        title: const Text(
          'Join an NGO',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchCtrl,
                    onChanged: _filterNGOs,
                    decoration: InputDecoration(
                      hintText: 'Search NGO by name...',
                      hintStyle: const TextStyle(color: _labelGrey),
                      prefixIcon: const Icon(Icons.search, color: _navy),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtrl.clear();
                                _filterNGOs('');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _sky),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Already Joined Section
                  if (_joinedNGOIds.isNotEmpty) ...[
                    Text(
                      'My NGOs (${_joinedNGOIds.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _navy,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._allNGOs
                        .where((ngo) => _joinedNGOIds.contains(ngo['ngoid']))
                        .map((ngo) => _buildNGOCard(ngo, isJoined: true))
                        .toList(),
                    const SizedBox(height: 24),
                  ],

                  // Available NGOs Section
                  Text(
                    'Available NGOs',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _navy,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_filteredNGOs.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          _searchQuery.isEmpty
                              ? 'No NGOs available'
                              : 'No NGOs found matching "$_searchQuery"',
                          style: const TextStyle(color: _labelGrey),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    ..._filteredNGOs
                        .where((ngo) => !_joinedNGOIds.contains(ngo['ngoid']))
                        .map((ngo) => _buildNGOCard(ngo, isJoined: false))
                        .toList(),
                ],
              ),
            ),
    );
  }

  Widget _buildNGOCard(Map<String, dynamic> ngo, {required bool isJoined}) {
    return GestureDetector(
      onTap: isJoined
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      VolunteerLanding(selectedNGOId: ngo['ngoid']),
                ),
              );
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: isJoined ? _completeGreen : _sky),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ngo['name'] ?? 'Unknown NGO',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _navy,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ngo['ngotype'] ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: _labelGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isJoined)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _completeGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Joined',
                        style: TextStyle(
                          color: _completeGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                ngo['description'] ?? 'No description',
                style: const TextStyle(
                  fontSize: 13,
                  color: _labelGrey,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (!isJoined) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _navy,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () => _joinNGO(ngo['ngoid']),
                    child: const Text(
                      'Join NGO',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
}
