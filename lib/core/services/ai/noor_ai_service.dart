import 'package:flutter/foundation.dart';

import '../../../data/repositories/content_repository.dart';
import '../../../data/repositories/hadith_repository.dart';
import '../../../data/repositories/quran_repository.dart';
import '../../../features/tasbeeh/tasbeeh_presets.dart';

/// A single chat message.
class NoorAiMessage {
  NoorAiMessage({required this.role, required this.text, this.sources = const []});
  final String role; // 'user' | 'assistant'
  final String text;
  final List<String> sources;
}

/// Answer from Noor AI. [sources] are human-readable citations
/// (e.g. "Quran 2:255", "Sahih al-Bukhari · Hadith 1").
/// [isUncertain] marks answers the user should verify with a scholar.
class NoorAiReply {
  const NoorAiReply({
    required this.text,
    this.sources = const [],
    this.isUncertain = false,
  });
  final String text;
  final List<String> sources;
  final bool isUncertain;
}

/// Noor AI — source-grounded Islamic Q&A.
///
/// Contract (safety-critical):
///   * Answers ONLY from the app's bundled verified datasets
///     (Quran / Hadith / Dua repositories).
///   * NEVER invents verses, hadith, dua wordings, references or rulings.
///   * Says "I don't know" when nothing verified matches.
///   * Refuses personal fatwa questions, directing to a qualified scholar.
///   * Every religious quote carries its source line.
abstract class NoorAiService {
  /// [lang]: 'en' | 'ur' | 'roman' | 'ar' — controls the wrapper language.
  /// Quoted religious text always comes verbatim from the dataset.
  Future<NoorAiReply> ask(String query, {String lang = 'en'});
}

/// Local implementation: keyword intent matching over bundled data.
/// No network, no LLM — fully deterministic and auditable.
class LocalNoorAiService implements NoorAiService {
  LocalNoorAiService({
    QuranRepository? quran,
    HadithRepository? hadith,
    ContentRepository? content,
  })  : _quran = quran ?? QuranRepository.instance,
        _hadith = hadith ?? HadithRepository.instance,
        _content = content ?? ContentRepository.instance;

  final QuranRepository _quran;
  final HadithRepository _hadith;
  final ContentRepository _content;

  // --- keyword sets (English + Roman Urdu + Urdu) ---

  static const _fatwaKeys = {
    'halal', 'haram', 'fatwa', 'divorce', 'talaq', 'khula',
    'inheritance', 'wirasat', 'meerath', 'zina', 'verdict', 'ruling on',
    'is it permissible', 'jayaz', 'najayaz', 'haraam', 'halaal',
    'طلاق', 'حلال', 'حرام', 'فتوی', 'وراثت',
  };

  static const _greetKeys = {
    'hello', 'hi', 'salam', 'assalam', 'aoa', 'hey',
    'السلام', 'سلام',
  };

  static const _duaKeys = {
    'dua', 'duaa', 'prayer for', 'supplication',
    'dain', 'deen', 'duain', 'دعا',
  };

  static const _hadithKeys = {
    'hadith', 'hadees', 'hadeeth', 'hadis', 'sunnah',
    'حدیث', 'حديث',
  };

  static const _ayahKeys = {
    'ayah', 'ayat', 'verse', 'surah', 'quran says', 'قرآن', 'آیت', 'سورۃ', 'آية',
  };

  static const _prayerHowKeys = {
    'how to pray', 'namaz', 'salah', 'prayer method', 'namaz ka tarika',
    'namaz parhne', 'rakat', "rak'ah", 'نماز',
  };

  static const _wuduKeys = {'wudu', 'wuzu', 'ablution', 'ghusl', 'وضو', 'غسل'};

  static const _fastKeys = {
    'fast', 'roza', 'ramadan', 'sehri', 'iftar', 'suhoor',
    'روزہ', 'رمضان', 'سحری', 'افطار',
  };

  static const _zakatKeys = {'zakat', 'nisab', 'زکاۃ', 'زكاة', 'نصاب'};

  static const _qiblaKeys = {'qibla', 'kibla', 'direction', 'قبلہ'};

  static const _dhikrKeys = {
    'dhikr', 'zikr', 'tasbeeh', 'tasbih', 'ذكر', 'تسبیح',
  };

