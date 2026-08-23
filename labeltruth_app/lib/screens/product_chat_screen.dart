import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../models/scan_result.dart';
import '../providers/settings_provider.dart';
import '../services/api_service.dart';

class ChatBubbleMessage {
  final String role; // "user" or "assistant"
  final String text;
  final DateTime timestamp;

  ChatBubbleMessage({
    required this.role,
    required this.text,
    required this.timestamp,
  });
}

class ProductChatScreen extends ConsumerStatefulWidget {
  final ScanResult scanResult;

  const ProductChatScreen({super.key, required this.scanResult});

  @override
  ConsumerState<ProductChatScreen> createState() => _ProductChatScreenState();
}

class _ProductChatScreenState extends ConsumerState<ProductChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatBubbleMessage> _messages = [];
  bool _isSending = false;

  final List<String> _suggestedPrompts = [
    "Is this safe for daily consumption?",
    "Why is Palmolein or Saturated Fat harmful?",
    "Explain the FSSAI statutory violations",
    "Is this suitable for diabetics or kids?",
    "What are 100% clean alternatives?",
  ];

  @override
  void initState() {
    super.initState();
    // Add initial greeting from LabelTruth AI
    final p = widget.scanResult;
    final violationsCount = p.violations.length;
    final introText = "Hello! I am your **LabelTruth AI Food Safety Auditor**.\n\n"
        "I have reviewed **${p.brandName} - ${p.productName}**.\n"
        "• **Truth Score**: ${p.truthScore}/100 (${p.verdict})\n"
        "• **Violations Found**: $violationsCount statutory issue(s)\n\n"
        "Ask me anything about its ingredients, hidden chemicals, Indian FSSAI laws, or dietary safety!";

    _messages.add(ChatBubbleMessage(
      role: "assistant",
      text: introText,
      timestamp: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty || _isSending) return;

    _controller.clear();
    setState(() {
      _messages.add(ChatBubbleMessage(
        role: "user",
        text: cleanText,
        timestamp: DateTime.now(),
      ));
      _isSending = true;
    });
    _scrollToBottom();

    try {
      final settings = ref.read(settingsProvider);
      final apiService = ApiService(customBaseUrl: settings.backendUrl);

      final p = widget.scanResult;
      final historyPayload = _messages
          .map((m) => {"role": m.role, "content": m.text})
          .toList();

      final reply = await apiService.askProductChat(
        productName: p.productName,
        brandName: p.brandName,
        truthScore: p.truthScore,
        verdict: p.verdict,
        marketingClaims: p.marketingClaims,
        ingredientsText: p.ingredients.map((i) => i.name).join(", "),
        nutrition: p.nutritionPer100g.toJson(),
        violations: p.violations.map((v) => v.toJson()).toList(),
        userQuestion: cleanText,
        chatHistory: historyPayload,
      );

      if (mounted) {
        setState(() {
          _messages.add(ChatBubbleMessage(
            role: "assistant",
            text: reply,
            timestamp: DateTime.now(),
          ));
          _isSending = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatBubbleMessage(
            role: "assistant",
            text: "⚠️ **Connection Error**: Unable to reach AI auditor. Please ensure the backend is active.",
            timestamp: DateTime.now(),
          ));
          _isSending = false;
        });
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.scanResult;
    final scoreColor = AppColors.getScoreColor(p.truthScore);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Ask Food Safety AI",
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              "${p.brandName} • ${p.productName}",
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMutedDark),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: scoreColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: scoreColor.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, color: scoreColor, size: 14),
                const SizedBox(width: 4),
                Text(
                  "${p.truthScore}/100",
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: scoreColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat message stream
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg.role == "user";

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.85,
                    ),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isUser
                          ? AppColors.accent
                          : AppColors.surfaceCardDark,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16),
                      ),
                      border: Border.all(
                        color: isUser
                            ? Colors.transparent
                            : AppColors.surfaceLightDark,
                        width: 0.8,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isUser) ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.auto_awesome, color: AppColors.accent, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                "LabelTruth AI Auditor",
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                        ],
                        Text(
                          msg.text,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Typing indicator
          if (_isSending)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "AI Auditor is analyzing product data...",
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMutedDark),
                  ),
                ],
              ),
            ),

          // Quick Prompt Chips
          Container(
            height: 42,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _suggestedPrompts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final prompt = _suggestedPrompts[index];
                return ActionChip(
                  label: Text(
                    prompt,
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.accent),
                  ),
                  backgroundColor: AppColors.surfaceCardDark,
                  side: const BorderSide(color: AppColors.surfaceLightDark),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onPressed: () => _sendMessage(prompt),
                );
              },
            ),
          ),

          // Bottom Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              border: const Border(top: BorderSide(color: AppColors.surfaceLightDark, width: 0.8)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: "Ask about ingredients, safety, FSSAI rules...",
                        hintStyle: GoogleFonts.inter(color: AppColors.textMutedDark, fontSize: 12),
                        filled: true,
                        fillColor: AppColors.surfaceCardDark,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 10),
                  CircleAvatar(
                    backgroundColor: AppColors.accent,
                    radius: 22,
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      onPressed: () => _sendMessage(_controller.text),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
