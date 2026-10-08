/// Phase 3 static content: Salah guide, Tajweed academy, Hajj & Umrah.
///
/// CONTENT POLICY (strict):
/// - Arabic phrases below are the universally-memorized wordings of the
///   five daily prayers (takbir, ruku/sujud dhikr, tashahhud, durood,
///   salam, talbiyah). Each carries its hadith/Quran source.
/// - Quranic quotes are copied from the bundled verified dataset
///   (assets/data/quran/quran_ara.json) — see the verification script
///   notes in PHASE3_NOTES.md. Nothing is paraphrased.
/// - Fiqh steps describe the undisputed standard practice; where madhhabs
///   differ, the difference is labeled explicitly and respectfully.
/// - No virtue claims, no invented references, no "general" wazaif-style
///   content.
library;

/// One step inside a guide (wudu, ghusl, prayer, hajj rite...).
class GuideStep {
  const GuideStep({
    required this.title,
    required this.detail,
    this.arabic,
    this.transliteration,
    this.translation,
    this.source,
    this.madhabNote,
  });

  final String title;
  final String detail;
  final String? arabic;
  final String? transliteration;
  final String? translation;
  final String? source;
  final String? madhabNote;
}

/// A complete guide: wudu, ghusl, or one prayer.
class SalahGuide {
  const SalahGuide({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.steps,
  });

  final String id;
  final String title;
  final String subtitle;
  final List<GuideStep> steps;
}

/// Shared Arabic wordings of the prayer (with sources).
class PrayerArabic {
  PrayerArabic._();

