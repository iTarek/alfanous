#!/bin/bash
# Script to build Alfanous indexes

set -e

echo "Building Alfanous indexes..."

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
    echo "Error: Python 2 is required to build indexes"
    echo "Please install Python 2.7 and try again"
    exit 1
fi

echo "Using Python command: $PYTHON_COMMAND"

# Step 1: Construct database
echo "Step 1: Constructing database..."
cd ${DB_PATH}
rm -f main.db
cat main.sql | sqlite3 main.db
cd ../..

# Step 2: Update information.json
echo "Step 2: Updating information.json..."
perl -p -w -e 's|alfanous.release|0.7.33Kahraman|g;s|alfanous.version|0.7.33|g;' \
    ${API_PATH}alfanous/resources/information.json.in > ${API_PATH}alfanous/resources/information.json

# Step 3: Create dynamic resources directory
echo "Step 3: Creating dynamic resources directory..."
mkdir -p ${DYNAMIC_RESOURCES_PATH}
touch ${DYNAMIC_RESOURCES_PATH}__init__.py

# Step 4: Transfer dynamic resources (prebuild)
echo "Step 4: Transferring dynamic resources..."
export PYTHONPATH=${API_PATH}

${PYTHON_COMMAND} ${QIMPORT} -t stopwords ${DB_PATH}main.db ${DYNAMIC_RESOURCES_PATH}
${PYTHON_COMMAND} ${QIMPORT} -t synonyms ${DB_PATH}main.db ${DYNAMIC_RESOURCES_PATH}
${PYTHON_COMMAND} ${QIMPORT} -t word_props ${DB_PATH}main.db ${DYNAMIC_RESOURCES_PATH}
${PYTHON_COMMAND} ${QIMPORT} -t derivations ${DB_PATH}main.db ${DYNAMIC_RESOURCES_PATH}
${PYTHON_COMMAND} ${QIMPORT} -t ara2eng_names ${DB_PATH}main.db ${DYNAMIC_RESOURCES_PATH}
${PYTHON_COMMAND} ${QIMPORT} -t std2uth_words ${DB_PATH}main.db ${DYNAMIC_RESOURCES_PATH}

# Step 5: Build indexes
echo "Step 5: Building main index..."
rm -rf ${INDEX_PATH}main/
${PYTHON_COMMAND} ${QIMPORT} -x main ${DB_PATH}main.db ${INDEX_PATH}main/
chmod 644 ${INDEX_PATH}main/*_LOCK

echo "Step 6: Building extend index..."
rm -rf ${INDEX_PATH}extend/
${PYTHON_COMMAND} ${QIMPORT} -x extend ${STORE_PATH}translations/ ${INDEX_PATH}extend/
chmod 644 ${INDEX_PATH}extend/*_LOCK

# Step 7: Update translations list
echo "Step 7: Updating translations list..."
echo "{}" > ${CONFIGS_PATH}translations.json
${PYTHON_COMMAND} ${QIMPORT} -u translations ${INDEX_PATH}extend/ ${CONFIGS_PATH}translations.json

# Step 8: Build spellers
echo "Step 8: Building spellers..."
${PYTHON_COMMAND} ${QIMPORT} -p aya ${INDEX_PATH}main/
chmod 644 ${INDEX_PATH}main/*_LOCK

${PYTHON_COMMAND} ${QIMPORT} -p subject ${INDEX_PATH}main/
chmod 644 ${INDEX_PATH}main/*_LOCK

# Step 9: Transfer vocalizations (postbuild)
echo "Step 9: Transferring vocalizations..."
${PYTHON_COMMAND} ${QIMPORT} -t vocalizations ${DB_PATH}main.db ${INDEX_PATH}main/ ${DYNAMIC_RESOURCES_PATH}

echo "Build complete! Indexes created in ${INDEX_PATH}"

