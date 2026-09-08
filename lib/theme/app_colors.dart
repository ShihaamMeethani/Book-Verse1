import 'package:flutter/material.dart';

/// BookVerse theme palette matching the sleek "Note Reader" design:
/// - Rich Obsidian matte dark background (#0E0E12)
/// - Vibrant Rose-Raspberry (#D8315B)
/// - Deep Plum-Wine (#8E284E)
/// - Warm Coral-Salmon (#F38375)
/// - Crisp White & Muted Slate typography
class AppColors {
  AppColors._();

  // ── Signature Palette (from Note Reader) ─────────────────────
  static const Color primary = Color(0xFFD8315B); // Vibrant Rose / Raspberry
  static const Color primaryDark = Color(0xFFB32048);
  static const Color primaryLight = Color(0xFFE84D74);
  static const Color primaryGlow = Color(0x33D8315B);

  // Deep Plum / Wine
  static const Color plum = Color(0xFF8E284E);
  static const Color plumDark = Color(0xFF6B1A38);
  static const Color plumLight = Color(0xFFA83B65);

  // Warm Coral / Salmon Peach
  static const Color coral = Color(0xFFF38375);
  static const Color coralDark = Color(0xFFD96355);
  static const Color coralLight = Color(0xFFFFA599);

  // Accent & Gold Mappings (Remapped to Note Reader tones)
  static const Color gold = coral;
  static const Color goldBright = Color(0xFFFFA094);
  static const Color goldSoft = Color(0xFF2C1917);
  static const Color accent = primary;
  static const Color accentSoft = Color(0xFF2B121E);

  // ── Obsidian Matte Dark Surfaces ─────────────────────────────
  static const Color ink = Color(0xFF0E0E12); // Pure deep matte dark background
  static const Color espresso = Color(0xFF131318);
  static const Color surface = Color(0xFF18181F); // Clean solid card surface
  static const Color surfaceRaised = Color(0xFF202028); // Elevated card / sheet
  static const Color surfaceStrong = Color(0xFF282834);
  static const Color surfaceBorder = Color(0xFF2C2C38); // Crisp clean border
  static const Color surfaceBorderLight = Color(0xFF22222B);

  // ── Light Mode Surfaces (Clean & Minimal) ────────────────────
  static const Color paper = Color(0xFFF7F7FA);
  static const Color paperMuted = Color(0xFFECECF2);
  static const Color paperSurface = Color(0xFFFFFFFF);
  static const Color paperBorder = Color(0xFFE4E4EC);

  // ── Typography Colors ────────────────────────────────────────
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9E9EA7);
  static const Color textMuted = Color(0xFF686873);
  static const Color textDark = Color(0xFF111116);
  static const Color textDarkSecondary = Color(0xFF686873);

  // ── Semantic Status Colors ───────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF38BDF8);

  // ── Legacy gradient list compatibility (Solid single tones) ──
  static const List<Color> primaryGradient = [primary, primary];
  static const List<Color> heroGradient = [primary, coral];
  static const List<Color> goldGradient = [coral, coral];
  static const List<Color> darkCardGradient = [surface, surface];
  static const List<Color> glassGradient = [surfaceRaised, surfaceRaised];

  // ── Compatibility aliases ────────────────────────────────────
  static const Color burgundy = primary;
  static const Color burgundyDeep = primaryDark;
  static const Color burgundyBright = primaryLight;
  static const Color burgundySoft = accentSoft;
  static const Color primaryDarkAlias = primaryDark;
  static const Color primaryLightAlias = primaryLight;
  static const Color background = paper;
  static const Color surfaceDim = surfaceRaised;
  static const Color darkBackground = ink;
  static const Color darkSurface = surface;
  static const Color darkSurfaceDim = surfaceRaised;
  static const Color textOnDark = textPrimary;
}