  static const takbir = (
    arabic: 'اللهُ أَكْبَرُ',
    translit: 'Allahu Akbar',
    translation: 'Allah is the Greatest',
    source: 'Sahih al-Bukhari & Sahih Muslim (every prayer)',
  );
  static const rukuDhikr = (
    arabic: 'سُبْحَانَ رَبِّيَ الْعَظِيمِ',
    translit: 'Subhana Rabbiyal-Azim',
    translation: 'Glory to my Lord, the Most Great',
    source: 'Sahih Muslim 772',
  );
  static const samiAllahu = (
    arabic: 'سَمِعَ اللَّهُ لِمَنْ حَمِدَهُ',
    translit: "Sami'allahu liman hamidah",
    translation: 'Allah hears the one who praises Him',
    source: 'Sahih al-Bukhari 796',
  );
  static const rabbanaLakalHamd = (
    arabic: 'رَبَّنَا لَكَ الْحَمْدُ',
    translit: 'Rabbana lakal-hamd',
    translation: 'Our Lord, to You belongs all praise',
    source: 'Sahih al-Bukhari 796',
  );
  static const sujudDhikr = (
    arabic: 'سُبْحَانَ رَبِّيَ الأَعْلَى',
    translit: "Subhana Rabbiyal-A'la",
    translation: 'Glory to my Lord, the Most High',
    source: 'Sahih Muslim 772',
  );
  static const tashahhud = (
    arabic:
        'التَّحِيَّاتُ لِلَّهِ وَالصَّلَوَاتُ وَالطَّيِّبَاتُ، السَّلاَمُ عَلَيْكَ أَيُّهَا النَّبِيُّ وَرَحْمَةُ اللَّهِ وَبَرَكَاتُهُ، السَّلاَمُ عَلَيْنَا وَعَلَى عِبَادِ اللَّهِ الصَّالِحِينَ، أَشْهَدُ أَنْ لاَ إِلَهَ إِلاَّ اللَّهُ وَأَشْهَدُ أَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُولُهُ',
    translit:
        'At-tahiyyatu lillahi was-salawatu wat-tayyibat. As-salamu alayka ayyuhan-nabiyyu wa rahmatullahi wa barakatuh. As-salamu alayna wa ala ibadillahis-salihin. Ash-hadu an la ilaha illallah, wa ash-hadu anna Muhammadan abduhu wa rasuluh.',
    translation:
        'All greetings, prayers and pure words are for Allah. Peace be upon you, O Prophet, and the mercy of Allah and His blessings. Peace be upon us and upon the righteous servants of Allah. I bear witness that none is worthy of worship but Allah, and I bear witness that Muhammad is His servant and Messenger.',
    source: 'Sahih al-Bukhari 831 (Ibn Mas\'ud)',
  );
  static const durood = (
    arabic:
        'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ كَمَا صَلَّيْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ إِنَّكَ حَمِيدٌ مَجِيدٌ، اللَّهُمَّ بَارِكْ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ كَمَا بَارَكْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ إِنَّكَ حَمِيدٌ مَجِيدٌ',
    translit:
        'Allahumma salli ala Muhammadin wa ala ali Muhammad, kama sallayta ala Ibrahima wa ala ali Ibrahim, innaka hamidun majid. Allahumma barik ala Muhammadin wa ala ali Muhammad, kama barakta ala Ibrahima wa ala ali Ibrahim, innaka hamidun majid.',
    translation:
        'O Allah, send prayers upon Muhammad and the family of Muhammad as You sent prayers upon Ibrahim and the family of Ibrahim; You are Praiseworthy, Glorious. O Allah, bless Muhammad and the family of Muhammad as You blessed Ibrahim and the family of Ibrahim; You are Praiseworthy, Glorious.',
    source: "Sahih al-Bukhari 3370 (Ka'b ibn Ujrah)",
  );
  static const salam = (
    arabic: 'السَّلاَمُ عَلَيْكُمْ وَرَحْمَةُ اللهِ',
    translit: 'As-salamu alaykum wa rahmatullah',
    translation: 'Peace and the mercy of Allah be upon you',
    source: 'Sahih Muslim 582',
  );
  static const rabbanaAtina = (
    arabic:
        'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
    translit:
        'Rabbana atina fid-dunya hasanah, wa fil-akhirati hasanah, wa qina adhaban-nar',
    translation:
        'Our Lord, give us good in this world and good in the Hereafter, and shield us from the punishment of the Fire',
    source: 'Quran 2:201 (also a recommended dua after durood)',
  );
  static const talbiyah = (
    arabic:
        'لَبَّيْكَ اللَّهُمَّ لَبَّيْكَ، لَبَّيْكَ لاَ شَرِيكَ لَكَ لَبَّيْكَ، إِنَّ الْحَمْدَ وَالنِّعْمَةَ لَكَ وَالْمُلْكَ، لاَ شَرِيكَ لَكَ',
    translit:
        'Labbaykallahumma labbayk, labbayka la sharika laka labbayk, innal-hamda wan-ni\'mata laka wal-mulk, la sharika lak',
    translation:
        'Here I am, O Allah, here I am. Here I am, You have no partner, here I am. All praise, grace and dominion belong to You. You have no partner.',
    source: 'Sahih al-Bukhari 1549 (Ibn Umar)',
  );
}

/// All Salah-guide content.
class SalahGuideData {
  SalahGuideData._();

  static const wudu = SalahGuide(
    id: 'wudu',
    title: 'Wudu (Ablution)',
    subtitle: 'Steps before every prayer · Sahih al-Bukhari 159 (Uthman ibn Affan)',
    steps: [
      GuideStep(
        title: '1 · Intention (Niyyah)',
        detail:
            'Make the intention in your heart to perform wudu for the sake of Allah. The intention is in the heart and is not spoken aloud.',
      ),
      GuideStep(
        title: '2 · Say Bismillah',
        detail: 'Begin by saying "Bismillah" (In the name of Allah).',
        arabic: 'بِسْمِ اللَّهِ',
        transliteration: 'Bismillah',
        translation: 'In the name of Allah',
        source: 'Sunan al-Tirmidhi 25',
      ),
      GuideStep(
        title: '3 · Wash the hands',
        detail: 'Wash both hands up to the wrists three times.',
      ),
      GuideStep(
        title: '4 · Rinse the mouth',
        detail: 'Take water into the mouth, rinse and spit out — three times.',
      ),
      GuideStep(
        title: '5 · Clean the nose',
        detail: 'Sniff water gently into the nose and blow it out — three times.',
      ),
      GuideStep(
        title: '6 · Wash the face',
        detail:
            'Wash the entire face from forehead to chin and ear to ear — three times.',
      ),
      GuideStep(
        title: '7 · Wash the arms',
        detail:
            'Wash the right arm up to and including the elbow three times, then the left arm three times.',
      ),
      GuideStep(
        title: '8 · Wipe the head',
        detail: 'Wipe over the head once with wet hands, front to back and back to front.',
      ),
      GuideStep(
        title: '9 · Wash the feet',
        detail:
            'Wash the right foot up to and including the ankle three times, then the left foot three times.',
      ),
    ],
  );

