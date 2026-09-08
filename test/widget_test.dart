import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookverse/widgets/custom_button.dart';
import 'package:bookverse/utils/constants.dart';
import 'package:bookverse/models/review_model.dart';

void main() {
  testWidgets('CustomButton renders label and handles tap', (WidgetTester tester) async {
    bool pressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomButton(
            label: 'Test Button',
            onPressed: () => pressed = true,
          ),
        ),
      ),
    );

    expect(find.text('Test Button'), findsOneWidget);

    await tester.tap(find.text('Test Button'));
    await tester.pump();

    expect(pressed, isTrue);
  });

  testWidgets('CustomButton shows loading indicator when isLoading is true', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CustomButton(
            label: 'Loading Button',
            isLoading: true,
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Loading Button'), findsNothing);
  });

  test('Review.fromMap handles both integer and double rating correctly', () {
    final intReview = Review.fromMap({
      'bookId': 'b1',
      'userId': 'u1',
      'userName': 'Owais',
      'rating': 5, // int from Firestore
      'comment': 'Great book!',
      'likedBy': ['u2'],
    }, 'rev1');

    expect(intReview.rating, 5.0);
    expect(intReview.likeCount, 1);
    expect(intReview.userName, 'Owais');

    final doubleReview = Review.fromMap({
      'bookId': 'b1',
      'userId': 'u1',
      'userName': 'Owais',
      'rating': 4.5,
      'comment': 'Really good!',
    }, 'rev2');

    expect(doubleReview.rating, 4.5);
    expect(doubleReview.likeCount, 0);
  });

  test('AppConstants.isAdminEmail returns true for configured admin emails', () {
    expect(AppConstants.isAdminEmail('admin@bookverse.com'), isTrue);
    expect(AppConstants.isAdminEmail('ADMIN@BOOKVERSE.COM'), isTrue);
    expect(AppConstants.isAdminEmail('meethanishihaam24@gmail.com'), isTrue);
    expect(AppConstants.isAdminEmail('regularuser@gmail.com'), isFalse);
    expect(AppConstants.isAdminEmail(''), isFalse);
    expect(AppConstants.isAdminEmail(null), isFalse);
  });
}