  static const _stopwords = {
    'the', 'a', 'an', 'is', 'are', 'what', 'which', 'who', 'whom', 'whose',
    'when', 'where', 'why', 'how', 'do', 'does', 'did', 'can', 'could',
    'should', 'would', 'will', 'tell', 'me', 'about', 'for', 'of', 'in',
    'on', 'to', 'and', 'or', 'please', 'ko', 'ka', 'ki', 'ke', 'mein',
    'hai', 'hain', 'kya', 'batao', 'bata', 'mujhe', 'kia',
  };

  bool _hasAny(String q, Set<String> keys) {
    for (final k in keys) {
      if (q.contains(k)) return true;
    }
    return false;
  }

  /// Content words used for repository search (stopwords stripped).
  String _searchTerms(String q) {
    final words = q
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2 && !_stopwords.contains(w))
        .toList();
    return words.take(4).join(' ');
  }

  @override
  Future<NoorAiReply> ask(String query, {String lang = 'en'}) async {
    final q = query.trim();
    if (q.isEmpty) return _t(lang).empty;
    final ql = q.toLowerCase();

    try {
      // 1. Fatwa guard — always first.
      if (_hasAny(ql, _fatwaKeys)) return _t(lang).fatwaRefusal;

      // 2. Greeting.
      if (_hasAny(ql, _greetKeys) && ql.length < 30) return _t(lang).greeting;

      // 3. Feature intents (point at real in-app screens).
      if (_hasAny(ql, _prayerHowKeys)) return _t(lang).prayerGuide;
      if (_hasAny(ql, _wuduKeys)) return _t(lang).wuduGuide;
      if (_hasAny(ql, _qiblaKeys)) return _t(lang).qiblaGuide;
      if (_hasAny(ql, _fastKeys)) return _t(lang).fastingGuide;
      if (_hasAny(ql, _zakatKeys)) return _t(lang).zakatGuide;
      if (_hasAny(ql, _dhikrKeys)) return _dhikrReply(lang);

      // 4. Content intents — search bundled verified datasets.
      final terms = _searchTerms(ql);
      if (_hasAny(ql, _duaKeys) || _hasAny(ql, _ayahKeys) || _hasAny(ql, _hadithKeys) || terms.isNotEmpty) {
        final reply = await _answerFromData(terms, lang);
        if (reply != null) return reply;
      }

      // 5. Honest fallback.
      return _t(lang).dontKnow;
    } catch (e) {
      debugPrint('Noor-e-Deen NoorAi failed: $e');
      return _t(lang).error;
    }
  }

  /// Search duas → hadith → quran in order; first verified hit wins.
  Future<NoorAiReply?> _answerFromData(String terms, String lang) async {
    if (terms.isEmpty) return null;
    final t = _t(lang);

    // Duas.
    try {
      final duas = await _content.searchDuas(terms);
      if (duas.isNotEmpty) {
        final d = duas.first;
        final buf = StringBuffer();
        buf.writeln(t.duaFound(d.title));
        buf.writeln();
        buf.writeln(d.arabic);
        final translit = d.transliteration;
        if (translit != null && translit.isNotEmpty) {
          buf.writeln();
          buf.writeln(translit);
        }
        final tr = lang == 'ur' ? d.urdu : d.english;
        if (tr != null && tr.isNotEmpty) {
          buf.writeln();
          buf.writeln(tr);
        }
        return NoorAiReply(
          text: buf.toString().trim(),
          sources: ['Dua: ${d.title} — ${d.source}'],
        );
      }
    } catch (_) {/* continue */}

    // Hadith (Bukhari first, then Muslim).
    for (final col in ['bukhari', 'muslim']) {
      try {
        final hits = await _hadith.search(col, terms);
        if (hits.isNotEmpty) {
          final h = hits.first;
          final text = '${t.hadithFound(h.collectionName)}\n\n'
              '${h.text}\n\n${t.sourceLabel}: ${h.sourceLine}';
          return NoorAiReply(
            text: text,
            sources: [h.sourceLine],
          );
        }
      } catch (_) {/* continue */}
    }

    // Quran.
    try {
      final ayahs = await _quran.search(terms);
      if (ayahs.isNotEmpty) {
        final a = ayahs.first;
        final buf = StringBuffer();
        buf.writeln(t.ayahFound('${a.surah}:${a.number}'));
        buf.writeln();
        buf.writeln(a.arabic);
        final tr = lang == 'ur' ? a.urdu : a.english;
        if (tr.isNotEmpty) {
          buf.writeln();
          buf.writeln(tr);
        }
        return NoorAiReply(
          text: buf.toString().trim(),
          sources: ['Quran ${a.surah}:${a.number}'],
        );
      }
    } catch (_) {/* continue */}

    return null;
  }

  NoorAiReply _dhikrReply(String lang) {
    final t = _t(lang);
    final buf = StringBuffer(t.dhikrIntro);
    buf.writeln();
    for (final d in TasbeehPresets.items) {
      buf.writeln('• $d');
    }
    return NoorAiReply(text: buf.toString().trim());
  }

  _Templates _t(String lang) {
    switch (lang) {
      case 'ur':
        return _Templates.urdu();
      case 'roman':
        return _Templates.roman();
      case 'ar':
        return _Templates.arabic();
      case 'en':
      default:
        return _Templates.english();
    }
  }
}

