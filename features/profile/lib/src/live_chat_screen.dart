import 'package:flutter/material.dart';
import 'customer_profile_strings.dart';
import 'package:design_system/design_system.dart';
import 'support_hero_header.dart';
import 'support_scaffold.dart';

class LiveChatScreen extends StatefulWidget {
  const LiveChatScreen({super.key});

  @override
  State<LiveChatScreen> createState() => _LiveChatScreenState();
}

class _LiveChatScreenState extends State<LiveChatScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _hasText = false;
  late final List<_ChatMessage> _messages;
  late final List<String> _quickReplies;

  @override
  void initState() {
    super.initState();
    _messages = [
      _ChatMessage(
        text: CustomerProfileStrings.chatWelcome1,
        isAgent: true,
        time: '10:00 AM',
      ),
      _ChatMessage(
        text: CustomerProfileStrings.chatWelcome2,
        isAgent: true,
        time: '10:00 AM',
      ),
    ];
    _quickReplies = [
      CustomerProfileStrings.chatQuick1,
      CustomerProfileStrings.chatQuick2,
      CustomerProfileStrings.chatQuick3,
      CustomerProfileStrings.chatQuick4,
    ];
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(
        _ChatMessage(text: text.trim(), isAgent: false, time: _timeNow()),
      );
      _input.clear();
      _hasText = false;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
    Future.delayed(const Duration(seconds: 1, milliseconds: 200), () {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatMessage(
            text: CustomerProfileStrings.chatAgentReply,
            isAgent: true,
            time: '',
          ),
        );
      });
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!mounted) return;
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    });
  }

  String _timeNow() {
    final now = DateTime.now();
    final h = now.hour;
    final m = now.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h % 12 == 0 ? 12 : h % 12;
    return '$hour12:$m $period';
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    // Use MediaQuery.padding directly so the header can still bleed full-width
    // while the scrollable content and input bar stay within safe bounds.
    final safe = MediaQuery.of(context).padding;

    return SupportScaffold(
      appBarColor: AppColors.primary,
      centerTitle: !isLandscape,
      titleWidget: isLandscape
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _AgentAvatar(borderColor: AppColors.primary),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      CustomerProfileStrings.chatAgentShort,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      CustomerProfileStrings.chatOnline,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Text(
              CustomerProfileStrings.helpLiveChat,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert_rounded, color: AppColors.white),
          onPressed: () {},
        ),
      ],
      body: Column(
        children: [
          // Portrait-only hero header — in landscape it's replaced by the AppBar row
          if (!isLandscape)
            SupportHeroHeader(
              icon: Icons.chat_bubble_outline_rounded,
              gradientColors: const [
                AppColors.headerGradientStart,
                AppColors.headerGradientEnd,
              ],
              title: CustomerProfileStrings.chatAgentName,
              subtitle: CustomerProfileStrings.chatSubtitle,
              badge: CustomerProfileStrings.chatOnline,
              badgeColor: AppColors.success,
              bottomChild: Row(
                children: [
                  _AgentAvatar(borderColor: AppColors.headerGradientEnd),
                  const SizedBox(width: 10),
                  Text(
                    CustomerProfileStrings.chatAgentFullName,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // Messages list — uses MediaQuery safe insets for left/right
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: EdgeInsets.fromLTRB(
                safe.left + 16,
                16,
                safe.right + 16,
                12,
              ),
              children: [
                ..._messages.map((m) => _BubbleTile(message: m)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _quickReplies
                      .map(
                        (r) => GestureDetector(
                          onTap: () => _sendMessage(r),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              r,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),

          // Input bar — MediaQuery handles bottom and left/right notch
          Container(
            color: AppColors.white,
            padding: EdgeInsets.fromLTRB(
              safe.left + 8,
              8,
              safe.right + 8,
              safe.bottom + 8,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.attach_file_rounded,
                    color: AppColors.gray400,
                  ),
                  onPressed: () {},
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.field,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _input,
                      onChanged: (v) =>
                          setState(() => _hasText = v.trim().isNotEmpty),
                      textInputAction: TextInputAction.send,
                      onSubmitted: _sendMessage,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.ink,
                      ),
                      decoration: InputDecoration(
                        hintText: CustomerProfileStrings.chatInputHint,
                        hintStyle: const TextStyle(
                          color: AppColors.gray400,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 11,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _hasText ? AppColors.primary : AppColors.gray200,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.send_rounded,
                      color: _hasText ? AppColors.white : AppColors.gray400,
                      size: 18,
                    ),
                    onPressed: _hasText
                        ? () => _sendMessage(_input.text)
                        : null,
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

// ── Agent avatar with online dot ──────────────────────────────────────────────

class _AgentAvatar extends StatelessWidget {
  const _AgentAvatar({required this.borderColor});
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.white.withValues(alpha: 0.22),
          child: const Icon(
            Icons.support_agent_rounded,
            color: AppColors.white,
            size: 18,
          ),
        ),
        Positioned(
          bottom: 0,
          right: -1,
          child: Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Chat message model ────────────────────────────────────────────────────────

class _ChatMessage {
  final String text;
  final bool isAgent;
  final String time;

  const _ChatMessage({
    required this.text,
    required this.isAgent,
    required this.time,
  });
}

// ── Chat bubble ───────────────────────────────────────────────────────────────

class _BubbleTile extends StatelessWidget {
  const _BubbleTile({required this.message});
  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isAgent = message.isAgent;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isAgent
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isAgent) ...[
            const CircleAvatar(
              radius: 13,
              backgroundColor: AppColors.primaryLight,
              child: Icon(
                Icons.support_agent_rounded,
                size: 14,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isAgent
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: isAgent ? AppColors.white : AppColors.primary,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isAgent ? 4 : 16),
                      bottomRight: Radius.circular(isAgent ? 16 : 4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: isAgent ? AppColors.ink : AppColors.white,
                      height: 1.4,
                    ),
                  ),
                ),
                if (message.time.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      message.time,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
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