  static const ghusl = SalahGuide(
    id: 'ghusl',
    title: 'Ghusl (Full Bath)',
    subtitle: 'Required after major impurity · Sahih al-Bukhari 248 (Aisha)',
    steps: [
      GuideStep(
        title: '1 · Intention',
        detail: 'Intend in your heart to perform ghusl for purification.',
      ),
      GuideStep(
        title: '2 · Wash hands and private parts',
        detail: 'Wash both hands, then wash away any impurity from the private parts.',
      ),
      GuideStep(
        title: '3 · Perform wudu',
        detail: 'Perform a complete wudu as described above.',
      ),
      GuideStep(
        title: '4 · Pour water over the head',
        detail: 'Pour water over the head three times, reaching the roots of the hair.',
      ),
      GuideStep(
        title: '5 · Wash the whole body',
        detail:
            'Pour water over the entire body, starting with the right side, making sure water reaches everywhere.',
      ),
    ],
  );

  /// Builds the step list for a fard prayer with [fardRakhs] rak'ahs.
  static SalahGuide prayer({
    required String id,
    required String title,
    required String subtitle,
    required int fardRakhs,
    String? extraNote,
  }) {
    final steps = <GuideStep>[
      const GuideStep(
        title: 'Stand & intend',
        detail:
            'Stand facing the Qibla. Make the intention in your heart for this prayer (e.g. "I intend the 2 fard rak\'ahs of Fajr").',
        madhabNote:
            'Hand position: below the navel (Hanafi) or on the chest (Shafi\'i, Hanbali) — both are established practices.',
      ),
      GuideStep(
        title: 'Takbirat al-Ihram',
        detail: 'Raise both hands to the ears/shoulders and say the takbir.',
        arabic: PrayerArabic.takbir.arabic,
        transliteration: PrayerArabic.takbir.translit,
        translation: PrayerArabic.takbir.translation,
        source: PrayerArabic.takbir.source,
      ),
      const GuideStep(
        title: 'Qiyam — recitation',
        detail:
            'Fold your hands and recite Surah al-Fatihah, then any surah or verses you know (e.g. Surah al-Ikhlas). Recite silently in Dhuhr/Asr; the imam recites aloud in Fajr/Maghrib/Isha.',
      ),
      GuideStep(
        title: 'Ruku (bowing)',
        detail: 'Say the takbir, bow with a flat back and hands on the knees, and say the dhikr three times.',
        arabic: PrayerArabic.rukuDhikr.arabic,
        transliteration: PrayerArabic.rukuDhikr.translit,
        translation: PrayerArabic.rukuDhikr.translation,
        source: PrayerArabic.rukuDhikr.source,
      ),
      GuideStep(
        title: 'Rise from ruku',
        detail: 'Rise saying the first phrase, then stand still saying the second.',
        arabic:
            '${PrayerArabic.samiAllahu.arabic} — ${PrayerArabic.rabbanaLakalHamd.arabic}',
        transliteration:
            '${PrayerArabic.samiAllahu.translit} — ${PrayerArabic.rabbanaLakalHamd.translit}',
        translation:
            '${PrayerArabic.samiAllahu.translation} — ${PrayerArabic.rabbanaLakalHamd.translation}',
        source: PrayerArabic.samiAllahu.source,
      ),
      GuideStep(
        title: 'Sujud (prostration)',
        detail:
            'Say the takbir and prostrate on seven bones (forehead+nose, two hands, two knees, two feet), saying the dhikr three times.',
        arabic: PrayerArabic.sujudDhikr.arabic,
        transliteration: PrayerArabic.sujudDhikr.translit,
        translation: PrayerArabic.sujudDhikr.translation,
        source: PrayerArabic.sujudDhikr.source,
      ),
      const GuideStep(
        title: 'Sit & second sujud',
        detail:
            'Say the takbir, sit briefly (a short dua may be said), then prostrate a second time with the same dhikr. This completes one rak\'ah — stand up for the next.',
      ),
    ];

    if (fardRakhs == 2) {
      steps.add(_tashahhudDuroodSalam());
    } else if (fardRakhs == 3) {
      steps.add(const GuideStep(
        title: 'After 2 rak\'ahs — first Tashahhud',
        detail:
            'Sit and recite the Tashahhud, then stand for the third rak\'ah (recite only al-Fatihah in it).',
      ));
      steps.add(_tashahhudDuroodSalam(finalSitting: true));
    } else {
      steps.add(const GuideStep(
        title: 'After 2 rak\'ahs — first Tashahhud',
        detail:
            'Sit and recite the Tashahhud, then stand for the remaining rak\'ahs (recite only al-Fatihah in each).',
      ));
      steps.add(_tashahhudDuroodSalam(finalSitting: true));
    }

    if (extraNote != null) {
      steps.add(GuideStep(title: 'Note', detail: extraNote));
    }
    return SalahGuide(id: id, title: title, subtitle: subtitle, steps: steps);
  }