/// UI wrapper strings per language. These are interface text written by the
/// developers — never religious content, which always comes from datasets.
class _Templates {
  const _Templates({
    required this.empty,
    required this.greeting,
    required this.fatwaRefusal,
    required this.dontKnow,
    required this.error,
    required this.prayerGuide,
    required this.wuduGuide,
    required this.qiblaGuide,
    required this.fastingGuide,
    required this.zakatGuide,
    required this.dhikrIntro,
    required this.sourceLabel,
    required this.duaFound,
    required this.hadithFound,
    required this.ayahFound,
  });

  final NoorAiReply empty;
  final NoorAiReply greeting;
  final NoorAiReply fatwaRefusal;
  final NoorAiReply dontKnow;
  final NoorAiReply error;
  final NoorAiReply prayerGuide;
  final NoorAiReply wuduGuide;
  final NoorAiReply qiblaGuide;
  final NoorAiReply fastingGuide;
  final NoorAiReply zakatGuide;
  final String dhikrIntro;
  final String sourceLabel;
  final String Function(String title) duaFound;
  final String Function(String collection) hadithFound;
  final String Function(String ref) ayahFound;

  factory _Templates.english() => _Templates(
        empty: const NoorAiReply(text: 'Please type a question first.'),
        greeting: const NoorAiReply(
          text: 'Assalamu alaikum! I am Noor AI. Ask me about duas, '
              'hadith, Quran verses, prayer, fasting, or zakat — I answer '
              'only from verified sources in this app.',
        ),
        fatwaRefusal: const NoorAiReply(
          text: 'I cannot give personal religious rulings (fatwa) — '
              'questions about halal/haram, divorce, or inheritance need a '
              'qualified scholar who knows your full situation. Please '
              'consult one directly.',
          isUncertain: true,
        ),
        dontKnow: const NoorAiReply(
          text: 'I could not find a verified answer in this app\'s sources. '
              'I will not guess — please browse the Quran, Hadith, or Dua '
              'sections, or ask a qualified scholar.',
          isUncertain: true,
        ),
        error: const NoorAiReply(
          text: 'Something went wrong while searching. Please try again.',
          isUncertain: true,
        ),
        prayerGuide: const NoorAiReply(
          text: 'Open the Salah Guide (Explore → Salah Guide) for step-by-step '
              'prayer instructions with Arabic, transliteration, translation '
              'and hadith sources, including wudu and ghusl.',
        ),
        wuduGuide: const NoorAiReply(
          text: 'Open the Salah Guide (Explore → Salah Guide → Wudu/Ghusl) '
              'for the verified step-by-step method with hadith sources.',
        ),
        qiblaGuide: const NoorAiReply(
          text: 'Open the Qibla screen (Home → Qibla) for the direction of '
              'the Kaaba from your location, with calibration guidance.',
        ),
        fastingGuide: const NoorAiReply(
          text: 'Open Ramadan (Explore → Ramadan) for sehri/iftar times, the '
              'fasting tracker, taraweeh information and the Laylat-ul-Qadr '
              'planner.',
        ),
        zakatGuide: const NoorAiReply(
          text: 'Open the Zakat Calculator (Explore → Zakat). It uses 2.5% '
              'over the nisab (87.48 g gold or 612.36 g silver) — the result '
              'is an estimate; please confirm personal cases with a scholar.',
        ),
        dhikrIntro: 'The app\'s Tasbeeh presets (open Tasbeeh to count):',
        sourceLabel: 'Source',
        duaFound: (title) => 'Here is the dua "$title" from the app\'s verified library:',
        hadithFound: (c) => 'From $c:',
        ayahFound: (ref) => 'Quran $ref:',
      );

