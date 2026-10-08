# DATA_SOURCES.md — Noor-e-Deen Islamic Super App

All religious text in this app is loaded from the verified published datasets below.
Nothing is generated, paraphrased, or invented by the app or its builders.
Compiled 8 Oct 2026.

# Quran Data Sources — Noor-e-Deen Islamic Super App

Fetched: 8 Oct 2026 (BST). Fetcher: Quran DATA subagent (downloaded datasets only — no text was generated or altered).

## Dataset

- **Name:** fawazahmed0/quran-api
- **Repo:** https://github.com/fawazahmed0/quran-api
- **CDN used:** https://cdn.jsdelivr.net/gh/fawazahmed0/quran-api@1/editions/{EDITION}/{N}.json (N = 1..114)
- **Description:** Community-verified per-surah JSON editions of the Quran; Arabic text is **Tanzil-derived Uthmani script** (with full diacritics).

## Editions used

| Edition key (in URL)        | Language | Content |
|-----------------------------|----------|---------|
| `ara-quranuthmanihaf`       | Arabic   | Uthmani script with diacritics (Tanzil-derived) |
| `urd-muhammadjunagar`       | Urdu     | Translation by **Muhammad Junagarhi** |
| `eng-mustafakhattaba`       | English  | **"The Clear Quran"** by **Dr Mustafa Khattab** |

Per-file format: `{"chapter": [{"chapter": N, "verse": M, "text": "..."}, ...]}`

## Surah metadata

- **Source:** quran.com API v4 — `https://api.quran.com/api/v4/chapters?language=en`
- Converted to: `[{"id","name","arabic","verses","revelation","meaning"}, ...]` for all 114 surahs
- Example: `{"id":1,"name":"Al-Fatihah","arabic":"الفاتحة","verses":7,"revelation":"makkah","meaning":"The Opener"}`
- Note: `revelation` values are lowercase `"makkah"` / `"madinah"` as returned by the API.

## Font

- **Name:** Amiri Quran (Regular)
- **License:** SIL Open Font License (OFL) — free for app use, including embedding.
- **URL (primary, used):** https://github.com/google/fonts/raw/main/ofl/amiriquran/AmiriQuran-Regular.ttf
- Fallback (not needed): https://github.com/google/fonts/raw/main/ofl/amiri/Amiri-Regular.ttf
- Verified: magic `00 01 00 00` (valid TrueType), 136,920 bytes (>100 KB).

## Assets built

Location: `/home/hatch/workspace/noor-e-deen/assets/data/quran/`

| File | Size | Content |
|------|------|---------|
| `quran_ara.json` | 1,421,026 B | `{"surahs": {"1": {"1": "…"}, …}}` — Arabic Uthmani, ayah numbers as string keys |
| `quran_urd.json` | 1,459,218 B | same structure — Junagarhi Urdu translation |
| `quran_eng.json` | 907,788 B | same structure — Khattab "The Clear Quran" |
| `surahs.json` | 12,731 B | 114-entry metadata array |

Font: `/home/hatch/workspace/noor-e-deen/assets/fonts/AmiriQuran-Regular.ttf` (136,920 B)

Raw per-surah files retained at `/tmp/quran_raw/{edition}/{1..114}.json` (ephemeral).

## Verification results (all PASSED)

1. **File counts:** all 3 editions contain exactly files 1..114.
2. **Ayah counts (spot checks):** Surah 1 = 7, Surah 2 = 286, Surah 114 = 6 — all correct in all 3 editions; verse numbering sequential 1..N in every file.
3. **Cross-edition consistency:** all 114 surahs have identical ayah counts across the 3 editions; **6,236 ayahs total** per edition.
4. **Text checks:**
   - Arabic 1:1 = `بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ` — contains diacritics (harakat) ✓
   - Urdu 1:1 = `شروع کرتا ہوں اللہ تعالیٰ کے نام سے جو بڑا مہربان نہایت رحم واﻻ ہے` — Urdu script ✓
   - English 1:1 = `In the Name of Allah—the Most Compassionate, Most Merciful` — English ✓

## Download issues encountered

- First pass: 2 files missing — `eng-mustafakhattaba/31.json` (HTTP 403 on jsDelivr) and `eng-mustafakhattaba/86.json` (HTTP 404 on jsDelivr).
- Resolution: re-downloaded both from `https://raw.githubusercontent.com/fawazahmed0/quran-api/1/editions/eng-mustafakhattaba/{31,86}.json` (HTTP 200). Contents verified with the same checks as all other files.
- **No exclusions:** all 342 files present and verified; nothing was fabricated or skipped.