  static GuideStep _tashahhudDuroodSalam({bool finalSitting = false}) {
    return GuideStep(
      title: finalSitting ? 'Final sitting — Tashahhud, Durood, Salam' : 'Tashahhud, Durood & Salam',
      detail:
          'Sit for the tashahhud, then send salutations on the Prophet ﷺ, then end the prayer turning the head right and left.',
      arabic:
          '${PrayerArabic.tashahhud.arabic}\n\n${PrayerArabic.durood.arabic}\n\n${PrayerArabic.salam.arabic}',
      transliteration:
          '${PrayerArabic.tashahhud.translit}\n\n${PrayerArabic.durood.translit}\n\n${PrayerArabic.salam.translit}',
      translation:
          '${PrayerArabic.tashahhud.translation}\n\n${PrayerArabic.durood.translation}\n\n${PrayerArabic.salam.translation}',
      source:
          'Tashahhud: ${PrayerArabic.tashahhud.source} · Durood: ${PrayerArabic.durood.source} · Salam: ${PrayerArabic.salam.source}',
    );
  }

  static final List<SalahGuide> all = [
    wudu,
    ghusl,
    prayer(
      id: 'fajr',
      title: 'Fajr',
      subtitle: '2 fard rak\'ahs · from true dawn to sunrise',
      fardRakhs: 2,
    ),
    prayer(
      id: 'dhuhr',
      title: 'Dhuhr',
      subtitle: '4 fard rak\'ahs · after the sun passes its zenith',
      fardRakhs: 4,
    ),
    prayer(
      id: 'asr',
      title: 'Asr',
      subtitle: '4 fard rak\'ahs · afternoon',
      fardRakhs: 4,
      extraNote:
          'Asr start time differs: Standard (Shafi\'i, Maliki, Hanbali) — shadow equals one object-length; Hanafi — shadow equals two object-lengths. This app lets you choose in Prayer settings.',
    ),
    prayer(
      id: 'maghrib',
      title: 'Maghrib',
      subtitle: '3 fard rak\'ahs · just after sunset',
      fardRakhs: 3,
    ),
    prayer(
      id: 'isha',
      title: 'Isha',
      subtitle: '4 fard rak\'ahs · after twilight disappears',
      fardRakhs: 4,
    ),
    const SalahGuide(
      id: 'witr',
      title: 'Witr',
      subtitle: 'Odd-numbered rak\'ahs after Isha',
      steps: [
        GuideStep(
          title: 'How many rak\'ahs?',
          detail:
              'Witr is prayed in an odd number of rak\'ahs after Isha — most commonly 3.',
          madhabNote:
              'Hanafi: 3 rak\'ahs, treated as wajib (necessary). Shafi\'i / Maliki / Hanbali: 1, 3, 5 or more rak\'ahs, an emphasized sunnah. All agree it is prayed after Isha before Fajr.',
        ),
        GuideStep(
          title: 'The prayer',
          detail:
              'Pray like the fard prayers above. In the final rak\'ah, before or after ruku, raise the hands and recite Dua-e-Qunut (a supplication asking Allah for guidance and mercy). Then complete with tashahhud, durood and salam.',
          madhabNote:
              'Qunut placement and wording vary slightly between schools; any authentic supplication is valid.',
        ),
      ],
    ),
  ];
}

