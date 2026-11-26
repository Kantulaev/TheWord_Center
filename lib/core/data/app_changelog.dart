import 'package:flutter/foundation.dart';

const String kCurrentAppVersion = '1.7.0';

enum ReleaseChangeType { newFeature, improved, fixed }

@immutable
class ReleaseHighlight {
  const ReleaseHighlight({
    required this.type,
    required this.text,
  });

  final ReleaseChangeType type;
  final String text;
}

@immutable
class AppReleaseNote {
  const AppReleaseNote({
    required this.version,
    required this.dateLabel,
    required this.title,
    required this.summary,
    required this.highlights,
  });

  final String version;
  final String dateLabel;
  final String title;
  final String summary;
  final List<ReleaseHighlight> highlights;
}

/// Official in-app changelog displayed to teachers & staff under "What's New".
const List<AppReleaseNote> kAppChangelog = [
  AppReleaseNote(
    version: '1.7.0',
    dateLabel: 'May 2026',
    title: 'Notifications Center, Auto-Registration & Events History',
    summary:
        'Automated Google Sign-In roster linking for teachers and students, Speaking Club push alerts via FCM & Firebase Analytics, and date-grouped Events & History with audience permissions.',
    highlights: [
      ReleaseHighlight(
        type: ReleaseChangeType.newFeature,
        text:
            'Auto-Registration on Sign-In: whitelisted staff automatically link to Teachers Directory and learners auto-register in Students with zero duplicates.',
      ),
      ReleaseHighlight(
        type: ReleaseChangeType.newFeature,
        text:
            'Notifications & Speaking Club Alerts: targeted announcements (All, Teachers, Students, Specific Group, or Selected Users), Club Topic templates, unread bell badge, Web/Android push sync, and Firebase Analytics.',
      ),
      ReleaseHighlight(
        type: ReleaseChangeType.improved,
        text:
            'Events & Event History: Upcoming and Past Events grouped chronologically by month with flexible visibility controls and 1-click event notifications.',
      ),
    ],
  ),
  AppReleaseNote(
    version: '1.6.1',
    dateLabel: 'Nov 26, 2026',
    title: '120 FPS Turbo Rendering & Native High-Refresh Android Support',
    summary:
        'Eliminated multi-layer GPU blur overhead and enabled 120Hz+ native Android display mode selection with Vulkan Impeller.',
    highlights: [
      ReleaseHighlight(
        type: ReleaseChangeType.improved,
        text:
            '120 FPS Liquid Glass Engine: replaced 30+ continuous per-frame BackdropFilter shaders with cached GPU-friendly frosted glass layers, keeping live blur only on floating navigation chrome.',
      ),
      ReleaseHighlight(
        type: ReleaseChangeType.improved,
        text:
            'Android High-Refresh-Rate & Impeller: automatically selects maximum screen Hz (120Hz/144Hz) in MainActivity and removes continuous idle background repaints.',
      ),
    ],
  ),
  AppReleaseNote(
    version: '1.6.0',
    dateLabel: 'Nov 26, 2026',
    title: '6-Language Student Portal, Accessibility Fonts, Dark Default & 2GIS',
    summary:
        'Added green WhatsApp & tap-to-call phone buttons, 2GIS Bishkek building route launcher, 6-language extensible Student Portal localization, global text scaling, and Dark Mode by default.',
    highlights: [
      ReleaseHighlight(
        type: ReleaseChangeType.newFeature,
        text:
            'Student Portal 6 Languages: English, Русский, Кыргызча, Қазақша, Oʻzbekcha, and 中文 with clean key-map extensibility for adding future languages.',
      ),
      ReleaseHighlight(
        type: ReleaseChangeType.newFeature,
        text:
            'Accessibility Text Size & Default Dark Theme: configurable 100%–145% global font scaling and Dark/Light theme switcher saved locally.',
      ),
      ReleaseHighlight(
        type: ReleaseChangeType.newFeature,
        text:
            'Direct Center Actions: green WhatsApp icon buttons, tap-to-dial phone numbers, and 1-tap 2GIS directions to Ogonbaeva 222.',
      ),
    ],
  ),
  AppReleaseNote(
    version: '1.5.0',
    dateLabel: 'Nov 26, 2026',
    title: 'Center Schedule Sync, Sharing Privacy & Speed Optimization',
    summary:
        'Synchronized timetable with official Bishkek working hours, isolated Sharing groups strictly for staff, hardened Firestore security rules, and optimized Firebase read quotas.',
    highlights: [
      ReleaseHighlight(
        type: ReleaseChangeType.newFeature,
        text:
            'Official Center Hours & Contacts: Mon/Wed/Fri 08:30–19:00, Tue/Thu/Sat 09:00–18:00, Sunday Closed, plus Ogonbaeva 222 address & WhatsApp/phone links.',
      ),
      ReleaseHighlight(
        type: ReleaseChangeType.newFeature,
        text:
            'Sharing Confidentiality: Sharing groups and sessions are now hidden from all students at both UI and Cloud Firestore security rule levels.',
      ),
      ReleaseHighlight(
        type: ReleaseChangeType.improved,
        text:
            'Zero-Leak Security Hardening: split teacher salaries/phones, student rosters, and homework submissions into strict owner/staff collections with verified email checks.',
      ),
      ReleaseHighlight(
        type: ReleaseChangeType.improved,
        text:
            'Firebase Speed & Quota Savings: enabled IndexedDB local cache, scoped student queries, immutable asset caching, and capped log listeners to minimize free-tier reads.',
      ),
    ],
  ),
  AppReleaseNote(
    version: '1.4.0',
    dateLabel: 'Nov 26, 2026',
    title: 'Center Operations Suite & Teacher Changelog',
    summary:
        'Major production upgrade adding attendance auto-deduction, payments & teacher payroll, homework feedback, trial leads, reschedule requests, HSK progress tracking, CSV exports, and live activity logs.',
    highlights: [
      ReleaseHighlight(
        type: ReleaseChangeType.newFeature,
        text:
            'Attendance Journal: mark Present / Absent / Excused inside any lesson with automatic -1 lesson credit deduction (and safe +1 refund if changed).',
      ),
      ReleaseHighlight(
        type: ReleaseChangeType.newFeature,
        text:
            'Finance & Teacher Payroll: record student tuition payments, track monthly revenue, configure teacher hourly/club rates, and auto-calculate monthly payouts.',
      ),
      ReleaseHighlight(
        type: ReleaseChangeType.newFeature,
        text:
            'Homework Submissions & Feedback: students can submit answers or audio/photo links in Student Portal; teachers review and leave feedback.',
      ),
      ReleaseHighlight(
        type: ReleaseChangeType.newFeature,
        text:
            'Trial Leads & Reschedule Requests: track trial students through enrollment and approve/decline student reschedule requests in real time.',
      ),
      ReleaseHighlight(
        type: ReleaseChangeType.newFeature,
        text:
            'HSK / CEFR Progress Tracker: track topic mastery %, exam readiness, and display progress inside each student\'s portal.',
      ),
      ReleaseHighlight(
        type: ReleaseChangeType.newFeature,
        text:
            'WhatsApp / Telegram Reminders, CSV Schedule & Payroll Exports, and full Activity Audit Log + What\'s New changelog.',
      ),
    ],
  ),
  AppReleaseNote(
    version: '1.3.0',
    dateLabel: 'Nov 26, 2026',
    title: 'Groups, Homework & Student Portal',
    summary:
        'Introduced HSK & CEFR cohort management with 12-lesson tracking, teacher homework delivery, and open Google Student Portal.',
    highlights: [
      ReleaseHighlight(
        type: ReleaseChangeType.newFeature,
        text:
            'Study Groups tab with steady weekly schedule sync and per-student 12-lesson payment & remaining balance controls.',
      ),
      ReleaseHighlight(
        type: ReleaseChangeType.newFeature,
        text:
            'Open Google Sign-In Student Portal where learners select their HSK group and view assigned homework.',
      ),
      ReleaseHighlight(
        type: ReleaseChangeType.fixed,
        text:
            'Disabled aggressive PWA service-worker caching so updates reach browsers immediately.',
      ),
    ],
  ),
  AppReleaseNote(
    version: '1.2.0',
    dateLabel: 'Nov 26, 2026',
    title: 'Sharing Sessions & Multi-Teacher Support',
    summary:
        'Added open-chat Sharing sessions supporting multiple hosts and multiple students.',
    highlights: [
      ReleaseHighlight(
        type: ReleaseChangeType.newFeature,
        text:
            'New Sharing category with violet accents and multi-teacher co-host selection + clash detection.',
      ),
      ReleaseHighlight(
        type: ReleaseChangeType.newFeature,
        text:
            'Weekly recurring lessons (Mon/Wed/Fri presets) and ongoing Saturday Speaking Clubs (11:00 Chinese & 15:00 English) with responsible teacher picker.',
      ),
    ],
  ),
  AppReleaseNote(
    version: '1.1.0',
    dateLabel: 'Nov 26, 2026',
    title: 'Closed Google Staff Auth & Custom Domain',
    summary:
        'Launched live on thewordcenter.web.app with Google whitelist authentication and in-app colleague invites.',
    highlights: [
      ReleaseHighlight(
        type: ReleaseChangeType.newFeature,
        text:
            'Staff Access & Invites dialog allowing any authorized teacher to grant or revoke Google access.',
      ),
      ReleaseHighlight(
        type: ReleaseChangeType.improved,
        text:
            'Seeded center rooms (1–5, Hall, OldCenter) and teachers (Sharllote, Keith, Andrew, Sofia, Olga).',
      ),
    ],
  ),
];