---

# Hadith Data Sources — Noor-e-Deen App

Fetched: 2026-10-08

## Dataset repository

**fawazahmed0/hadith-api** — open-source Hadith datasets/API on GitHub,
served via jsDelivr CDN at `https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/`

- Repo: https://github.com/fawazahmed0/hadith-api
- Editions index (used for translator attribution):
  `https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions.min.json`
- All files below are verbatim published datasets. No text was generated,
  paraphrased, or "completed" by the fetcher. Empty/missing fields are
  preserved as-is from the source.

## Collections bundled (in `assets/data/hadith/`)

| File | Edition | metadata.name | Hadiths | Sections | Size | Translator/author (as stated in dataset) |
|---|---|---|---|---|---|---|
| bukhari_eng.json | eng-bukhari | Sahih al Bukhari | 7,589 | 98 | 4,821,289 bytes (4.60 MB) | Muhsin Khan |
| muslim_eng.json | eng-muslim | Sahih Muslim | 7,563 | 57 | 3,940,216 bytes (3.76 MB) | Abdul Hamid Siddiqui |

- Translator attribution copied verbatim from the dataset's `editions`
  index `author` field. The JSON files themselves carry no author/source/
  translator fields (metadata only contains `name`, `sections`,
  `section_details`); the editions index lists `author: "Muhsin Khan"`
  for eng-bukhari and `author: "Abdul Hamid Siddiqui"` for eng-muslim
  (source and comments fields are empty in the index).
- Schema per entry: `{"hadithnumber", "arabicnumber", "text", "grades": [],
  "reference": {"book", "hadith"}}`.

## Verification results

- **Bukhari — PASS.** Valid JSON; `metadata.name` = "Sahih al Bukhari";
  7,589 hadiths (task estimate ≈7,563 — exact count reported here);
  98 sections; first hadith (book 1, hadith 1) begins with
  "Narrated 'Umar bin Al-Khattab" (the intentions hadith). 9 entries have
  empty `text` (0.1%) — preserved as-is; app should skip or handle them.
- **Muslim — PASS with caveat.** Valid JSON; `metadata.name` =
  "Sahih Muslim"; 7,563 hadiths; 57 sections; 3.94 MB — well under the
  12 MB bundle limit, so it IS bundled. Caveat: 203 of 7,563 entries
  (2.7%) have empty `text`, including the first two entries
  (book 0, hadith 1–2). The first non-empty entry (book 0, hadith 3)
  reads as a Sahih Muslim Book of Faith narration; sanity-checked as
  plausibly Muslim-style content. Reference `book` starts at 0 in this
  edition. The app must filter out empty-text entries rather than
  displaying blanks.
- **Grades — not present in either edition.** Sampled 20 hadiths spread
  across all books of eng-bukhari (one per ~5th book): every `grades`
  array is `[]`. Total across all 7,589: 0 populated. Same for eng-muslim:
  0 of 7,563 populated. App should display "grade not listed in this
  edition" where absent. Grades were NOT invented.

## On-demand (not bundled) — size checks for future planning

Measured by full download to /tmp (then deleted); not saved to the app.

| Edition | Size | Verdict |
|---|---|---|
| ara-bukhari.min.json | 9,409,647 bytes (8.97 MB) | Bundleable later if wanted (under 12 MB) |
| urd-bukhari.min.json | 9,584,861 bytes (9.14 MB) | Bundleable later if wanted (under 12 MB) |

Note: jsDelivr HEAD requests did not return `Content-Length` for these
files, so size was measured by downloading once to /tmp and deleting —
no copy is retained in the app assets.

- ara-bukhari attribution in index: author "Unknown".
- urd-bukhari attribution in index: author "Unknown".

## Fallback note (from dataset README)

If a `.min.json` URL fails, the non-minified `.json` variant of the same
path can be used as a fallback, and vice versa.

---

# Dua/Adhkar/Wazaif data sources & verification log
Prepared 2026-10-08 for the Noor-e-Deen app (data curator subagent).

## Datasets used (all fetched, not reconstructed)