// ---------------------------------------------------------------------------
// TAJWEED ACADEMY
// ---------------------------------------------------------------------------

/// One tajweed lesson.
class TajweedLesson {
  const TajweedLesson({
    required this.id,
    required this.title,
    required this.intro,
    required this.rules,
    this.audioNote,
  });

  final String id;
  final String title;
  final String intro;
  final List<TajweedRule> rules;
  final String? audioNote;
}

class TajweedRule {
  const TajweedRule({
    required this.name,
    required this.explanation,
    required this.exampleArabic,
    required this.exampleRef,
    required this.exampleNote,
  });

  final String name;
  final String explanation;
  final String exampleArabic; // verbatim from bundled Quran data
  final String exampleRef; // e.g. "Quran 113:2"
  final String exampleNote;
}

/// One multiple-choice quiz question.
class TajweedQuizQ {
  const TajweedQuizQ({
    required this.question,
    required this.options,
    required this.answerIndex,
    required this.explain,
  });

  final String question;
  final List<String> options;
  final int answerIndex;
  final String explain;
}

class TajweedData {
  TajweedData._();

  static const List<TajweedLesson> lessons = [
    TajweedLesson(
      id: 'makharij',
      title: 'Makharij — Points of Articulation',
      intro:
          'Every Arabic letter is pronounced from a specific point (makhraj). The five main areas are: the empty space of the mouth/throat (الجوف) for the long vowels, the throat (الحلق), the tongue (اللسان), the lips (الشفتان), and the nasal cavity (الخيشوم) for ghunnah.',
      rules: [
        TajweedRule(
          name: 'Throat letters (حروف الحلق)',
          explanation:
              'ء ه ع ح غ خ — pronounced deep in the throat, e.g. the ع in prayer.',
          exampleArabic: 'أَعُوذُ',
          exampleRef: 'Quran 113:1 (first word after قُلْ)',
          exampleNote: 'The ع comes from the middle of the throat.',
        ),
        TajweedRule(
          name: 'Qalqalah letters (حروف القلقلة)',
          explanation:
              'ق ط ب ج د — when sakin (no vowel), they get a slight "echo/bounce".',
          exampleArabic: 'قُلْ أَعُوذُ',
          exampleNote: 'The ق in قُلْ bounces because it carries a sukun.',
          exampleRef: 'Quran 113:1',
        ),
      ],
      audioNote:
          'Audio examples for makharij need a licensed reciter recording — planned for a later phase.',
    ),
    TajweedLesson(
      id: 'noon-sakinah',
      title: 'Noon Sakinah & Tanween — 4 Rules',
      intro:
          'When نْ (noon with sukun) or tanween (ـًـٍـٌ) meets the next letter, one of four rules applies.',
      rules: [
        TajweedRule(
          name: 'Izhar — clear pronunciation',
          explanation:
              'Before ء ه ع ح غ خ, pronounce the noon clearly with no ghunnah.',
          exampleArabic: 'أَنْعَمْتَ',
          exampleRef: 'Quran 1:7',
          exampleNote: 'نْ before ع is read clearly: "an-amta".',
        ),
        TajweedRule(
          name: 'Idgham — merging',
          explanation:
              'Before ي ر م ل و ن, merge the noon into the next letter (with ghunnah except for ل and ر).',
          exampleArabic: 'مَن يَقُولُ',
          exampleRef: 'Quran 2:8',
          exampleNote: 'نْ before ي merges: "may-yaqūlu" with nasalization.',
        ),
        TajweedRule(
          name: 'Iqlab — conversion',
          explanation:
              'Before ب, the noon sound turns into a light م with ghunnah.',
          exampleArabic: 'أَنبِئْهُم',
          exampleRef: 'Quran 2:33',
          exampleNote: 'Read as "ambihum" — the ن becomes a hidden م.',
        ),
        TajweedRule(
          name: 'Ikhfa — hiding',
          explanation:
              'Before the remaining 15 letters, hide the noon with a light ghunnah.',
          exampleArabic: 'مِن شَرِّ',
          exampleRef: 'Quran 113:2',
          exampleNote: 'نْ before ش is softened with nasalization.',
        ),
      ],
    ),
    TajweedLesson(
      id: 'meem-sakinah',
      title: 'Meem Sakinah — 3 Rules',
      intro: 'A مْ (meem with sukun) follows three rules depending on the next letter.',
      rules: [
        TajweedRule(
          name: 'Ikhfa Shafawi',
          explanation: 'Before ب, hide the meem with ghunnah.',
          exampleArabic: 'هُم بِهِ',
          exampleRef: 'Quran 9:55',
          exampleNote: 'The م is softened before ب.',
        ),
        TajweedRule(
          name: 'Idgham Shafawi',
          explanation: 'Before another م, merge the two meems with ghunnah.',
          exampleArabic: 'لَكُم مَّا',
          exampleRef: 'Quran 2:29',
          exampleNote: 'The two meems merge into one lengthened sound.',
        ),
        TajweedRule(
          name: 'Izhar Shafawi',
          explanation: 'Before any other letter, pronounce the meem clearly.',
          exampleArabic: 'عَلَيْهِمْ غَيْرِ',
          exampleRef: 'Quran 1:7',
          exampleNote: 'The م before غ is read plainly.',
        ),
      ],
    ),
    TajweedLesson(
      id: 'madd',
      title: 'Madd — Elongation',
      intro:
          'Madd stretches vowel sounds. Natural madd (مَدّ طَبِيعِي) is 2 counts; some causes stretch to 4–5 or 6 counts.',
      rules: [
        TajweedRule(
          name: 'Madd Tabi\'i (natural, 2 counts)',
          explanation:
              'ا preceded by fatha, و preceded by damma, ي preceded by kasra — stretched 2 counts.',
          exampleArabic: 'قَالُوا',
          exampleRef: 'Common across the Quran',
          exampleNote: 'Each long vowel here gets 2 counts.',
        ),
        TajweedRule(
          name: 'Madd Lazim (6 counts)',
          explanation:
              'A long vowel followed by a permanent sukun — stretched 6 counts, the longest madd.',
          exampleArabic: 'الضَّالِّينَ',
          exampleRef: 'Quran 1:7',
          exampleNote: 'The ا before the doubled ل is held 6 counts.',
        ),
      ],
    ),
    TajweedLesson(
      id: 'qalqalah-detail',
      title: 'Qalqalah in Detail',
      intro:
          'Qalqalah ("shaking") applies to ق ط ب ج د with sukun. Stronger at the end of a stopped word (kubra) than mid-word (sughra).',
      rules: [
        TajweedRule(
          name: 'Qalqalah Sughra (minor)',
          explanation: 'Mid-word with sukun — a light bounce.',
          exampleArabic: 'قُلْ أَعُوذُ',
          exampleRef: 'Quran 113:1',
          exampleNote: 'ق carries a light echo.',
        ),
        TajweedRule(
          name: 'Qalqalah Kubra (major)',
          explanation: 'At a stop (end of ayah/word) — a stronger bounce.',
          exampleArabic: 'أَحَدٌ',
          exampleRef: 'Quran 112:1 (when stopping)',
          exampleNote: 'Stopping on د gives a clear echo: "ahad".',
        ),
      ],
      audioNote:
          'Hearing the bounce needs audio — licensed reciter audio is planned for a later phase.',
    ),
  ];

