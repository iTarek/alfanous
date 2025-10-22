# Alfanous Architecture Overview

## System Overview

Alfanous is a Quranic search engine with advanced Arabic text processing capabilities. It uses **Whoosh** (embedded in the codebase) for full-text indexing and custom query parsers for Arabic-specific features.

---

## Architecture Layers

### 1. **Web API Layer** (`app.py`)
- Flask-based REST API
- Endpoints:
  - `/api/search` - Search Quranic verses
  - `/api/suggest` - Get spelling suggestions
  - `/api/info` - Get metadata
  - `/health` - Health check
- Converts HTTP params to internal format
- **Current fix**: Converts string params to proper types (int for page/range/offset)

### 2. **Output Formatting Layer** (`outputs.py`)
- `Raw` class: Main interface for all operations
- Methods:
  - `do(flags)` - Main entry point
  - `_search_aya(flags)` - Search in verses
  - `_search_translation(flags)` - Search in translations
  - `_search_word(flags)` - Word-level search
  - `_suggest_aya(flags)` - Get suggestions
  - `_show(flags)` - Get metadata
- Handles result formatting, highlighting, pagination
- Manages adjacent verses, translations, recitations

### 3. **Search Engine Layer** (`engines.py`)
Four specialized search engines:

#### **QuranicSearchEngine** (Main Index)
- Field: `aya` (verse text)
- Uses: `QuranicParser`
- Spell checkers: Aya + Subject
- Default index: `src/alfanous/indexes/main/`

#### **FuzzyQuranicSearchEngine**
- Same as Quranic but with fuzzy matching
- Uses: `FuzzyQuranicParser`
- Searches multiple fields automatically

#### **TraductionSearchEngine** (Extend Index)
- Field: `text` (translation text)
- Uses: `StandardParser`
- Default index: `src/alfanous/indexes/extend/`

#### **WordSearchEngine** (Word Index)
- Field: `normalized` (word)
- Uses: `StandardParser`
- Provides morphological analysis
- Default index: `src/alfanous/indexes/word/`

### 4. **Query Processing Layer** (`query_processing.py`)

#### **QuranicParser** - Advanced Arabic Query Syntax

**Special Operators:**
- `~word` - Synonyms (مرادفات)
- `#word` - Antonyms (أضداد)
- `>word` - Lemma derivations (الجذر)
- `>>word` - Root derivations (الأصل)
- `'word'` - Tashkil/vocalization matching
- `%word` - Spell error tolerance
- `{root,type}` - Tuple search (root + word type)
- `*` or `؟` - Wildcards
- `[start TO end]` - Range queries

**Field Mapping:**
- Supports Arabic field names → English
- Examples: `رقم:1` → `gid:1`, `سورة:الفاتحة` → `sura:Al-Fatihah`

**Boolean Operators:**
- `و` or `AND` or `+` - AND
- `أو` or `OR` or `|` - OR  
- `وليس` or `ANDNOT` or `-` - AND NOT
- `ليس` or `NOT` - NOT

**Buckwalter Transliteration:**
- Automatic conversion: `Allh` → `الله`
- Query: `qwl` finds `قال`, `قول`, etc.

### 5. **Searching Layer** (`searching.py`)
- `QSearcher`: Executes searches via Whoosh
- `QReader`: Reads index, provides term statistics
- Custom scoring: `QScore()`
- Custom sorting: `QSort(sortedby)`

### 6. **Indexing Layer** (`indexing.py`, `data.py`)
- Three Whoosh indexes built from SQLite database
- Index structure:
  - **Main**: Quranic text (6,236 verses)
  - **Extend**: Translations
  - **Word**: Morphological analysis (Quranic Corpus)

### 7. **Data Layer**
Built during `make build`:
1. **Database** (`resources/databases/main.sql`):
   - Source: Quranic data, morphology, translations
   - Size: ~8.5 MB

2. **Dynamic Resources** (Python modules):
   - Synonyms dictionary
   - Derivations (root/lemma mappings)
   - Field name mappings (Arabic ↔ English)
   - Standard ↔ Uthmani text mappings
   - Vocalizations
   - Stop words

3. **Indexes** (Whoosh):
   - Built by `src/alfanous-import/cli.py`
   - Includes spell checkers

---

## Data Flow

