import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../domain/chat_message.dart';

const chatBlue = Color(0xFF004CFF);
const chatGray = Color(0xFFE7E8EA);
const chatInk = Color(0xFF101828);

class DesignIcon extends StatelessWidget {
  const DesignIcon(this.name, {super.key});
  final String name;

  @override
  Widget build(BuildContext context) =>
      SvgPicture.asset('assets/icons/$name.svg');
}

class DesignStatusBar extends StatelessWidget {
  const DesignStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 44,
      child: Stack(
        children: [
          Positioned(left: 40, top: 15, child: DesignIcon('time')),
          Positioned(
            right: 21,
            top: 16,
            child: Row(
              spacing: 4,
              children: [
                DesignIcon('signal'),
                DesignIcon('wifi'),
                DesignIcon('battery'),
              ],
            ),
          ),
          Positioned(right: 78, top: 8, child: DesignIcon('indicator')),
        ],
      ),
    );
  }
}

class AiAvatar extends StatelessWidget {
  const AiAvatar({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 41,
    height: 41,
    child: Stack(
      children: [
        DesignIcon('ai-background'),
        Positioned(left: 11.1, top: 10, child: DesignIcon('ai')),
      ],
    ),
  );
}

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final user = message.isUser;
    final time = message.createdAt;
    final timeLabel =
        '${time.hour.toString().padLeft(2, '0')}.'
        '${time.minute.toString().padLeft(2, '0')}';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: user ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!user) ...[const AiAvatar(), const SizedBox(width: 11)],
        Flexible(
          child: Padding(
            padding: EdgeInsets.only(top: user ? 9.5 : 14),
            child: Container(
              width: !user && message.text.length > 110 ? 280 : 198,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: user ? chatBlue : chatGray,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(user ? 10 : 0),
                  topRight: Radius.circular(user ? 0 : 10),
                  bottomLeft: const Radius.circular(10),
                  bottomRight: const Radius.circular(10),
                ),
              ),
              child: DefaultTextStyle(
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  height: 1.5,
                  color: user ? const Color(0xFFFCFCFC) : chatInk,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (message.attachment case final attachment?) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.memory(
                          attachment.bytes,
                          height: 128,
                          fit: BoxFit.cover,
                          semanticLabel: 'Gambar transaksi terlampir',
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    SelectableText(
                      message.text,
                      textAlign: user ? TextAlign.right : TextAlign.left,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      timeLabel,
                      textAlign: user ? TextAlign.left : TextAlign.right,
                      style: const TextStyle(fontSize: 8, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (user) ...[
          const SizedBox(width: 10.5),
          ClipOval(
            child: Image.asset(
              'assets/images/avatar.png',
              width: 41,
              height: 41,
              fit: BoxFit.cover,
              semanticLabel: 'Avatar pengguna contoh',
            ),
          ),
        ],
      ],
    );
  }
}

const quickReplies = [
  (
    icon: 'file-chart',
    label: 'Bandingkan keuangan per periode',
    prompt:
        'Bandingkan keuangan saya antara periode saat ini dengan sebelumnya',
  ),
  (
    icon: 'pie-chart',
    label: 'Cek keuangan per kategori',
    prompt: 'Cek keuangan per kategori',
  ),
  (
    icon: 'bar-chart',
    label: 'Simulasi rencana keuangan',
    prompt: 'Simulasi rencana keuangan',
  ),
  (
    icon: 'wallet',
    label: 'Minta rekomendasi budget',
    prompt: 'Minta rekomendasi budget',
  ),
];

class QuickReplies extends StatelessWidget {
  const QuickReplies({super.key, required this.onSelected});
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 248,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: chatBlue,
            borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tips dan Balasan Cepat',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFCFCFC),
                ),
              ),
              Text(
                'mulai percakapan dengan ketuk kolom text atau gunakan balasan cepat berikut:',
                style: TextStyle(
                  fontSize: 10,
                  height: 1.5,
                  color: Color(0xFFFCFCFC),
                ),
              ),
            ],
          ),
        ),
        for (final item in quickReplies)
          Material(
            color: const Color(0xFFFCFCFC),
            shape: Border.all(color: chatGray),
            child: InkWell(
              onTap: () => onSelected(item.prompt),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 7, 10),
                child: Row(
                  spacing: 6,
                  children: [
                    DesignIcon(item.icon),
                    Expanded(
                      child: Text(
                        item.label,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: chatInk,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class AttachmentMenu extends StatelessWidget {
  const AttachmentMenu({
    super.key,
    required this.onFile,
    required this.onCamera,
  });
  final VoidCallback onFile;
  final VoidCallback onCamera;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFFCFCFC),
    elevation: 2,
    shadowColor: Colors.black26,
    borderRadius: BorderRadius.circular(10),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _item('paperclip', 'Upload file gambar', onFile),
          _item('camera', 'Upload gambar', onCamera),
        ],
      ),
    ),
  );

  Widget _item(String icon, String label, VoidCallback onTap) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          DesignIcon(icon),
          Text(label, style: const TextStyle(fontSize: 12, color: chatInk)),
        ],
      ),
    ),
  );
}