  factory _Templates.urdu() => _Templates(
        empty: const NoorAiReply(text: 'پہلے کوئی سوال لکھیں۔'),
        greeting: const NoorAiReply(
          text: 'السلام علیکم! میں نور AI ہوں۔ مجھ سے دعاؤں، احادیث، قرآنی آیات، '
              'نماز، روزے یا زکاۃ کے بارے میں پوچھیں — میں صرف اس ایپ کے '
              'مصدقہ ذرائع سے جواب دیتا ہوں۔',
        ),
        fatwaRefusal: const NoorAiReply(
          text: 'میں ذاتی شرعی فتوے نہیں دے سکتا — حلال/حرام، طلاق یا وراثت '
              'کے سوالات کے لیے کسی مستند عالم سے رجوع کریں۔',
          isUncertain: true,
        ),
        dontKnow: const NoorAiReply(
          text: 'اس ایپ کے ذرائع میں مجھے کوئی مصدقہ جواب نہیں ملا۔ میں اندازہ '
              'نہیں لگاؤں گا — قرآن، حدیث یا دعا کے سیکشن دیکھیں یا کسی عالم '
              'سے پوچھیں۔',
          isUncertain: true,
        ),
        error: const NoorAiReply(
          text: 'تلاش کے دوران مسئلہ ہوا۔ دوبارہ کوشش کریں۔',
          isUncertain: true,
        ),
        prayerGuide: const NoorAiReply(
          text: 'نماز کا مکمل طریقہ دیکھنے کے لیے "Salah Guide" کھولیں '
              '(Explore → Salah Guide) — عربی، transliteration، ترجمہ اور '
              'احادیث کے حوالوں کے ساتھ۔',
        ),
        wuduGuide: const NoorAiReply(
          text: '"Salah Guide" میں وضو اور غسل کا مصدقہ طریقہ دیکھیں۔',
        ),
        qiblaGuide: const NoorAiReply(
          text: 'قبلہ کی سمت کے لیے "Qibla" اسکرین کھولیں۔',
        ),
        fastingGuide: const NoorAiReply(
          text: 'سحری/افطاری کے اوقات اور روزوں کی تفصیل کے لیے "Ramadan" '
              'سیکشن کھولیں۔',
        ),
        zakatGuide: const NoorAiReply(
          text: '"Zakat Calculator" کھولیں — نصاب (87.48 گرام سونا یا 612.36 '
              'گرام چاندی) پر 2.5٪۔ یہ تخمینہ ہے؛ ذاتی معاملات عالم سے پوچھیں۔',
        ),
        dhikrIntro: 'ایپ کے تسبیح کے اذکار (گننے کے لیے Tasbeeh کھولیں):',
        sourceLabel: 'حوالہ',
        duaFound: (title) => 'مصدقہ لائبریری سے دعا "$title":',
        hadithFound: (c) => '$c سے:',
        ayahFound: (ref) => 'قرآن $ref:',
      );

  factory _Templates.roman() => _Templates(
        empty: const NoorAiReply(text: 'Pehle koi sawal likhein.'),
        greeting: const NoorAiReply(
          text: 'Assalamu alaikum! Main Noor AI hun. Mujh se duaon, hadith, '
              'Quran ki ayaat, namaz, rozay ya zakat ke baare mein poochein — '
              'main sirf is app ke verified sources se jawab deta hun.',
        ),
        fatwaRefusal: const NoorAiReply(
          text: 'Main personal fatwa nahi de sakta — halal/haram, talaq ya '
              'virasat ke sawalon ke liye kisi qualified aalim se rujoo karein.',
          isUncertain: true,
        ),
        dontKnow: const NoorAiReply(
          text: 'Is app ke sources mein mujhe koi verified jawab nahi mila. '
              'Main andaza nahi lagaunga — Quran, Hadith ya Dua section '
              'dekhein ya kisi aalim se poochein.',
          isUncertain: true,
        ),
        error: const NoorAiReply(
          text: 'Search ke dauran masla hua. Dobara try karein.',
          isUncertain: true,
        ),
        prayerGuide: const NoorAiReply(
          text: 'Namaz ka complete tarika "Salah Guide" mein dekhein '
              '(Explore → Salah Guide) — Arabic, transliteration, tarjuma '
              'aur hadith references ke saath.',
        ),
        wuduGuide: const NoorAiReply(
          text: '"Salah Guide" mein wudu aur ghusl ka verified tarika dekhein.',
        ),
        qiblaGuide: const NoorAiReply(
          text: 'Qibla direction ke liye "Qibla" screen kholein.',
        ),
        fastingGuide: const NoorAiReply(
          text: 'Sehri/iftar timings aur rozon ki details ke liye "Ramadan" '
              'section kholein.',
        ),
        zakatGuide: const NoorAiReply(
          text: '"Zakat Calculator" kholein — nisab (87.48g sona ya 612.36g '
              'chandi) par 2.5%. Ye estimate hai; personal cases aalim se '
              'poochein.',
        ),
        dhikrIntro: 'App ke Tasbeeh presets (ginne ke liye Tasbeeh kholein):',
        sourceLabel: 'Source',
        duaFound: (title) => 'Verified library se dua "$title":',
        hadithFound: (c) => '$c se:',
        ayahFound: (ref) => 'Quran $ref:',
      );