```
User Request
    ↓
Flask API (app.py)
    ↓
Raw.do(params) [outputs.py]
    ↓
Search Engine [engines.py]
    ↓
Query Parser [query_processing.py]
    ↓
Searcher [searching.py]
    ↓
Whoosh Index [indexes/]
    ↓
Results Processing [results_processing.py]
    ↓
JSON Response
```

---

## Key Features

### Quranic Search Features
1. **Advanced Query Syntax**
   - Arabic and English fields
   - Complex boolean queries
   - Range queries (e.g., `رقم_السورة:[1 الى 5]`)

2. **Arabic Language Support**
   - Synonym expansion
   - Root/lemma derivation
   - Vocalization matching
   - Spell error tolerance
   - Buckwalter transliteration

3. **Result Enrichment**
   - Previous/next verses
   - Sura information & statistics
   - Word analysis & derivations
   - Thematic classification
   - Sajda (prostration) info
   - Morphological annotations

4. **Multiple Views**
   - Minimal, Normal, Full, Statistic, Linguistic, Recitation
   - Customizable via flags

5. **Highlighting**
   - CSS, HTML, Genshi, Bold, BBCode

6. **Scripts**
   - Standard (simplified)
   - Uthmani (Medina Mushaf)

7. **Recitations**
   - 30+ reciters
   - MP3 audio links

---

## Technology Stack

- **Python 2.7** (core library)
- **Flask 1.1.4** (web API)
- **Whoosh** (full-text search engine, embedded)
- **pyparsing** (query grammar)
- **SQLite** (data storage)
- **Gunicorn** (WSGI server)
- **Docker** (deployment)

---

## Index Schema (Main)

Key fields:
- `gid` - Global ayah ID (1-6236)
- `aya_id` - Ayah number in sura
- `sura_id` - Sura number (1-114)
- `aya` - Unvocalized standard text (searchable)
- `aya_` - Vocalized standard text
- `uth` - Unvocalized Uthmani text
- `uth_` - Vocalized Uthmani text
- `sura`, `sura_arabic`, `sura_english` - Sura names
- `juz`, `hizb`, `rub`, `page` - Structural divisions
- `subject`, `chapter`, `topic`, `subtopic` - Themes
- `sajda`, `sajda_id`, `sajda_type` - Prostration info
- Statistics: `a_w`, `a_l`, `a_g` (words, letters, godnames per aya)
- Sura stats: `s_w`, `s_l`, `s_g`, `s_a` (per sura)

---

## Deployment Notes

### Railway Issues Encountered & Fixed:
1. ✅ **PORT variable expansion** - Fixed with `start.sh` script
2. ✅ **Type conversion** - Fixed string→int for page/range/offset params
3. ✅ **Debian Buster archives** - Fixed repository URLs in Dockerfile
4. ✅ **Build process** - Automated with `build_indexes.sh`

### Current Status:
- ✅ Health check: Working
- ✅ Info endpoints: Working
- ✅ Suggest: Working
- 🔄 Search: Fixed, needs redeployment

---

## API Endpoints Summary

| Endpoint | Method | Parameters | Description |
|----------|--------|------------|-------------|
| `/` | GET | - | API info |
| `/health` | GET | - | Health check |
| `/api/search` | GET | query, unit, page, range, etc. | Search verses/translations |
| `/api/suggest` | GET | query, unit | Spelling suggestions |
| `/api/info` | GET | query | Metadata (fields, translations, etc.) |

---

## Example Queries

```bash
# Simple Arabic search
/api/search?query=الله

# Field search
/api/search?query=gid:1

# Range search
/api/search?query=سورة:الفاتحة

# Complex query
/api/search?query=الصلاة+الزكاة

# Derivation search (root)
/api/search?query=>>مالك

# Translation search
/api/search?unit=translation&query=prayer

# With pagination
/api/search?query=الله&page=2&perpage=5
```

---

## Performance Considerations

1. **Index Loading**: Indexes are loaded once at startup
2. **Caching**: Searchers are closed after each query
3. **Pagination**: Results are sliced in memory (could be optimized)
4. **Dynamic Resources**: Loaded as Python modules (fast)
5. **Build Time**: ~30-50 seconds (one-time during deployment)

---

## Future Optimization Opportunities

1. **Pagination**: Move to index-level for better performance
2. **Caching**: Cache frequent queries
3. **Python 3**: Migrate from Python 2.7
4. **API Versioning**: Add /v1/ prefix
5. **Rate Limiting**: Add for production
6. **Async**: Use async/await for better concurrency

