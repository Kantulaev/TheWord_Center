import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/language_type.dart';
import '../../../core/models/student.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/confirm_delete_dialog.dart';
import '../../../shared/widgets/entity_avatar.dart';
import '../../../shared/widgets/language_badge.dart';
import '../../../shared/widgets/liquid_glass_container.dart';
import 'student_detail_panel.dart';
import 'student_form_dialog.dart';

class StudentsScreen extends ConsumerStatefulWidget {
  const StudentsScreen({super.key});

  @override
  ConsumerState<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends ConsumerState<StudentsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  CourseLanguage? _languageFilter;
  LessonType? _formatFilter;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openInspector(BuildContext context, Student student) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 600) {
      showAdaptiveGlassModal<void>(
        context,
        builder: (sheetCtx) => LiquidGlassContainer(
          borderRadius: 28,
          blurSigma: 28,
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: MediaQuery.sizeOf(sheetCtx).height * 0.84,
            child: StudentDetailPanel(
              studentId: student.id,
              onClose: () => Navigator.of(sheetCtx).pop(),
            ),
          ),
        ),
      );
      return;
    }
    ref
        .read(inspectorSelectionProvider.notifier)
        .open(InspectorTarget.student(student.id));
  }

  @override
  Widget build(BuildContext context) {
    final students = ref.watch(studentsStreamProvider).value ?? const [];
    final teachers = ref.watch(teachersMapProvider);

    final filtered = students.where((s) {
      if (_languageFilter != null && s.targetLanguage != _languageFilter) {
        return false;
      }
      if (_formatFilter != null && s.format != _formatFilter) {
        return false;
      }
      if (_query.trim().isNotEmpty) {
        final q = _query.trim().toLowerCase();
        final teacherName =
            teachers[s.primaryTeacherId]?.fullName.toLowerCase() ?? '';
        final haystack =
            '${s.fullName} ${s.proficiencyLevel} $teacherName ${s.email}'.toLowerCase();
        if (!haystack.contains(q)) return false;
      }
      return true;
    }).toList(growable: false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 600;
            final header = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Students Roster',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Track Chinese (HSK 1–6) and English (A1–C2) learners, lesson credits, and upcoming classes.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            );
            final cta = LiquidPrimaryButton(
              label: 'Add Student',
              icon: CupertinoIcons.person_add,
              onPressed: () => showStudentFormModal(context),
            );
            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [header, const SizedBox(height: 12), cta],
              );
            }
            return Row(
              children: [
                Expanded(child: header),
                const SizedBox(width: 16),
                cta,
              ],
            );
          },
        ),
        const SizedBox(height: 16),

        LiquidGlassContainer(
          borderRadius: 22,
          blurSigma: 18,
          elevation: 0.55,
          padding: const EdgeInsets.all(14),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 248,
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search student, level, teacher...',
                    prefixIcon: const Icon(CupertinoIcons.search, size: 18),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            tooltip: 'Clear Search',
                            icon: const Icon(
                              CupertinoIcons.xmark_circle_fill,
                              size: 16,
                            ),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    isDense: true,
                  ),
                ),
              ),
              LiquidGlassPillButton(
                label: 'All (${students.length})',
                selected: _languageFilter == null,
                onTap: () => setState(() => _languageFilter = null),
              ),
              for (final lang in const [
                CourseLanguage.chinese,
                CourseLanguage.english,
              ])
                LiquidGlassPillButton(
                  label: lang.label,
                  selected: _languageFilter == lang,
                  accentColor: lang.accentColor(context),
                  onTap: () => setState(() => _languageFilter = lang),
                ),
              LiquidGlassPillButton(
                label: 'Individual',
                selected: _formatFilter == LessonType.oneOnOne,
                onTap: () => setState(
                  () => _formatFilter = _formatFilter == LessonType.oneOnOne
                      ? null
                      : LessonType.oneOnOne,
                ),
              ),
              LiquidGlassPillButton(
                label: 'Group',
                selected: _formatFilter == LessonType.group,
                onTap: () => setState(
                  () => _formatFilter = _formatFilter == LessonType.group
                      ? null
                      : LessonType.group,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (filtered.isEmpty)
          LiquidGlassContainer(
            borderRadius: 24,
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(
                'No students match the current filters.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width >= 1100 ? 3 : (width >= 660 ? 2 : 1);
              const spacing = 14.0;
              final cardWidth =
                  (width - spacing * (crossAxisCount - 1)) / crossAxisCount;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final student in filtered)
                    SizedBox(
                      width: crossAxisCount == 1 ? width : cardWidth,
                      child: _StudentCard(
                        student: student,
                        primaryTeacherName: student.primaryTeacherId != null
                            ? teachers[student.primaryTeacherId!]?.fullName
                            : null,
                        onTap: () => _openInspector(context, student),
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}

class _StudentCard extends ConsumerWidget {
  const _StudentCard({
    required this.student,
    required this.primaryTeacherName,
    required this.onTap,
  });

  final Student student;
  final String? primaryTeacherName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = student.targetLanguage.accentColor(context);
    final isLowCredits = student.remainingCredits <= 2;

    return LiquidGlassContainer(
      borderRadius: 24,
      blurSigma: 20,
      elevation: 0.7,
      tintColor: accent,
      tintStrength: 0.05,
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              EntityAvatar(
                initials: student.initials,
                color: accent,
                size: 46,
                badgeText: student.targetLanguage.code,
                badgeColor: accent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        LanguageBadge(
                          language: student.targetLanguage,
                          compact: true,
                        ),
                        GlassInfoTag(label: student.proficiencyLevel),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit Student',
                icon: const Icon(CupertinoIcons.pencil, size: 17),
                onPressed: () =>
                    showStudentFormModal(context, existing: student),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${student.format.studentFormatLabel} • Teacher: ${primaryTeacherName ?? 'Unassigned'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Remaining Credits',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                          ),
                    ),
                    Row(
                      children: [
                        Text(
                          '${student.remainingCredits}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: isLowCredits
                                    ? AppColors.warningAmber
                                    : null,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        if (isLowCredits) ...[
                          const SizedBox(width: 6),
                          const StatusBadge(
                            label: 'Low',
                            color: AppColors.warningAmber,
                            compact: true,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Decrease credits (-1)',
                onPressed: student.remainingCredits > 0
                    ? () => ref
                        .read(dataRepositoryProvider)
                        .adjustStudentCredits(student.id, -1)
                    : null,
                icon: const Icon(CupertinoIcons.minus, size: 15),
              ),
              const SizedBox(width: 6),
              IconButton.filledTonal(
                tooltip: 'Increase credits (+1)',
                onPressed: () => ref
                    .read(dataRepositoryProvider)
                    .adjustStudentCredits(student.id, 1),
                icon: const Icon(CupertinoIcons.plus, size: 15),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
