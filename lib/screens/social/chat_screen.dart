import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../core/database/database.dart' as db;
import '../../core/services/interaction_service.dart';
import '../../widgets/profile_image.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String otherUserId;
  const ChatScreen({super.key, required this.otherUserId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    ref.read(supabaseServiceProvider).sendMessage(
      receiverId: widget.otherUserId,
      content: text,
    );
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) return const CupertinoPageScaffold(child: SizedBox.shrink());

    final otherProfileAsync = ref.watch(specificUserProfileProvider(widget.otherUserId));
    final messagesAsync = ref.watch(chatMessagesProvider(widget.otherUserId));
    final pendingInteractionAsync = ref.watch(pendingInteractionProvider(widget.otherUserId));

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFFF2F2F7).withValues(alpha: 0.9),
        middle: otherProfileAsync.when(
          data: (p) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ProfileImage(url: p?.avatarUrl, size: 28, isCircle: true),
              const SizedBox(height: 2),
              Text(p?.name ?? 'Chat', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
          loading: () => const Text('Loading...'),
          error: (_, _) => const Text('Chat'),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.back, color: AppColors.emerald700),
              Text('Back', style: TextStyle(color: AppColors.emerald700)),
            ],
          ),
          onPressed: () => context.pop(),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.info, color: AppColors.emerald700),
          onPressed: () {
            // Show info or profile
            context.push('/marketplace/provider/${widget.otherUserId}');
          },
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                // Auto scroll to bottom
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });
                
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final m = messages[index];
                    final isMe = m.senderId == user.id;
                    
                    // Logic to show timestamp only if time difference is significant
                    bool showTimestamp = true;
                    if (index > 0) {
                      final prev = messages[index - 1];
                      if (m.createdAt.difference(prev.createdAt).inMinutes < 15) {
                        showTimestamp = false;
                      }
                    }

                    return Column(
                      children: [
                        if (showTimestamp)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              _formatTimestamp(m.createdAt),
                              style: const TextStyle(color: AppColors.grey400, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                        _ChatBubble(message: m, isMe: isMe),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(child: CupertinoActivityIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
          
          // Booking Confirmation (if any)
          pendingInteractionAsync.when(
            data: (interaction) => interaction != null 
                ? _BookingConfirmationBar(interaction: interaction, otherName: otherProfileAsync.valueOrNull?.name ?? 'Provider')
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),

          _buildInputArea(),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime date) {
    final now = DateTime.now();
    if (now.difference(date).inDays == 0) {
      return 'Today ${DateFormat('h:mm a').format(date)}';
    } else if (now.difference(date).inDays == 1) {
      return 'Yesterday ${DateFormat('h:mm a').format(date)}';
    }
    return DateFormat('MMM d, h:mm a').format(date);
  }

  Widget _buildInputArea() {
    return Material(
      color: Colors.white,
      child: Container(
        padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5E5EA))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.add, color: AppColors.grey500, size: 28),
              onPressed: () {},
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5E5EA)),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: TextField(
                    controller: _messageController,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'iMessage',
                      hintStyle: TextStyle(color: Color(0xFFBCBCC1), fontSize: 16),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.emerald700,
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.arrow_up, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final db.Message message;
  final bool isMe;
  const _ChatBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: isMe ? AppColors.emerald700 : const Color(0xFFE9E9EB),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black, 
            fontSize: 16, 
            fontWeight: FontWeight.w400,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}

class _BookingConfirmationBar extends ConsumerWidget {
  final db.Interaction interaction;
  final String otherName;
  const _BookingConfirmationBar({required this.interaction, required this.otherName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5EA)),
      ),
      child: Column(
        children: [
          Text(
            'Did you book $otherName?',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: -0.3),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  color: AppColors.emerald700,
                  padding: EdgeInsets.zero,
                  borderRadius: BorderRadius.circular(10),
                onPressed: () async {
                    try {
                      // Yes - Create booking via Bridge Service
                      await ref.read(caddieServiceProvider).createBooking(
                        providerId: interaction.providerId,
                        initiatedVia: interaction.type.toUpperCase(),
                        roundType: 'EIGHTEEN_HOLES', // Default
                      );
                      ref.read(interactionServiceProvider).confirmBooking(interaction.id, true);
                    } catch (e) {
                      debugPrint('CHAT: Error creating booking: $e');
                    }
                  },
                  child: const Text('Yes, Booked', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CupertinoButton(
                  color: const Color(0xFFE5E5EA),
                  padding: EdgeInsets.zero,
                  borderRadius: BorderRadius.circular(10),
                  onPressed: () {
                    // "Not Yet" - do nothing, let it stay pending
                  },
                  child: const Text('Not Yet', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.grey700)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CupertinoButton(
                  color: Colors.white,
                  padding: EdgeInsets.zero,
                  borderRadius: BorderRadius.circular(10),
                  onPressed: () {
                    // No - Log Inquiry and mark interaction ignored
                    ref.read(supabaseServiceProvider).createInquiry(
                      providerId: interaction.providerId, 
                      initiatedVia: interaction.type.toUpperCase() == 'CALL' ? 'CALL' : 'CHAT',
                    );
                    ref.read(interactionServiceProvider).ignoreInteraction(interaction.id);
                  },
                  child: const Text('No', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.redAccent)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Chat Providers ────────────────────────────────────────────────────────

final chatMessagesProvider = StreamProvider.family<List<db.Message>, String>((ref, otherId) {
  final database = ref.watch(databaseProvider);
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return database.watchConversation(user.id, otherId);
});

final pendingBookingProvider = StreamProvider.family<db.Booking?, String>((ref, providerId) {
  final database = ref.watch(databaseProvider);
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(null);
  
  return database.watchPlayerBookings(user.id).map((list) {
    return list.where((b) => b.providerId == providerId && b.status == 'PENDING').firstOrNull;
  });
});
