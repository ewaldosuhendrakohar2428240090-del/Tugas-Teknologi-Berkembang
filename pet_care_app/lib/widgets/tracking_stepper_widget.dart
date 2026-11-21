import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/tracking_step_model.dart';
import '../theme/app_theme.dart';

class TrackingStepperWidget extends StatelessWidget {
  final List<TrackingStepModel> steps;
  final bool isSteril;

  const TrackingStepperWidget({
    Key? key,
    required this.steps,
    this.isSteril = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('Belum ada tahapan pengerjaan.', style: TextStyle(color: AppTheme.textLight)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: steps.length,
      itemBuilder: (context, index) {
        final step = steps[index];
        final isLast = index == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Step Indicator & Connecting Line
            Column(
              children: [
                _buildStepIcon(step),
                if (!isLast)
                  Container(
                    width: 2.5,
                    height: step.photoUrl != null ? 140 : 70,
                    color: step.isCompleted ? AppTheme.primary : AppTheme.borderLight,
                  ),
              ],
            ),
            const SizedBox(width: 14),

            // Right Column: Step Content Card
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: step.isInProgress ? const Color(0xFFF0FDF4) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: step.isInProgress
                        ? AppTheme.primary
                        : (step.isCompleted ? AppTheme.borderLight : Colors.transparent),
                    width: step.isInProgress ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step Title & Time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            step.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: step.isPending ? AppTheme.textLight : AppTheme.textDark,
                            ),
                          ),
                        ),
                        if (step.completedAt != null)
                          Text(
                            DateFormat('HH:mm').format(step.completedAt!),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryDark,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        else if (step.isInProgress)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.inProgressBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Sedang Dikerjakan',
                              style: TextStyle(fontSize: 11, color: AppTheme.inProgressAmber, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    if (step.description != null && step.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        step.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: step.isPending ? AppTheme.textLight : AppTheme.textMuted,
                          height: 1.3,
                        ),
                      ),
                    ],

                    // Staff Note / Catatan Khusus
                    if (step.staffNotes != null && step.staffNotes!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.borderLight),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.sticky_note_2_outlined, size: 14, color: AppTheme.primary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                step.staffNotes!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textDark,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Live Photo Proof from Groomer / Doctor
                    if (step.photoUrl != null && step.photoUrl!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          children: [
                            Image.network(
                              step.photoUrl!,
                              height: 110,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 80,
                                color: const Color(0xFFF1F5F9),
                                alignment: Alignment.center,
                                child: const Icon(Icons.pets, color: AppTheme.textLight),
                              ),
                            ),
                            Positioned(
                              bottom: 6,
                              right: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.camera_alt, color: Colors.white, size: 12),
                                    SizedBox(width: 4),
                                    Text('Foto Langsung Pet Shop', style: TextStyle(color: Colors.white, fontSize: 10)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStepIcon(TrackingStepModel step) {
    if (step.isCompleted) {
      return Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: AppTheme.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 18),
      );
    } else if (step.isInProgress) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppTheme.primaryLight,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.primary, width: 2.5),
        ),
        child: const Center(
          child: SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ),
        ),
      );
    } else {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.borderLight, width: 2),
        ),
        child: Center(
          child: Text(
            '${step.stepNumber}',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textLight,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
  }
}
