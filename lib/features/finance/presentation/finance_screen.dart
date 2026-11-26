import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/classroom.dart';
import '../../../core/models/language_type.dart';
import '../../../core/models/lesson.dart';
import '../../../core/models/operations_models.dart';
import '../../../core/models/student.dart';
import '../../../core/models/study_group.dart';
import '../../../core/models/teacher.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/csv_exporter.dart';
import '../../../core/utils/reminder_helper.dart';
import '../../../shared/widgets/confirm_delete_dialog.dart';
import '../../../shared/widgets/entity_avatar.dart';
import '../../../shared/widgets/language_badge.dart';
import '../../../shared/widgets/liquid_glass_container.dart';
import '../../teachers/presentation/teacher_form_dialog.dart';

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  void _shiftMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final payments = ref.watch(paymentsStreamProvider).value ?? const [];
    final students = ref.watch(studentsStreamProvider).value ?? const [];
    final teachers = ref.watch(teachersStreamProvider).value ?? const [];
    final classrooms = ref.watch(classroomsMapProvider);
    final lessons = ref.watch(lessonsStreamProvider).value ?? const [];
    final groups = ref.watch(groupsStreamProvider).value ?? const [];
    final teachersMap = ref.watch(teachersMapProvider);

    final now = DateTime.now();
    final monthStart = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final monthEnd = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);

    final monthPayments = payments
        .where((p) =>
            p.paidAt.year == _selectedMonth.year &&
            p.paidAt.month == _selectedMonth.month)
        .toList();
    final monthRevenue =
        monthPayments.fold<double>(0, (sum, p) => sum + p.amount);
    final todayRevenue = payments
        .where((p) =>
            p.paidAt.year == now.year &&
            p.paidAt.month == now.month &&
            p.paidAt.day == now.day)
        .fold<double>(0, (sum, p) => sum + p.amount);

    final lowCreditStudents = students
        .where((s) => s.remainingCredits <= 2)
        .toList()
      ..sort((a, b) => a.remainingCredits.compareTo(b.remainingCredits));

    final unpaidGroupEntries = <({StudyGroup group, GroupMemberPayment member})>[];
    for (final group in groups) {
      for (final m in group.members) {
        if (!m.hasPaid || m.lessonsRemaining <= 2) {
          unpaidGroupEntries.add((group: group, member: m));
        }
      }
    }

    final payrollRows = _computeTeacherPayroll(
      teachers: teachers,
      lessons: lessons,
      monthStart: monthStart,
      monthEnd: monthEnd,
    );
    final totalPayroll = payrollRows.fold<double>(0, (s, r) => s + r.totalPay);
    final monthLabel = DateFormat('MMMM yyyy').format(_selectedMonth);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 680;
            final header = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Finance, Payroll & Exports',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Track student tuition payments, monitor monthly teacher payouts, send reminders, and export CSV reports.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            );
            final actions = Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                LiquidGlassContainer(
                  borderRadius: 999,
                  blurSigma: 14,
                  elevation: 0.3,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Previous Month',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _shiftMonth(-1),
                        icon: const Icon(CupertinoIcons.chevron_left, size: 16),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          monthLabel,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Next Month',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _shiftMonth(1),
                        icon: const Icon(CupertinoIcons.chevron_right, size: 16),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Export CSV reports',
                  onSelected: (choice) => _handleCsvExport(
                    context,
                    choice: choice,
                    monthLabel: monthLabel,
                    lessons: lessons,
                    teachersMap: teachersMap,
                    classroomsMap: classrooms,
                    students: students,
                    groups: groups,
                    payments: monthPayments,
                    payrollRows: payrollRows,
                  ),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'schedule',
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.calendar, size: 17),
                          SizedBox(width: 8),
                          Text('Export Week Schedule CSV'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'unpaid',
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.exclamationmark_triangle, size: 17),
                          SizedBox(width: 8),
                          Text('Export Unpaid & Low Credits CSV'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'finance',
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.money_dollar_circle, size: 17),
                          SizedBox(width: 8),
                          Text('Export Payments & Payroll CSV'),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.englishAccent(context)
                            .withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.arrow_down_doc,
                          size: 16,
                          color: AppColors.englishAccent(context),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Export CSV',
                          style: TextStyle(
                            color: AppColors.englishAccent(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                LiquidPrimaryButton(
                  label: 'Record Payment',
                  icon: CupertinoIcons.plus,
                  onPressed: () => showPaymentFormModal(context),
                ),
              ],
            );
            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [header, const SizedBox(height: 12), actions],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: header),
                const SizedBox(width: 16),
                actions,
              ],
            );
          },
        ),
        const SizedBox(height: 18),

        // KPI Row
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _FinanceKpiCard(
              title: 'Revenue ($monthLabel)',
              value: '\$${monthRevenue.toStringAsFixed(0)}',
              subtitle: '${monthPayments.length} payments recorded',
              icon: CupertinoIcons.money_dollar_circle_fill,
              accent: AppColors.liveEmerald,
            ),
            _FinanceKpiCard(
              title: 'Collected Today',
              value: '\$${todayRevenue.toStringAsFixed(0)}',
              subtitle: DateFormat('EEE, MMM d').format(now),
              icon: CupertinoIcons.bolt_fill,
              accent: AppColors.englishAccent(context),
            ),
            _FinanceKpiCard(
              title: 'Est. Teacher Payroll',
              value: '\$${totalPayroll.toStringAsFixed(0)}',
              subtitle: '${teachers.where((t) => t.isActive).length} active teachers',
              icon: CupertinoIcons.person_2_fill,
              accent: AppColors.sharingAccent(context),
            ),
            _FinanceKpiCard(
              title: 'Renewal Alerts',
              value: '${lowCreditStudents.length + unpaidGroupEntries.length}',
              subtitle: 'Low credits or unpaid packages',
              icon: CupertinoIcons.bell_fill,
              accent: (lowCreditStudents.isEmpty && unpaidGroupEntries.isEmpty)
                  ? AppColors.liveEmerald
                  : AppColors.warningAmber,
            ),
          ],
        ),
        const SizedBox(height: 22),

        // Low-Credit & Unpaid Alerts with Smart Reminders
        LiquidGlassContainer(
          borderRadius: 24,
          blurSigma: 20,
          tintColor: AppColors.warningAmber,
          tintStrength: 0.05,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.bell_circle_fill,
                    color: AppColors.warningAmber,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tuition Renewal & Unpaid Alerts (${lowCreditStudents.length + unpaidGroupEntries.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Send one-tap WhatsApp or Telegram reminders, or record a new tuition payment.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              if (lowCreditStudents.isEmpty && unpaidGroupEntries.isEmpty)
                Text(
                  'All enrolled students and cohort packages have healthy credit balances.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.liveEmerald,
                        fontWeight: FontWeight.w600,
                      ),
                )
              else ...[
                for (final s in lowCreditStudents) ...[
                  _LowCreditAlertRow(
                    title: s.fullName,
                    subtitle:
                        '${s.targetLanguage.label} • ${s.proficiencyLevel} • ${s.remainingCredits} credits left',
                    phone: s.phone,
                    badgeColor: s.remainingCredits <= 0
                        ? AppColors.dangerRose
                        : AppColors.warningAmber,
                    badgeLabel: s.remainingCredits <= 0
                        ? '0 left'
                        : '${s.remainingCredits} left',
                    message:
                        'Hello ${s.fullName}! This is a friendly reminder from The Word Language Center that you have ${s.remainingCredits} remaining lesson credit(s) for ${s.targetLanguage.label} (${s.proficiencyLevel}). Please let us know when you would like to renew your package!',
                    onRecordPayment: () => showPaymentFormModal(
                      context,
                      initialStudent: s,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                for (final entry in unpaidGroupEntries) ...[
                  _LowCreditAlertRow(
                    title: '${entry.member.fullName} (${entry.group.name})',
                    subtitle:
                        '${entry.group.language.label} ${entry.group.level} • ${entry.member.lessonsRemaining}/${entry.member.totalPaidLessons} left',
                    phone: '',
                    badgeColor: !entry.member.hasPaid
                        ? AppColors.dangerRose
                        : AppColors.warningAmber,
                    badgeLabel: !entry.member.hasPaid
                        ? 'Unpaid'
                        : '${entry.member.lessonsRemaining} left',
                    message:
                        'Hello ${entry.member.fullName}! Reminder from The Word Center regarding group ${entry.group.name} (${entry.group.level}): ${entry.member.hasPaid ? "you have ${entry.member.lessonsRemaining} lessons remaining" : "your 12-lesson tuition payment is currently pending"}.',
                    onRecordPayment: () => showPaymentFormModal(
                      context,
                      initialGroup: entry.group,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Teacher Payroll Section
        LiquidGlassContainer(
          borderRadius: 24,
          blurSigma: 20,
          tintColor: AppColors.sharingAccent(context),
          tintStrength: 0.04,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    CupertinoIcons.briefcase_fill,
                    color: AppColors.sharingAccent(context),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Teacher Payroll — $monthLabel',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Auto-calculated from all active and recurring classes (excluding canceled sessions). Tap Edit Rates on any teacher to adjust hourly or club fees.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              if (payrollRows.isEmpty)
                const Text('No teachers registered yet.')
              else
                for (final row in payrollRows) ...[
                  _PayrollTeacherTile(
                    row: row,
                    onEditRates: () => showTeacherFormModal(
                      context,
                      existing: row.teacher,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Recent Payment Transactions
        LiquidGlassContainer(
          borderRadius: 24,
          blurSigma: 20,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    CupertinoIcons.doc_plaintext,
                    color: AppColors.englishAccent(context),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Payment Ledger (${payments.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (payments.isEmpty)
                Text(
                  'No payments recorded yet. Click "Record Payment" above when a student pays tuition.',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                for (final p in payments.take(40)) ...[
                  _PaymentHistoryTile(payment: p),
                  const SizedBox(height: 8),
                ],
            ],
          ),
        ),
      ],
    );
  }

  List<_TeacherPayrollRow> _computeTeacherPayroll({
    required List<Teacher> teachers,
    required List<Lesson> lessons,
    required DateTime monthStart,
    required DateTime monthEnd,
  }) {
    final expanded = Lesson.expandAll(lessons, monthStart, monthEnd)
        .where((l) => l.status != LessonStatus.canceled)
        .toList();

    final rows = <_TeacherPayrollRow>[];
    for (final teacher in teachers) {
      var regularHours = 0.0;
      var regularCount = 0;
      var clubCount = 0;
      for (final lesson in expanded) {
        if (!lesson.involvesTeacher(teacher.id)) continue;
        if (lesson.isSpeakingClub) {
          clubCount += 1;
        } else {
          regularCount += 1;
          regularHours += lesson.durationMinutes / 60.0;
        }
      }
      final regularPay = regularHours * teacher.hourlyRate;
      final clubPay = clubCount * teacher.clubRate;
      rows.add(
        _TeacherPayrollRow(
          teacher: teacher,
          regularCount: regularCount,
          regularHours: regularHours,
          clubCount: clubCount,
          regularPay: regularPay,
          clubPay: clubPay,
          totalPay: regularPay + clubPay,
        ),
      );
    }
    rows.sort((a, b) => b.totalPay.compareTo(a.totalPay));
    return rows;
  }

  Future<void> _handleCsvExport(
    BuildContext context, {
    required String choice,
    required String monthLabel,
    required List<Lesson> lessons,
    required Map<String, Teacher> teachersMap,
    required Map<String, Classroom> classroomsMap,
    required List<Student> students,
    required List<StudyGroup> groups,
    required List<PaymentRecord> payments,
    required List<_TeacherPayrollRow> payrollRows,
  }) async {
    final now = DateTime.now();
    final dateTag = DateFormat('yyyy-MM-dd').format(now);
    switch (choice) {
      case 'schedule':
        final weekday = now.weekday;
        final weekStart = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        final weekLessons = Lesson.expandAll(lessons, weekStart, weekEnd);
        final rows = <List<String>>[
          ['Date', 'Start', 'End', 'Title', 'Category', 'Format', 'Classroom', 'Teachers', 'Status'],
          for (final l in weekLessons)
            [
              DateFormat('yyyy-MM-dd (EEE)').format(l.startTime),
              DateFormat('HH:mm').format(l.startTime),
              DateFormat('HH:mm').format(l.endTime),
              l.title,
              l.language.label,
              l.lessonType.label,
              classroomsMap[l.classroomId]?.name ?? l.classroomId,
              l.allTeacherIds
                  .map((id) => teachersMap[id]?.fullName ?? id)
                  .join(' / '),
              l.status.label,
            ],
        ];
        await CsvExporter.exportAndNotify(
          context,
          filename: 'theword_schedule_$dateTag.csv',
          rows: rows,
        );
      case 'unpaid':
        final rows = <List<String>>[
          ['Source', 'Student', 'Course / Group', 'Remaining Credits', 'Payment Status', 'Phone', 'Email'],
          for (final s in students.where((s) => s.remainingCredits <= 2))
            [
              'Individual Student',
              s.fullName,
              '${s.targetLanguage.label} ${s.proficiencyLevel}',
              '${s.remainingCredits}',
              s.remainingCredits <= 0 ? 'Depleted' : 'Low Balance',
              s.phone,
              s.email,
            ],
          for (final g in groups)
            for (final m in g.members)
              if (!m.hasPaid || m.lessonsRemaining <= 2)
                [
                  'Study Group',
                  m.fullName,
                  '${g.name} (${g.level})',
                  '${m.lessonsRemaining}/${m.totalPaidLessons}',
                  m.hasPaid ? 'Low Balance' : 'Unpaid',
                  '',
                  m.email,
                ],
        ];
        await CsvExporter.exportAndNotify(
          context,
          filename: 'theword_unpaid_low_credits_$dateTag.csv',
          rows: rows,
        );
      case 'finance':
        final rows = <List<String>>[
          ['Section', 'Name', 'Details', 'Hours / Lessons', 'Method / Rate', 'Amount (USD)', 'Date'],
          for (final r in payrollRows)
            [
              'Teacher Payroll ($monthLabel)',
              r.teacher.fullName,
              '${r.regularCount} classes + ${r.clubCount} clubs',
              '${r.regularHours.toStringAsFixed(1)}h',
              '\$${r.teacher.hourlyRate.toStringAsFixed(0)}/h | \$${r.teacher.clubRate.toStringAsFixed(0)}/club',
              r.totalPay.toStringAsFixed(2),
              monthLabel,
            ],
          for (final p in payments)
            [
              'Student Payment',
              p.studentName,
              p.notes.isEmpty ? 'Tuition package' : p.notes,
              '+${p.lessonsPurchased} lessons',
              '${p.method.label} (${p.currency})',
              p.amount.toStringAsFixed(2),
              DateFormat('yyyy-MM-dd').format(p.paidAt),
            ],
        ];
        await CsvExporter.exportAndNotify(
          context,
          filename: 'theword_finance_payroll_$dateTag.csv',
          rows: rows,
        );
    }
  }
}

class _TeacherPayrollRow {
  const _TeacherPayrollRow({
    required this.teacher,
    required this.regularCount,
    required this.regularHours,
    required this.clubCount,
    required this.regularPay,
    required this.clubPay,
    required this.totalPay,
  });

  final Teacher teacher;
  final int regularCount;
  final double regularHours;
  final int clubCount;
  final double regularPay;
  final double clubPay;
  final double totalPay;
}

class _FinanceKpiCard extends StatelessWidget {
  const _FinanceKpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 210, maxWidth: 280),
      child: LiquidGlassContainer(
        borderRadius: 22,
        blurSigma: 18,
        tintColor: accent,
        tintStrength: 0.06,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.labelMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _LowCreditAlertRow extends StatelessWidget {
  const _LowCreditAlertRow({
    required this.title,
    required this.subtitle,
    required this.phone,
    required this.badgeColor,
    required this.badgeLabel,
    required this.message,
    required this.onRecordPayment,
  });

  final String title;
  final String subtitle;
  final String phone;
  final Color badgeColor;
  final String badgeLabel;
  final String message;
  final VoidCallback onRecordPayment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.72),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.25),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 520;
          final info = Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusBadge(
                          label: badgeLabel,
                          color: badgeColor,
                          compact: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          );

          final buttons = Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => ReminderHelper.openWhatsApp(
                  context,
                  phone: phone,
                  message: message,
                ),
                icon: const Icon(CupertinoIcons.chat_bubble_fill, size: 14),
                label: const Text('WhatsApp'),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => ReminderHelper.openTelegram(
                  context,
                  message: message,
                ),
                icon: const Icon(CupertinoIcons.paperplane_fill, size: 14),
                label: const Text('Telegram'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: AppColors.liveEmerald,
                  foregroundColor: Colors.white,
                ),
                onPressed: onRecordPayment,
                icon: const Icon(CupertinoIcons.money_dollar, size: 14),
                label: const Text('Pay'),
              ),
            ],
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [info, const SizedBox(height: 10), buttons],
            );
          }
          return Row(
            children: [
              Expanded(child: info),
              const SizedBox(width: 12),
              buttons,
            ],
          );
        },
      ),
    );
  }
}

class _PayrollTeacherTile extends StatelessWidget {
  const _PayrollTeacherTile({
    required this.row,
    required this.onEditRates,
  });

  final _TeacherPayrollRow row;
  final VoidCallback onEditRates;

  @override
  Widget build(BuildContext context) {
    final t = row.teacher;
    final color = AppColors.fromHex(t.avatarColorHex);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.7),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 520;
          final left = Row(
            children: [
              EntityAvatar(
                initials: t.initials,
                color: color,
                size: 40,
                isActiveDot: t.isActive,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.fullName,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${row.regularCount} classes (${row.regularHours.toStringAsFixed(1)}h @ \$${t.hourlyRate.toStringAsFixed(0)}/h)  •  ${row.clubCount} clubs (@ \$${t.clubRate.toStringAsFixed(0)})',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          );
          final right = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '\$${row.totalPay.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.liveEmerald,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: onEditRates,
                child: const Text('Rates'),
              ),
            ],
          );
          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [left, const SizedBox(height: 10), right],
            );
          }
          return Row(
            children: [
              Expanded(child: left),
              const SizedBox(width: 12),
              right,
            ],
          );
        },
      ),
    );
  }
}