  static const List<TajweedQuizQ> quiz = [
    TajweedQuizQ(
      question: 'Noon sakinah followed by ب is which rule?',
      options: ['Izhar', 'Iqlab', 'Idgham'],
      answerIndex: 1,
      explain: 'Before ب, noon turns into a light meem — Iqlab. Example: أَنبِئْهُم (2:33).',
    ),
    TajweedQuizQ(
      question: 'Which set are the Qalqalah letters?',
      options: ['ا و ي', 'ق ط ب ج د', 'س ش ص ض'],
      answerIndex: 1,
      explain: 'ق ط ب ج د bounce when sakin. Example: قُلْ (113:1).',
    ),
    TajweedQuizQ(
      question: 'How many counts is natural (tabi\'i) madd?',
      options: ['2 counts', '4 counts', '6 counts'],
      answerIndex: 0,
      explain: 'Natural madd is 2 counts; 6 counts is madd lazim, e.g. الضَّالِّين (1:7).',
    ),
    TajweedQuizQ(
      question: 'مِن شَرِّ (113:2) is an example of…',
      options: ['Izhar', 'Ikhfa', 'Iqlab'],
      answerIndex: 1,
      explain: 'نْ before ش is hidden with ghunnah — Ikhfa.',
    ),
    TajweedQuizQ(
      question: 'Meem sakinah followed by another meem is…',
      options: ['Izhar Shafawi', 'Idgham Shafawi', 'Ikhfa Shafawi'],
      answerIndex: 1,
      explain: 'The two meems merge — Idgham Shafawi. Example: لَكُم مَّا (2:29).',
    ),
    TajweedQuizQ(
      question: 'أَنْعَمْتَ (1:7) is an example of…',
      options: ['Idgham', 'Izhar', 'Ikhfa'],
      answerIndex: 1,
      explain: 'نْ before ع (a throat letter) is read clearly — Izhar.',
    ),
  ];
}

