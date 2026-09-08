# BookVerse UI Update

This version refreshes the BookVerse interface using the supplied dark bookstore reference as visual inspiration.

## Main UI changes
- Near-black dark surfaces with crisp white typography.
- Bold red primary accent and red CTA buttons.
- Modern Inter typography and tighter spacing.
- Home screen now uses a compact greeting header, search bar, category chips, featured shelf and horizontal book sections.
- Book cards use a compact reference-style layout with cover, badge, heart action, title, author, rating and price.
- Bottom navigation is now five compact tabs: Home, Explore, Cart, Wishlist and Profile.
- Admin remains accessible from Profile/Drawer rather than occupying the primary navigation.
- Book details has a fixed bottom action area with wishlist + Add to Cart/View Cart.
- Add to Cart is single-click protected with a loading state and automatically opens Cart.
- Grid cards use a fixed main extent to avoid vertical pixel overflow.
- Dark mode remains the default theme; the existing light-mode toggle is still available.

## Run
```bash
flutter clean
flutter pub get
flutter analyze
flutter run
```