1. **Primary dataset — Hisnul Muslim transcription with 16 languages**
   Repo: https://github.com/HsnSaboor/quran-api-toon
   Files fetched (raw.githubusercontent.com, main branch):
   - `duas/duas/husn_ar.toon` (Arabic, 266 items)
   - `duas/duas/husn_en.toon` (English translation + transliteration + enriched references, 266 items)
   - `duas/duas/husn_ur.toon` (Urdu translation, 254 items — 12 ids lack Urdu, recorded as null)
   Notes: 132 categories, items carry `repeat` counts and `reference` fields enriched
   (per the repo's commit history) from sunnah.com/hisn with hadith numbers and
   Al-Albani grading citations. Arabic, transliteration, Urdu and English were copied
   verbatim into the output JSON; where a field was absent in the dataset, `null`
   was used (never invented).

2. **Cross-check source A — Arabic Hisnul Muslim transcription (MIT licensed)**
   Repo: https://github.com/asellam/HisnElMuslim
   File: `hisn.json` — Arabic text + Count + Arabic hadith reference per entry.
   Used as the independent second transcription for Arabic-integrity checks.

3. **Cross-check source B — independent dua REST API transcription**
   https://dua-api.hisnul.workers.dev/api/books/1/chapters/27/duas
   (thelighthub/dua-api; Bengali/Arabic transcription of Hisnul Muslim, fetched live.)

4. **Cross-check source C — Quran text (Uthmani)**
   https://api.alquran.cloud/v1/ayah/{2:201,2:255}/quran-uthmani
   Used to verify the two Quranic-verse items word-for-word.

## Verification performed (9 cross-checks, all passed)

| # | Item (dataset id) | Check | Result |
|---|---|---|---|
| 1 | 76 — Al-Ikhlas/Al-Falaq/An-Nas | Arabic vs independent dua-api ch.27 transcription | match |
| 2 | 75 — Ayat al-Kursi | Arabic vs alquran.cloud Quran 2:255 (Uthmani) | match |
| 3 | 235 — Rabbana atina | Arabic vs alquran.cloud Quran 2:201 (Uthmani) | match |
| 4 | 77 — Asbahna wa-asbahal-mulku | Arabic present in asellam transcription (ref: Muslim 4/2088) | match |
| 5 | 78 — Allahumma bika asbahna | Arabic in asellam (ref: Tirmidhi 5/466 / Sahih Tirmidhi 3/142) | match |
| 6 | 79 — Sayyid al-Istighfar | Arabic in asellam morning chapter | match |
| 7 | 82 — Allahumma 'afini fi badani (contains 'adhab al-qabr) | Arabic in asellam (ref: Abu Dawud 4/324, Ahmad 5/42) | match |
| 8 | 95 — as'aluka 'ilman nafi'an | Arabic in asellam | match |
| 9 | 96/97/98 — Istighfar / A'udhu bi kalimatillah / Durood | Arabic in asellam morning/evening chapters | match |

Note: comparisons were done on tashkeel-normalised Arabic (diacritics, alef variants
and Uthmani-specific codepoints normalised), because the sources use different
rasm conventions. No item's Arabic was altered in the output files.

## Exclusions

- **parents category: EXCLUDED (1 category).** The task requested a "parents" dua
  category, but no parents-specific dua exists in the fetched Hisnul Muslim dataset
  (searched raw and diacritic-normalised Arabic for والدي / لوالدي / ارحمهما —
  only hit was item 160, a funeral dua for a child). Per the no-invention rule it
  was dropped rather than composed.
- **0 items excluded for missing sources.** Every selected item carries a Hisnul
  Muslim chapter number plus its hadith/Quran reference from the dataset.
- **Virtue claims:** stated ONLY where the dataset's reference field quotes the
  virtue together with its hadith citation (w_02, w_03, w_04, w_07, w_08). All other
  wazaif have `"note": null`. No virtue was invented.
- **Urdu:** 12 of the 266 dataset ids have no Urdu translation in the source file;
  selected items affected are recorded as `"urdu": null`.

## Final counts

| File | Contents |
|---|---|
| `duas.json` | 30 duas (morning 1, evening 1, sleep 3, waking 2, eating 3, travel 2, anxiety 3, forgiveness 2, protection 3, rizq 1, knowledge 1, salah 3, general 6) |
| `adhkar.json` | morning 15, evening 12, after_salah 8 |
| `wazaif.json` | 8 (quran: 3, hadith: 5, general: 0 — none needed) |

All JSON files parse cleanly; every item has non-empty `arabic` and `source`.
Output location: `/home/hatch/workspace/noor-e-deen/assets/data/`