// ---------------------------------------------------------------------------
// HAJJ & UMRAH
// ---------------------------------------------------------------------------

/// One rite/step in Hajj or Umrah.
class HajjStep {
  const HajjStep({
    required this.title,
    required this.detail,
    this.arabic,
    this.transliteration,
    this.translation,
    this.source,
    this.checklist = const [],
  });

  final String title;
  final String detail;
  final String? arabic;
  final String? transliteration;
  final String? translation;
  final String? source;
  final List<String> checklist;
}

class HajjUmrahData {
  HajjUmrahData._();

  static final List<HajjStep> hajj = [
    HajjStep(
      title: '1 · Ihram & intention',
      detail:
          'At the miqat (boundary), perform ghusl, wear the ihram garments, pray 2 rak\'ahs and make the intention for Hajj, then recite the Talbiyah aloud.',
      arabic: PrayerArabic.talbiyah.arabic,
      transliteration: PrayerArabic.talbiyah.translit,
      translation: PrayerArabic.talbiyah.translation,
      source: PrayerArabic.talbiyah.source,
      checklist: ['Ghusl performed', 'Ihram garments worn', 'Intention made', 'Talbiyah recited'],
    ),
    HajjStep(
      title: '2 · Tawaf al-Qudum',
      detail:
          'On reaching Makkah, perform 7 circuits of the Kaaba counter-clockwise, starting at the Black Stone. Men do raml (brisk walk) in the first 3 circuits.',
      checklist: ['7 circuits completed', '2 rak\'ahs behind Maqam Ibrahim'],
    ),
    HajjStep(
      title: "3 · Sa'i",
      detail:
          'Walk 7 times between Safa and Marwa (Safa → Marwa = 1). Men jog between the green markers.',
      checklist: ['7 rounds completed'],
    ),
    HajjStep(
      title: '4 · Mina — 8th Dhul Hijjah (Tarwiyah)',
      detail:
          'Go to Mina and stay the night. Pray Dhuhr, Asr, Maghrib, Isha and Fajr there, shortening 4-rak\'ah prayers to 2.',
    ),
    HajjStep(
      title: '5 · Arafat — 9th Dhul Hijjah (Wuquf)',
      detail:
          'The essence of Hajj. Stand at Arafat from midday until sunset in dua and remembrance — "Hajj is Arafat" (al-Tirmidhi 889).',
      source: 'Jami\' al-Tirmidhi 889',
    ),
    HajjStep(
      title: '6 · Muzdalifah',
      detail:
          'After sunset, go to Muzdalifah. Pray Maghrib and Isha combined, rest, and collect pebbles for the stoning.',
      checklist: ['Pebbles collected (≈49–70)'],
    ),
    HajjStep(
      title: '7 · Rami — 10th Dhul Hijjah',
      detail:
          'Stone Jamarat al-Aqaba (the largest pillar) with 7 pebbles, saying "Allahu Akbar" with each throw.',
      arabic: 'اللهُ أَكْبَرُ',
      transliteration: 'Allahu Akbar',
      translation: 'Allah is the Greatest',
      checklist: ['7 pebbles thrown at Aqaba'],
    ),
    HajjStep(
      title: '8 · Sacrifice (Qurbani)',
      detail: 'Offer the sacrificial animal. This is obligatory for Hajj al-Tamattu\' and al-Qiran.',
    ),
    HajjStep(
      title: '9 · Halq / Taqsir',
      detail: 'Shave the head (men) or trim a fingertip-length of hair (women). Ihram restrictions now lift (except marital relations).',
    ),
    HajjStep(
      title: '10 · Tawaf al-Ifadah',
      detail: 'Return to Makkah for the 7-circuit Tawaf al-Ifadah, followed by Sa\'i if not done earlier.',
      checklist: ['Tawaf al-Ifadah done', "Sa'i done"],
    ),
    HajjStep(
      title: '11 · Days of Tashreeq (11–13th)',
      detail:
          'Stay in Mina and stone all three jamarat each day (7 pebbles each, starting with the smallest). You may leave after the 12th.',
      checklist: ['Day 11 rami done', 'Day 12 rami done', 'Day 13 rami done (or departed)'],
    ),
    HajjStep(
      title: '12 · Tawaf al-Wada (farewell)',
      detail: 'Before leaving Makkah, perform the farewell tawaf of 7 circuits.',
    ),
  ];