class _PaymentHistoryTile extends StatelessWidget {
  const _PaymentHistoryTile({required this.payment});

  final PaymentRecord payment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.68),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.liveEmerald.withValues(alpha: 0.14),
            ),
            child: const Icon(
              CupertinoIcons.checkmark_seal_fill,
              color: AppColors.liveEmerald,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.studentName,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  '${payment.method.label} • +${payment.lessonsPurchased} lessons • ${DateFormat('MMM d, yyyy').format(payment.paidAt)}${payment.notes.isNotEmpty ? ' • ${payment.notes}' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${payment.amount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.liveEmerald,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              Text(
                payment.currency,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> showPaymentFormModal(
  BuildContext context, {
  Student? initialStudent,
  StudyGroup? initialGroup,
}) {
  return showAdaptiveGlassModal<void>(
    context,
    maxWidth: 540,
    builder: (_) => _PaymentFormDialog(
      initialStudent: initialStudent,
      initialGroup: initialGroup,
    ),
  );
}

class _PaymentFormDialog extends ConsumerStatefulWidget {
  const _PaymentFormDialog({
    this.initialStudent,
    this.initialGroup,
  });

  final Student? initialStudent;
  final StudyGroup? initialGroup;

  @override
  ConsumerState<_PaymentFormDialog> createState() => _PaymentFormDialogState();
}

class _PaymentFormDialogState extends ConsumerState<_PaymentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController(text: '120');
  final _lessonsCtrl = TextEditingController(text: '12');
  final _notesCtrl = TextEditingController();

  String? _selectedStudentId;
  String? _selectedGroupId;
  PaymentMethod _method = PaymentMethod.transfer;
  String _currency = 'USD';
  bool _addCredits = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedStudentId = widget.initialStudent?.id;
    _selectedGroupId = widget.initialGroup?.id;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _lessonsCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final students = ref.watch(studentsStreamProvider).value ?? const [];
    final groups = ref.watch(groupsStreamProvider).value ?? const [];
    final selectedStudent = students.firstWhere(
      (s) => s.id == _selectedStudentId,
      orElse: () => students.isNotEmpty
          ? students.first
          : Student(
              id: '',
              fullName: 'Walk-in Student',
              targetLanguage: CourseLanguage.chinese,
              proficiencyLevel: 'HSK 1',
              format: LessonType.group,
              remainingCredits: 0,
              createdAt: DateTime.now(),
            ),
    );
    if (_selectedStudentId == null && students.isNotEmpty) {
      _selectedStudentId = students.first.id;
    }

    return LiquidGlassContainer(
      borderRadius: 28,
      blurSigma: 28,
      elevation: 1.4,
      padding: const EdgeInsets.all(22),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  CupertinoIcons.money_dollar_circle_fill,
                  color: AppColors.liveEmerald,
                  size: 26,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Record Tuition Payment',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(CupertinoIcons.xmark_circle_fill),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (students.isNotEmpty)
                      DropdownButtonFormField<String>(
                        initialValue: _selectedStudentId,
                        decoration: const InputDecoration(
                          labelText: 'Student *',
                        ),
                        items: [
                          for (final s in students)
                            DropdownMenuItem(
                              value: s.id,
                              child: Text(
                                '${s.fullName} (${s.remainingCredits} credits)',
                              ),
                            ),
                        ],
                        onChanged: (v) => setState(() => _selectedStudentId = v),
                      ),
                    const SizedBox(height: 12),
                    if (groups.isNotEmpty)
                      DropdownButtonFormField<String?>(
                        initialValue: _selectedGroupId,
                        decoration: const InputDecoration(
                          labelText: 'Study Group (optional)',
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('No specific group / 1-on-1'),
                          ),
                          for (final g in groups)
                            DropdownMenuItem<String?>(
                              value: g.id,
                              child: Text('${g.name} (${g.level})'),
                            ),
                        ],
                        onChanged: (v) => setState(() => _selectedGroupId = v),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _amountCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Amount *',
                            ),
                            validator: (v) {
                              final parsed = double.tryParse(v?.trim() ?? '');
                              if (parsed == null || parsed <= 0) {
                                return 'Enter positive amount';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _currency,
                            decoration:
                                const InputDecoration(labelText: 'Currency'),
                            items: const [
                              DropdownMenuItem(value: 'USD', child: Text('USD')),
                              DropdownMenuItem(value: 'KGS', child: Text('KGS')),
                              DropdownMenuItem(value: 'CNY', child: Text('CNY')),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _currency = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _lessonsCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Lessons Purchased',
                            ),
                            validator: (v) {
                              final parsed = int.tryParse(v?.trim() ?? '');
                              if (parsed == null || parsed < 0) {
                                return 'Enter valid count';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<PaymentMethod>(
                            initialValue: _method,
                            decoration:
                                const InputDecoration(labelText: 'Method'),
                            items: [
                              for (final m in PaymentMethod.values)
                                DropdownMenuItem(value: m, child: Text(m.label)),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _method = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final count in [4, 8, 12, 24])
                          ActionChip(
                            label: Text('$count lessons'),
                            onPressed: () =>
                                _lessonsCtrl.text = count.toString(),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: _addCredits,
                      title: const Text('Add lessons to student balance'),
                      subtitle: const Text(
                        'Automatically increases remaining lesson credits',
                      ),
                      onChanged: (v) => setState(() => _addCredits = v),
                    ),
                    TextFormField(
                      controller: _notesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        hintText: 'Month, invoice #, or package comment',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 10),
                LiquidPrimaryButton(
                  label: 'Save Payment',
                  icon: CupertinoIcons.checkmark_alt,
                  color: AppColors.liveEmerald,
                  onPressed: _saving
                      ? null
                      : () async {
                          if (!(_formKey.currentState?.validate() ?? false)) {
                            return;
                          }
                          setState(() => _saving = true);
                          final amount =
                              double.parse(_amountCtrl.text.trim());
                          final lessonsCount =
                              int.parse(_lessonsCtrl.text.trim());
                          final actor =
                              ref.read(authStateProvider).value?.email ??
                                  'staff';
                          final record = PaymentRecord(
                            id: const Uuid().v4(),
                            studentId: selectedStudent.id,
                            studentName: selectedStudent.fullName,
                            groupId: _selectedGroupId,
                            amount: amount,
                            currency: _currency,
                            lessonsPurchased: lessonsCount,
                            method: _method,
                            notes: _notesCtrl.text.trim(),
                            paidAt: DateTime.now(),
                            recordedBy: actor,
                          );
                          final repo = ref.read(dataRepositoryProvider);
                          await repo.recordPayment(
                            record,
                            addCreditsToStudent:
                                _addCredits && selectedStudent.id.isNotEmpty,
                          );
                          await repo.logActivity(
                            ActivityLogEntry(
                              id: const Uuid().v4(),
                              actorEmail: actor,
                              category: 'Payment',
                              summary:
                                  'Recorded \$${amount.toStringAsFixed(0)} (${record.method.label}, +$lessonsCount lessons) for ${record.studentName}',
                              createdAt: DateTime.now(),
                            ),
                          );
                          if (context.mounted) Navigator.of(context).pop();
                        },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
