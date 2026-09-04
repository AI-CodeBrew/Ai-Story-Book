import 'package:flutter/material.dart';
import 'app_colors.dart';

/// The 6 story themes/types, shared by the creation flow and the Library
/// filter. Names must match the website's THEME_OPTIONS exactly
/// (case-sensitive) since `theme` is a free-text field filtered server-side.
class ThemeOption {
  final String name;
  final IconData icon;
  final Color color;
  final String description;

  const ThemeOption({
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
  });
}

const List<ThemeOption> kThemeOptions = [
  ThemeOption(
    name: 'Adventure',
    icon: Icons.explore,
    color: AppColors.adventure,
    description: 'Exciting quests and discoveries',
  ),
  ThemeOption(
    name: 'Fantasy',
    icon: Icons.auto_awesome,
    color: AppColors.fantasy,
    description: 'Magical worlds and creatures',
  ),
  ThemeOption(
    name: 'Space',
    icon: Icons.rocket_launch,
    color: AppColors.space,
    description: 'Futuristic space adventures',
  ),
  ThemeOption(
    name: 'Nature',
    icon: Icons.eco,
    color: AppColors.nature,
    description: 'Beautiful natural world',
  ),
  ThemeOption(
    name: 'Friendship',
    icon: Icons.favorite,
    color: AppColors.friendship,
    description: 'Heartwarming friendship stories',
  ),
  ThemeOption(
    name: 'Science',
    icon: Icons.science,
    color: AppColors.science,
    description: 'Educational scientific concepts',
  ),
];
