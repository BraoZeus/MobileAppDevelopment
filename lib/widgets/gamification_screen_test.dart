import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:study_well/providers/profile_provider.dart';
import 'package:study_well/models/user_profile_model.dart';
import 'package:study_well/screens/gamification_screen.dart';

class MockProfileProvider extends Mock implements ProfileProvider {}

void main() {
  testWidgets('GamificationScreen renders avatar and badges correctly', (WidgetTester tester) async {
    // 1. Arrange: Setup Mock Provider
    final mockProfileProvider = MockProfileProvider();
    
    // Create a mock user profile at Level 2 (Explorer) with 150 XP
    final mockProfile = UserProfile(
      displayName: 'Test User',
      avatarEmoji: '🤓',
      xp: 150, 
    );
    
    when(() => mockProfileProvider.profile).thenReturn(mockProfile);

    // 2. Act: Pump the Widget
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ProfileProvider>.value(value: mockProfileProvider),
        ],
        child: const MaterialApp(
          home: GamificationScreen(),
        ),
      ),
    );

    // 3. Assert: Check for expected widgets
    // Ensure the avatar is displayed
    expect(find.text('🤓'), findsOneWidget);
    
    // Ensure the current rank (Explorer) is displayed in the main header
    expect(find.text('Explorer'), findsWidgets);
    
    // Check if the XP text is rendered
    expect(find.text('150 XP'), findsWidgets);
    
    // Ensure the "Buddy Levels" list is rendered by looking for the Legend title
    expect(find.text('Legend'), findsOneWidget);
  });
}
