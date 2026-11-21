import 'dart:math' as math;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../voice_logging/presentation/voice_logging_page.dart';
import '../data/chat_service.dart';
import '../domain/chat_message.dart';
import 'chat_widgets.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.service});
  final ChatService service;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();
  final _messages = <ChatMessage>[];
  ChatAttachment? _attachment;
  bool _menuOpen = false;
  bool _sending = false;
  bool _picking = false;
  int _generation = 0;
  ChatMessage? _failedMessage;

  @override
  void initState() {
    super.initState();
    _messages.add(_greeting());
    _focus.addListener(_onFocus);
    _recoverCamera();
  }

  ChatMessage _greeting() => ChatMessage(
    text: 'Halo, ada yang bisa saya bantu?',
    isUser: false,
    createdAt: DateTime.now(),
  );

  void _onFocus() {
    if (_focus.hasFocus && _menuOpen) setState(() => _menuOpen = false);
  }

  Future<void> _recoverCamera() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final result = await ImagePicker().retrieveLostData();
      if (result.files?.isNotEmpty ?? false) {
        await _acceptFile(result.files!.first);
      }
    } catch (_) {
      // The next picker interaction reports any permission issue to the user.
    }
  }

  Future<void> _pick({required bool camera}) async {
    if (_picking) return;
    setState(() {
      _menuOpen = false;
      _picking = true;
    });
    _focus.unfocus();
    try {
      final file = camera
          ? await ImagePicker().pickImage(
              source: ImageSource.camera,
              maxWidth: 1600,
              maxHeight: 1600,
              imageQuality: 85,
            )
          : await openFile(
              acceptedTypeGroups: [
                const XTypeGroup(
                  label: 'Gambar transaksi',
                  extensions: ['jpg', 'jpeg', 'png', 'webp'],
                  mimeTypes: ['image/jpeg', 'image/png', 'image/webp'],
                  uniformTypeIdentifiers: [
                    'public.jpeg',
                    'public.png',
                    'org.webmproject.webp',
                  ],
                ),
              ],
            );
      if (file != null) await _acceptFile(file);
    } catch (_) {
      if (mounted) {
        _notice(
          camera
              ? 'Kamera belum tersedia atau izin ditolak. Gunakan Upload file gambar.'
              : 'Gambar belum dapat dibuka. Silakan coba lagi.',
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _acceptFile(XFile file) async {
    if (await file.length() > 4 * 1024 * 1024) {
      if (mounted) _notice('Ukuran gambar maksimal 4 MB.');
      return;
    }
    final bytes = await file.readAsBytes();
    final mime = switch (bytes) {
      [0xFF, 0xD8, 0xFF, ...] => 'image/jpeg',
      [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, ...] => 'image/png',
      [0x52, 0x49, 0x46, 0x46, _, _, _, _, 0x57, 0x45, 0x42, 0x50, ...] =>
        'image/webp',
      _ => null,
    };
    if (!mounted) return;
    if (mime == null) {
      _notice('Gunakan gambar JPG, PNG, atau WebP.');
      return;
    }
    setState(
      () => _attachment = ChatAttachment(
        name: file.name,
        mimeType: mime,
        bytes: bytes,
      ),
    );
  }

  void _notice(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _send([String? prompt]) async {
    if (_sending) return;
    final text = (prompt ?? _text.text).trim();
    if (text.isEmpty && _attachment == null) return;
    if (text.length > 4000) {
      _notice('Pesan maksimal 4.000 karakter.');
      return;
    }
    final message = ChatMessage(
      text: text.isEmpty ? 'Bantu analisis transaksi pada gambar ini.' : text,
      isUser: true,
      createdAt: DateTime.now(),
      attachment: _attachment,
    );
    final history = List<ChatMessage>.of(_messages.skip(1));
    _text.clear();
    _focus.unfocus();
    setState(() {
      _messages.add(message);
      _attachment = null;
      _menuOpen = false;
      _sending = true;
      _failedMessage = null;
    });
    _scrollToEnd();
    await _request(message, history);
  }

  Future<void> _request(ChatMessage message, List<ChatMessage> history) async {
    final generation = _generation;
    try {
      final reply = await widget.service.reply(
        message: message.text,
        history: history,
        attachment: message.attachment,
      );
      if (!mounted || generation != _generation) return;
      setState(
        () => _messages.add(
          ChatMessage(text: reply, isUser: false, createdAt: DateTime.now()),
        ),
      );
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _failedMessage = message;
        _messages.add(
          ChatMessage(
            text: error is ChatException
                ? error.message
                : 'Terjadi kendala. Silakan coba lagi.',
            isUser: false,
            createdAt: DateTime.now(),
            isError: true,
          ),
        );
      });
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _sending = false);
        _scrollToEnd();
      }
    }
  }

  void _retry() {
    final message = _failedMessage;
    if (_sending || message == null) return;
    setState(() {
      _messages.removeLast();
      _sending = true;
      _failedMessage = null;
    });
    _request(message, _messages.skip(1).take(_messages.length - 2).toList());
  }

  void _scrollToEnd() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  });

  void _reset() {
    _generation++;
    _text.clear();
    setState(() {
      _messages
        ..clear()
        ..add(_greeting());
      _attachment = null;
      _menuOpen = false;
      _failedMessage = null;
      _sending = false;
    });
  }

  void _about() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('AI Chat SiFinance'),
      content: Text(
        widget.service.isDemo
            ? 'Mode demo aktif dengan balasan contoh. Hubungkan API_BASE_URL ke backend '
                  'untuk memakai model AI. Chat hanya tersimpan selama halaman terbuka.'
            : 'Asisten khusus SiFinance dan keuangan. Model memeriksa topik pertanyaan '
                  'dan jawaban. Data akun belum terhubung. Kirim angka atau gambar transaksi '
                  'untuk dianalisis. Pesan dan lampiran dikirim ke Gemini melalui backend.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Mengerti'),
        ),
      ],
    ),
  );

  @override
  void dispose() {
    _generation++;
    _text.dispose();
    _scroll.dispose();
    _focus.dispose();
    widget.service.close();
    super.dispose();
  }

  void _openVoiceLogging() {
    _focus.unfocus();
    Navigator.of(
      context,
    ).push<void>(MaterialPageRoute(builder: (_) => const VoiceLoggingPage()));
  }

  Widget _composerAction() {
    if (_sending) {
      return Semantics(
        label: 'Sedang berpikir',
        liveRegion: true,
        excludeSemantics: true,
        child: const SizedBox(
          width: 36,
          height: 40,
          child: Center(
            child: Text('•••', style: TextStyle(color: chatBlue)),
          ),
        ),
      );
    }
    if (_text.text.trim().isEmpty && _attachment == null) {
      return IconButton(
        tooltip: 'Buka Voice Logging',
        onPressed: _openVoiceLogging,
        icon: const Icon(Icons.mic_none, color: chatInk, size: 20),
      );
    }
    return IconButton(
      tooltip: 'Kirim pesan',
      onPressed: () => _send(),
      icon: const Icon(Icons.arrow_upward, color: chatBlue, size: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ColoredBox(
            color: Colors.white,
            child: Column(
              children: [
                if (kIsWeb)
                  const DesignStatusBar()
                else
                  SizedBox(height: MediaQuery.paddingOf(context).top),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: SizedBox(
                    height: 30,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: 24,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              tooltip: 'Kembali',
                              onPressed: () {
                                if (Navigator.of(context).canPop()) {
                                  Navigator.of(context).pop();
                                } else {
                                  _openVoiceLogging();
                                }
                              },
                              icon: const DesignIcon('arrow-left'),
                            ),
                          ),
                        ),
                        const Text(
                          'AI Chat',
                          style: TextStyle(
                            fontSize: 20,
                            height: 1.5,
                            fontWeight: FontWeight.bold,
                            color: chatInk,
                          ),
                        ),
                        Positioned(
                          right: 12,
                          top: 0,
                          bottom: 0,
                          child: PopupMenuButton<String>(
                            tooltip: 'Menu percakapan',
                            padding: EdgeInsets.zero,
                            icon: const DesignIcon('more'),
                            onSelected: (value) =>
                                value == 'reset' ? _reset() : _about(),
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'reset',
                                child: Text('Percakapan baru'),
                              ),
                              PopupMenuItem(
                                value: 'about',
                                child: Text('Tentang AI Chat'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) => Stack(
                      children: [
                        ListView.separated(
                          controller: _scroll,
                          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                          itemCount: _messages.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 33.5),
                          itemBuilder: (_, index) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MessageBubble(message: _messages[index]),
                              if (_messages[index].isError &&
                                  index == _messages.length - 1 &&
                                  _failedMessage != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 52),
                                  child: TextButton(
                                    onPressed: _retry,
                                    child: const Text('Coba lagi'),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (_messages.length == 1 &&
                            !keyboardOpen &&
                            constraints.maxHeight > 430)
                          Positioned(
                            right: 24,
                            bottom: 25,
                            child: SizedBox(
                              width: math.min(
                                248,
                                math.max(0, constraints.maxWidth - 48),
                              ),
                              child: QuickReplies(onSelected: _send),
                            ),
                          ),
                        if (_menuOpen) ...[
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => setState(() => _menuOpen = false),
                            ),
                          ),
                          Positioned(
                            left: 40,
                            bottom: 0,
                            child: AttachmentMenu(
                              onFile: () => _pick(camera: false),
                              onCamera: () => _pick(camera: true),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (_attachment case final attachment?)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(72, 0, 24, 8),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.memory(
                            attachment.bytes,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                const Icon(Icons.broken_image_outlined),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            attachment.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _attachment = null),
                          tooltip: 'Hapus lampiran',
                          icon: const Icon(Icons.close, size: 18),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    0,
                    24,
                    keyboardOpen
                        ? 12
                        : math.max(
                            44,
                            MediaQuery.paddingOf(context).bottom + 12,
                          ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: Material(
                          color: chatBlue,
                          borderRadius: BorderRadius.circular(6),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: _picking
                                ? null
                                : () {
                                    _focus.unfocus();
                                    setState(() => _menuOpen = !_menuOpen);
                                  },
                            child: Semantics(
                              button: true,
                              label: 'Tambah lampiran',
                              child: const Center(child: DesignIcon('plus')),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _text,
                          focusNode: _focus,
                          minLines: 1,
                          maxLines: 4,
                          maxLength: 4000,
                          textInputAction: TextInputAction.send,
                          onSubmitted: _sending ? null : (_) => _send(),
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: chatInk,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Tanyakan apa saja',
                            counterText: '',
                            isDense: true,
                            hintStyle: const TextStyle(
                              color: Color(0xFF525863),
                              fontSize: 12,
                            ),
                            filled: true,
                            fillColor: chatGray,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 11,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: _composerAction(),
                            suffixIconConstraints: const BoxConstraints(
                              minHeight: 40,
                              minWidth: 36,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
