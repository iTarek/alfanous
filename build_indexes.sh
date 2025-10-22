#!/bin/bash
# Script to build Alfanous indexes

set -e  # Exit on error

echo "======================================"
echo "Building Alfanous indexes..."
echo "======================================"

# Set paths
API_PATH="./src/"
QIMPORT="${API_PATH}alfanous-import/cli.py"
DB_PATH="./resources/databases/"
INDEX_PATH="${API_PATH}alfanous/indexes/"
CONFIGS_PATH="${API_PATH}alfanous/configs/"
STORE_PATH="./store/"
DYNAMIC_RESOURCES_PATH="${API_PATH}alfanous/dynamic_resources/"

# Check for Python 2
if command -v python2 &> /dev/null; then
    PYTHON_COMMAND="python2"
elif command -v python &> /dev/null && python --version 2>&1 | grep -q "Python 2"; then
    PYTHON_COMMAND="python"
else
    echo "❌ Error: Python 2 is required to build indexes"
    echo "Please install Python 2.7 and try again"
    exit 1
fi

echo "✅ Using Python: $PYTHON_COMMAND"
$PYTHON_COMMAND --version

# Step 1: Construct database
echo ""
echo "📦 Step 1: Constructing database from SQL..."
cd ${DB_PATH}
rm -f main.db
if [ ! -f main.sql ]; then
    echo "❌ Error: main.sql not found!"
    exit 1
fi
cat main.sql | sqlite3 main.db
echo "✅ Database created: $(ls -lh main.db)"
cd ../..

# Step 2: Update information.json
echo ""
echo "📝 Step 2: Updating information.json..."
perl -p -w -e 's|alfanous.release|0.7.33Kahraman|g;s|alfanous.version|0.7.33|g;' \
    ${API_PATH}alfanous/resources/information.json.in > ${API_PATH}alfanous/resources/information.json
echo "✅ Information file updated"

# Step 3: Create dynamic resources directory
echo ""
echo "📁 Step 3: Creating dynamic resources directory..."
mkdir -p ${DYNAMIC_RESOURCES_PATH}
touch ${DYNAMIC_RESOURCES_PATH}__init__.py
echo "✅ Directory created: ${DYNAMIC_RESOURCES_PATH}"

# Step 4: Transfer dynamic resources (prebuild)
echo ""
echo "🔄 Step 4: Transferring dynamic resources from database..."
export PYTHONPATH=${API_PATH}

echo "  - Transferring stopwords..."
${PYTHON_COMMAND} ${QIMPORT} -t stopwords ${DB_PATH}main.db ${DYNAMIC_RESOURCES_PATH}
echo "  - Transferring synonyms..."
${PYTHON_COMMAND} ${QIMPORT} -t synonyms ${DB_PATH}main.db ${DYNAMIC_RESOURCES_PATH}
echo "  - Transferring word properties..."
${PYTHON_COMMAND} ${QIMPORT} -t word_props ${DB_PATH}main.db ${DYNAMIC_RESOURCES_PATH}
echo "  - Transferring derivations..."
${PYTHON_COMMAND} ${QIMPORT} -t derivations ${DB_PATH}main.db ${DYNAMIC_RESOURCES_PATH}
echo "  - Transferring Arabic to English names..."
${PYTHON_COMMAND} ${QIMPORT} -t ara2eng_names ${DB_PATH}main.db ${DYNAMIC_RESOURCES_PATH}
echo "  - Transferring standard to Uthmani mappings..."
${PYTHON_COMMAND} ${QIMPORT} -t std2uth_words ${DB_PATH}main.db ${DYNAMIC_RESOURCES_PATH}
echo "✅ Dynamic resources transferred"

# Step 5: Build indexes
echo ""
echo "🔨 Step 5: Building main index (this may take a few minutes)..."
rm -rf ${INDEX_PATH}main/
mkdir -p ${INDEX_PATH}main/
${PYTHON_COMMAND} ${QIMPORT} -x main ${DB_PATH}main.db ${INDEX_PATH}main/
chmod 644 ${INDEX_PATH}main/*_LOCK 2>/dev/null || true
echo "✅ Main index built: $(du -sh ${INDEX_PATH}main/ | cut -f1)"

echo ""
echo "🔨 Step 6: Building extend index (translations)..."
rm -rf ${INDEX_PATH}extend/
mkdir -p ${INDEX_PATH}extend/
${PYTHON_COMMAND} ${QIMPORT} -x extend ${STORE_PATH}Translations/ ${INDEX_PATH}extend/
chmod 644 ${INDEX_PATH}extend/*_LOCK 2>/dev/null || true
echo "✅ Extend index built: $(du -sh ${INDEX_PATH}extend/ | cut -f1)"

# Step 7: Update translations list
echo ""
echo "📋 Step 7: Updating translations list..."
echo "{}" > ${CONFIGS_PATH}translations.json
${PYTHON_COMMAND} ${QIMPORT} -u translations ${INDEX_PATH}extend/ ${CONFIGS_PATH}translations.json
echo "✅ Translations list updated"

# Step 8: Build spellers
echo ""
echo "📖 Step 8: Building spell checkers..."
echo "  - Building aya speller..."
${PYTHON_COMMAND} ${QIMPORT} -p aya ${INDEX_PATH}main/
chmod 644 ${INDEX_PATH}main/*_LOCK 2>/dev/null || true

echo "  - Building subject speller..."
${PYTHON_COMMAND} ${QIMPORT} -p subject ${INDEX_PATH}main/
chmod 644 ${INDEX_PATH}main/*_LOCK 2>/dev/null || true
echo "✅ Spellers built"

# Step 9: Transfer vocalizations (postbuild)
echo ""
echo "🎵 Step 9: Transferring vocalizations..."
${PYTHON_COMMAND} ${QIMPORT} -t vocalizations ${DB_PATH}main.db ${INDEX_PATH}main/ ${DYNAMIC_RESOURCES_PATH}
echo "✅ Vocalizations transferred"

echo ""
echo "======================================"
echo "✅ BUILD COMPLETE!"
echo "======================================"
echo "Indexes location: ${INDEX_PATH}"
echo "Main index size: $(du -sh ${INDEX_PATH}main/ | cut -f1)"
echo "Extend index size: $(du -sh ${INDEX_PATH}extend/ | cut -f1)"
echo ""
ls -lh ${INDEX_PATH}main/ | head -5
echo "..."

