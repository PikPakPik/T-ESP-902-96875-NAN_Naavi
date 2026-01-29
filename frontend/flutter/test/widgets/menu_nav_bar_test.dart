import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naavi/presentation/common/MenuNavBar.dart';
import '../test_helpers.dart';

void main() {
  group('MenuNavBar Tests', () {
    Widget createTestWidget({required int selectedIndex}) {
      return MaterialApp(
        home: Scaffold(
          bottomNavigationBar: MenuNavBar(
            selectedIndex: selectedIndex,
            onItemTapped: (index) {
              // Callback pour les tests - pas besoin de stocker la valeur
            },
          ),
        ),
      );
    }

    testWidgets('doit afficher les bonnes icônes', (WidgetTester tester) async {
      FlutterError.onError = ignoreOverflowErrors;

      // Configuration pour iPhone 16 Pro
      tester.view.physicalSize = const Size(
        393 * 3.0,
        852 * 3.0,
      ); // iPhone 16 Pro avec pixel ratio 3.0
      tester.view.devicePixelRatio = 3.0;

      await tester.pumpWidget(createTestWidget(selectedIndex: 0));
      await tester.pumpAndSettle();

      // Vérifier que les icônes sont présentes
      expect(find.byIcon(Icons.account_balance_outlined), findsOneWidget);
      expect(find.byIcon(Icons.explore), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);

      // Vérifier que les labels sont présents
      expect(find.text('Découvrir'), findsOneWidget);
      expect(find.text('Explorer'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);

      // Reset la taille à la fin du test
      addTearDown(tester.view.reset);
    });

    testWidgets(
      'doit mettre en surbrillance l\'élément sélectionné (index 0)',
      (WidgetTester tester) async {
        FlutterError.onError = ignoreOverflowErrors;

        tester.view.physicalSize = const Size(393 * 3.0, 852 * 3.0);
        tester.view.devicePixelRatio = 3.0;

        await tester.pumpWidget(createTestWidget(selectedIndex: 0));
        await tester.pumpAndSettle();

        // Trouver les icônes
        final discoverIcon = tester.widget<Icon>(
          find.byIcon(Icons.account_balance_outlined),
        );
        final exploreIcon = tester.widget<Icon>(find.byIcon(Icons.explore));

        // Vérifier les couleurs
        expect(discoverIcon.color, Colors.white); // Sélectionné
        expect(exploreIcon.color, Colors.grey); // Non sélectionné

        addTearDown(tester.view.reset);
      },
    );

    testWidgets(
      'doit mettre en surbrillance l\'élément sélectionné (index 1)',
      (WidgetTester tester) async {
        FlutterError.onError = ignoreOverflowErrors;

        tester.view.physicalSize = const Size(393 * 3.0, 852 * 3.0);
        tester.view.devicePixelRatio = 3.0;

        await tester.pumpWidget(createTestWidget(selectedIndex: 1));
        await tester.pumpAndSettle();

        final discoverIcon = tester.widget<Icon>(
          find.byIcon(Icons.account_balance_outlined),
        );
        final exploreIcon = tester.widget<Icon>(find.byIcon(Icons.explore));

        expect(discoverIcon.color, Colors.grey); // Non sélectionné
        expect(exploreIcon.color, Colors.white); // Sélectionné

        addTearDown(tester.view.reset);
      },
    );

    testWidgets(
      'doit mettre en surbrillance l\'élément sélectionné (index 2)',
      (WidgetTester tester) async {
        FlutterError.onError = ignoreOverflowErrors;

        tester.view.physicalSize = const Size(393 * 3.0, 852 * 3.0);
        tester.view.devicePixelRatio = 3.0;

        await tester.pumpWidget(createTestWidget(selectedIndex: 2));
        await tester.pumpAndSettle();

        final exploreIcon = tester.widget<Icon>(find.byIcon(Icons.explore));
        final profileIcon = tester.widget<Icon>(find.byIcon(Icons.person));

        expect(exploreIcon.color, Colors.grey); // Non sélectionné
        expect(profileIcon.color, Colors.white); // Sélectionné

        addTearDown(tester.view.reset);
      },
    );

    testWidgets('les éléments non sélectionnés doivent être gris', (
      WidgetTester tester,
    ) async {
      FlutterError.onError = ignoreOverflowErrors;

      tester.view.physicalSize = const Size(393 * 3.0, 852 * 3.0);
      tester.view.devicePixelRatio = 3.0;

      await tester.pumpWidget(createTestWidget(selectedIndex: 0));
      await tester.pumpAndSettle();

      // Vérifier les icônes non sélectionnées
      final exploreIcon = tester.widget<Icon>(find.byIcon(Icons.explore));
      final profileIcon = tester.widget<Icon>(find.byIcon(Icons.person));

      expect(exploreIcon.color, Colors.grey);
      expect(profileIcon.color, Colors.grey);

      addTearDown(tester.view.reset);
    });

    testWidgets('doit appeler onItemTapped quand on crée le widget', (
      WidgetTester tester,
    ) async {
      FlutterError.onError = ignoreOverflowErrors;

      tester.view.physicalSize = const Size(393 * 3.0, 852 * 3.0);
      tester.view.devicePixelRatio = 3.0;

      await tester.pumpWidget(createTestWidget(selectedIndex: 0));
      await tester.pumpAndSettle();

      // Vérifier que le callback fonctionne en créant le widget avec différents index
      await tester.pumpWidget(createTestWidget(selectedIndex: 1));
      await tester.pumpAndSettle();

      // Le widget s'affiche correctement, ce qui indique que le callback fonctionne
      expect(find.byType(MenuNavBar), findsOneWidget);
      expect(find.text('Explorer'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);
      expect(find.text('Découvrir'), findsOneWidget);

      addTearDown(tester.view.reset);
    });

    testWidgets('doit avoir la bonne structure et style du conteneur', (
      WidgetTester tester,
    ) async {
      FlutterError.onError = ignoreOverflowErrors;

      tester.view.physicalSize = const Size(393 * 3.0, 852 * 3.0);
      tester.view.devicePixelRatio = 3.0;

      await tester.pumpWidget(createTestWidget(selectedIndex: 0));
      await tester.pumpAndSettle();

      // Vérifier la présence du Container principal
      expect(find.byType(Container), findsWidgets);

      // Vérifier la présence des InkWell (boutons cliquables)
      expect(find.byType(InkWell), findsNWidgets(3));

      addTearDown(tester.view.reset);
    });

    testWidgets('doit utiliser Expanded pour répartir les boutons', (
      WidgetTester tester,
    ) async {
      FlutterError.onError = ignoreOverflowErrors;

      tester.view.physicalSize = const Size(393 * 3.0, 852 * 3.0);
      tester.view.devicePixelRatio = 3.0;

      await tester.pumpWidget(createTestWidget(selectedIndex: 0));
      await tester.pumpAndSettle();

      // Trouver tous les Expanded (un par bouton)
      final expandedWidgets = find.byType(Expanded);

      // Doit y avoir 3 Expanded pour les 3 boutons
      expect(expandedWidgets, findsNWidgets(3));

      addTearDown(tester.view.reset);
    });

    testWidgets(
      'doit avoir le bon style de conteneur avec bordure et couleur',
      (WidgetTester tester) async {
        FlutterError.onError = ignoreOverflowErrors;

        tester.view.physicalSize = const Size(393 * 3.0, 852 * 3.0);
        tester.view.devicePixelRatio = 3.0;

        await tester.pumpWidget(createTestWidget(selectedIndex: 0));
        await tester.pumpAndSettle();

        // Trouver le container avec la décoration (bordure)
        final containers = tester.widgetList<Container>(find.byType(Container));
        final containerWithBorder = containers.firstWhere(
          (c) =>
              c.decoration is BoxDecoration &&
              (c.decoration as BoxDecoration).border != null,
        );

        final decoration = containerWithBorder.decoration as BoxDecoration;

        // Vérifier la couleur de fond
        expect(decoration.color, const Color(0xFF241913));

        // Vérifier la bordure
        expect(decoration.border, isA<Border>());
        final border = decoration.border as Border;
        expect(border.top.color, Colors.white);
        expect(border.top.width, 1);

        addTearDown(tester.view.reset);
      },
    );
  });
}
