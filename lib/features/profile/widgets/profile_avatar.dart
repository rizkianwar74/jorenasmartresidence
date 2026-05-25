import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    this.imageUrl,
    this.radius = 56,
    this.onEditTap,
  });

  final String? imageUrl;
  final double radius;
  final VoidCallback? onEditTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF2D3748),
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
            image: imageUrl != null
                ? DecorationImage(
                    image: NetworkImage(imageUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: imageUrl == null
              ? const Icon(Icons.person, color: Colors.white, size: 48)
              : null,
        ),
        Positioned(
          bottom: 2,
          right: 2,
          child: GestureDetector(
            onTap: onEditTap,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.edit,
                color: Colors.white,
                size: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }
}