  static final List<HajjStep> umrah = [
    HajjStep(
      title: '1 · Ihram',
      detail:
          'At the miqat, ghusl, ihram garments, 2 rak\'ahs, intention for Umrah, and the Talbiyah.',
      arabic: PrayerArabic.talbiyah.arabic,
      transliteration: PrayerArabic.talbiyah.translit,
      translation: PrayerArabic.talbiyah.translation,
      source: PrayerArabic.talbiyah.source,
      checklist: ['Ghusl performed', 'Ihram garments worn', 'Intention made', 'Talbiyah recited'],
    ),
    HajjStep(
      title: '2 · Tawaf',
      detail: '7 circuits of the Kaaba counter-clockwise starting at the Black Stone, then 2 rak\'ahs behind Maqam Ibrahim.',
      checklist: ['7 circuits completed', '2 rak\'ahs behind Maqam Ibrahim'],
    ),
    HajjStep(
      title: "3 · Sa'i",
      detail: '7 rounds between Safa and Marwa.',
      checklist: ['7 rounds completed'],
    ),
    HajjStep(
      title: '4 · Halq / Taqsir',
      detail: 'Shave (men) or trim (women) the hair. Umrah is now complete.',
    ),
  ];

  static const List<String> warnings = [
    'Hajj requires an official permit and visa — only travel with authorized, licensed groups.',
    'Book early: quotas fill months ahead. Never use unofficial "guaranteed Hajj" offers.',
    'Get vaccinations required by Saudi authorities and carry your medication.',
    'The rites involve long walks in heat — prepare physically and stay hydrated.',
    'Keep your passport, permits and emergency contacts on you at all times.',
  ];
}
