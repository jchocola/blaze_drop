import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/section_label.dart';

/// The "LOCAL_BROADCAST_BEACON" card (FUNCTIONALITY.md §5.2): a large QR
/// encoding the hub URL with a dark-on-light square eye style.
class QrBeacon extends StatelessWidget {
  const QrBeacon({super.key, required this.data, this.size = 190});

  final String data;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SectionLabel(
          text: 'LOCAL_BROADCAST_BEACON',
          color: AppColors.primaryContainer,
        ),
        const SizedBox(height: 12),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: QrImageView(
            data: data,
            version: QrVersions.auto,
            size: size,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Colors.black,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'BlazeDrop | Server Active',
          style: AppTextStyles.labelCaps.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
