import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:labeltruth_app/main.dart';
import 'package:labeltruth_app/screens/home_screen.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('LabelTruthApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: LabelTruthApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify HomeScreen is rendered
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text("Recent Food Audits"), findsOneWidget);
    expect(find.text("Audit Packaging"), findsOneWidget);
  });
}
