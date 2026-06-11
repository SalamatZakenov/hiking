import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../tracking/providers/tracking_provider.dart';

class CommentsSheet extends StatefulWidget {
  final String trackId;
  const CommentsSheet({super.key, required this.trackId});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> _comments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    final provider = Provider.of<TrackingProvider>(context, listen: false);
    final comments = await provider.getComments(widget.trackId);
    if (mounted) {
      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    }
  }

  Future<void> _sendComment() async {
    if (_controller.text.trim().isEmpty) return;
    final text = _controller.text.trim();
    _controller.clear();
    FocusScope.of(context).unfocus();

    final provider = Provider.of<TrackingProvider>(context, listen: false);
    await provider.addComment(widget.trackId, text);
    _loadComments();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Comments', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const Divider(color: Colors.white10, height: 1),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF))) // Изменен цвет
                : _comments.isEmpty
                ? const Center(child: Text('No comments yet. Be the first!', style: TextStyle(color: Colors.white54)))
                : ListView.builder(
              itemCount: _comments.length,
              itemBuilder: (context, index) {
                final comment = _comments[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF00E5FF).withOpacity(0.2), // Изменен цвет
                    child: Text(comment['username'][0].toUpperCase(), style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)), // Изменен цвет
                  ),
                  title: Text(comment['username'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(comment['text'], style: const TextStyle(color: Colors.white70)),
                );
              },
            ),
          ),

          Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 8),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sendComment,
                    icon: const Icon(Icons.send_rounded, color: Color(0xFF00E5FF)), // Изменен цвет
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}