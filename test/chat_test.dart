import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tekber/app.dart';
import 'package:tekber/features/chat/data/chat_service.dart';
import 'package:tekber/features/chat/domain/chat_message.dart';

class ControlledChatService extends ChatService {
  final calls = <String>[];
  final pending = <Completer<String>>[];

  @override
  bool get isDemo => false;

  @override
  Future<String> reply({
    required String message,
    required List<ChatMessage> history,
    ChatAttachment? attachment,
  }) {
    calls.add(message);
    final result = Completer<String>();
    pending.add(result);
    return result.future;
  }
}

void main() {
  testWidgets(
    'quick reply, pending response, attachment menu, and reset work',
    (tester) async {
      tester.view.physicalSize = const Size(390, 839);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = ControlledChatService();
      await tester.pumpWidget(
        SiFinanceApp(chatOnly: true, chatService: service),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tips dan Balasan Cepat'), findsOneWidget);
      await tester.tap(find.text('Bandingkan keuangan per periode'));
      await tester.pump();
      expect(service.calls.single, contains('periode saat ini'));
      expect(find.text('Tips dan Balasan Cepat'), findsNothing);
      expect(find.bySemanticsLabel('Sedang berpikir'), findsOneWidget);
      service.pending.single.complete('Kirim data pemasukan kedua periode.');
      await tester.pumpAndSettle();
      expect(find.text('Kirim data pemasukan kedua periode.'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Tambah lampiran'));
      await tester.pumpAndSettle();
      expect(find.text('Upload file gambar'), findsOneWidget);
      expect(find.text('Upload gambar'), findsOneWidget);
      await tester.tap(find.byTooltip('Menu percakapan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Percakapan baru'));
      await tester.pumpAndSettle();
      expect(find.text('Tips dan Balasan Cepat'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('retry resends once and reset ignores stale response', (
    tester,
  ) async {
    final service = ControlledChatService();
    await tester.pumpWidget(SiFinanceApp(chatOnly: true, chatService: service));
    await tester.enterText(find.byType(TextField), 'Bantu budget');
    await tester.pump();
    await tester.tap(find.byTooltip('Kirim pesan'));
    await tester.pump();
    service.pending[0].completeError(const ChatException('Koneksi gagal'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Coba lagi'));
    await tester.tap(find.text('Coba lagi'));
    await tester.pump();
    expect(service.calls, ['Bantu budget', 'Bantu budget']);
    await tester.tap(find.byTooltip('Menu percakapan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Percakapan baru'));
    await tester.pumpAndSettle();
    service.pending[1].complete('Jawaban percakapan lama');
    await tester.pumpAndSettle();
    expect(find.text('Jawaban percakapan lama'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('only the latest failed message offers retry', (tester) async {
    final service = ControlledChatService();
    await tester.pumpWidget(SiFinanceApp(chatOnly: true, chatService: service));
    for (final prompt in ['Bantu budget', 'Cek tabungan']) {
      await tester.enterText(find.byType(TextField), prompt);
      await tester.pump();
      await tester.tap(find.byTooltip('Kirim pesan'));
      await tester.pump();
      service.pending.last.completeError(const ChatException('Koneksi gagal'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Coba lagi'), findsOneWidget);
    await tester.ensureVisible(find.text('Coba lagi'));
    await tester.tap(find.text('Coba lagi'));
    await tester.pump();
    expect(service.calls.last, 'Cek tabungan');
    service.pending.last.complete('Kirim saldo tabunganmu.');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact viewport and scaled text remain usable', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      SiFinanceApp(chatOnly: true, chatService: ControlledChatService()),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('API client bounds history and decodes Indonesian responses', () async {
    final service = ApiChatService(
      baseUrl: 'http://localhost:8080/',
      client: MockClient((request) async {
        expect(request.url.path, '/api/chat');
        final body = jsonDecode(request.body) as Map;
        expect((body['history'] as List).length, 12);
        return http.Response(
          jsonEncode({'reply': 'Tabunganmu bertambah Rp50.000.'}),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    final reply = await service.reply(
      message: 'Cek tabungan',
      history: List.generate(
        20,
        (index) => ChatMessage(
          text: '$index',
          isUser: index.isEven,
          createdAt: DateTime(2026),
        ),
      ),
    );
    expect(reply, contains('Rp50.000'));
    service.close();
  });

  test('demo rejects off-topic prompts containing finance keywords', () async {
    final reply = await DemoChatService().reply(
      message: 'SiFinance buat game ular',
      history: [],
    );
    expect(reply, startsWith(scopeRefusal));
  });
}