  factory _Templates.arabic() => _Templates(
        empty: const NoorAiReply(text: 'اكتب سؤالاً أولاً.'),
        greeting: const NoorAiReply(
          text: 'السلام عليكم! أنا نور AI. اسألني عن الأدعية أو الأحاديث أو '
              'آيات القرآن أو الصلاة أو الصيام أو الزكاة — أجيب فقط من '
              'المصادر الموثوقة في هذا التطبيق.',
        ),
        fatwaRefusal: const NoorAiReply(
          text: 'لا أستطيع إصدار فتاوى شخصية — أسئلة الحلال والحرام والطلاق '
              'والميراث تحتاج إلى عالم مؤهل. يرجى استشارته مباشرة.',
          isUncertain: true,
        ),
        dontKnow: const NoorAiReply(
          text: 'لم أجد إجابة موثوقة في مصادر هذا التطبيق. لن أخمّن — تصفح '
              'أقسام القرآن أو الحديث أو الدعاء، أو اسأل عالماً مؤهلاً.',
          isUncertain: true,
        ),
        error: const NoorAiReply(
          text: 'حدث خطأ أثناء البحث. حاول مرة أخرى.',
          isUncertain: true,
        ),
        prayerGuide: const NoorAiReply(
          text: 'افتح "Salah Guide" (Explore) لخطوات الصلاة مع العربية '
              'والترجمة ومصادر الأحاديث.',
        ),
        wuduGuide: const NoorAiReply(
          text: 'طريقة الوضوء والغسل الموثوقة في "Salah Guide".',
        ),
        qiblaGuide: const NoorAiReply(
          text: 'افتح شاشة "Qibla" لاتجاه الكعبة من موقعك.',
        ),
        fastingGuide: const NoorAiReply(
          text: 'أوقات السحور والإفطار في قسم "Ramadan".',
        ),
        zakatGuide: const NoorAiReply(
          text: 'افتح "Zakat Calculator" — النصاب (87.48 غرام ذهب أو 612.36 '
              'غرام فضة) بنسبة 2.5٪. هذا تقدير؛ استشر عالماً للحالات الشخصية.',
        ),
        dhikrIntro: 'أذكار التسبيح في التطبيق (افتح Tasbeeh للعدّ):',
        sourceLabel: 'المصدر',
        duaFound: (title) => 'من المكتبة الموثوقة، دعاء "$title":',
        hadithFound: (c) => 'من $c:',
        ayahFound: (ref) => 'القرآن $ref:',
      );
}

/// Remote LLM integration point (documented, not active).
///
/// To activate: set NOOR_AI_API_URL + NOOR_AI_API_KEY (see .env.example),
/// pointing at an OpenAI-compatible chat endpoint, then wire this class in
/// AppServices. Even with a remote model, ALL religious claims must be
/// validated against the bundled datasets before display — the local
/// service remains the source-grounding layer.
class RemoteNoorAiService implements NoorAiService {
  RemoteNoorAiService({this.apiUrl, this.apiKey});

  final String? apiUrl;
  final String? apiKey;

  bool get isConfigured =>
      apiUrl != null && apiUrl!.isNotEmpty && apiKey != null && apiKey!.isNotEmpty;

  @override
  Future<NoorAiReply> ask(String query, {String lang = 'en'}) async {
    if (!isConfigured) {
      return const NoorAiReply(
        text: 'Remote AI is not configured. Set NOOR_AI_API_URL and '
            'NOOR_AI_API_KEY (see .env.example) to enable it. '
            'The built-in local assistant is answering instead.',
        isUncertain: true,
      );
    }
    // Integration point: POST {model, messages} to apiUrl with the key.
    // Religious grounding: pipe the model draft through LocalNoorAiService
    // dataset checks before showing. Not implemented until credentials exist.
    return const NoorAiReply(
      text: 'Remote AI integration is documented but not yet connected.',
      isUncertain: true,
    );
  }
}
