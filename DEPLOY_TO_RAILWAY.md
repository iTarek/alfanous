# Deploy Alfanous to Railway - Complete Step-by-Step Guide

## Prerequisites
- Git installed on your computer
- GitHub account
- Railway account (free - sign up at railway.app)

## Method 1: Using Make (Recommended if you have Python 2.7)

### Step 1: Build Indexes Locally

Open Terminal and run:

```bash
cd /Users/itarek/Projects/alfanous
make build
```

**Wait for it to complete** (may take 5-10 minutes). You'll see various build steps.

### Step 2: Verify Indexes Were Created

```bash
ls src/alfanous/indexes/main/
```

You should see several files. If you see files, proceed to Step 3.

### Step 3: Commit Everything to Git

```bash
# Add all new files
git add .

# Commit
git commit -m "Add Railway deployment configuration and indexes"

# Push to GitHub
git push origin master
```

**If you get an error about file size**, the indexes might be too large. Skip to Method 2 below.

### Step 4: Deploy on Railway

1. Go to https://railway.app
2. Click **"Login"** → Sign in with GitHub
3. Click **"New Project"**
4. Click **"Deploy from GitHub repo"**
5. Find and select **"alfanous"** from your repositories
6. Railway will automatically start deploying
7. Wait 3-5 minutes for deployment to complete

### Step 5: Get Your URL

1. In Railway dashboard, click on your project
2. Click on the **"Settings"** tab
3. Click **"Generate Domain"** under "Domains"
4. Your API will be available at: `https://your-project.up.railway.app`

### Step 6: Test Your API

Visit these URLs in your browser:
- `https://your-project.up.railway.app/` → Should show "status: running"
- `https://your-project.up.railway.app/health` → Should show "status: healthy"
- `https://your-project.up.railway.app/api/search?query=الله` → Should return search results

---

## Method 2: Using Build Script (If Make Doesn't Work)

### Step 1: Install Python 2.7

If you don't have Python 2.7:
- **macOS**: `brew install python@2`
- **Linux**: `sudo apt-get install python2.7`

### Step 2: Run the Build Script

```bash
cd /Users/itarek/Projects/alfanous
./build_indexes.sh
```

If you get "permission denied":
```bash
chmod +x build_indexes.sh
./build_indexes.sh
```

### Step 3: Follow Steps 2-6 from Method 1

After the build completes, follow Steps 2-6 from Method 1 above.

---

## Method 3: Using Docker (If Indexes Are Too Large for Git)

If your indexes are too large to commit to Git, use Docker:

### Step 1: Create a Dockerfile

The file `Dockerfile` is already created below. Just commit it.

### Step 2: Update railway.json

```bash
# Edit railway.json to use Docker
```

The railway.json is already configured for Docker support.

### Step 3: Commit and Deploy

```bash
git add .
git commit -m "Add Docker deployment for Railway"
git push origin master
```

Then follow Step 4-6 from Method 1.

---

## Troubleshooting

### Problem: "make: command not found"
**Solution**: Use Method 2 (build script) instead.

### Problem: Git refuses to push large files
**Solution**: The indexes might be too large. Use Method 3 (Docker) or use Git LFS:
```bash
git lfs install
git lfs track "src/alfanous/indexes/**"
git add .gitattributes
git commit -m "Track indexes with Git LFS"
git push origin master
```

### Problem: Railway deployment fails with "Module not found"
**Solution**: Make sure you committed the `src/` directory and all Python files.

### Problem: API returns "Alfanous not initialized"
**Solution**: Indexes weren't built or weren't included in deployment. Rebuild and recommit.

### Problem: Python 2.7 not available
**Solution**: Use Docker deployment (Method 3).

---

## What Each File Does

- `app.py` - Flask web server that wraps Alfanous library
- `requirements.txt` - Python dependencies Railway will install
- `Procfile` - Tells Railway how to start your app
- `runtime.txt` - Specifies Python version
- `railway.json` - Railway configuration
- `build_indexes.sh` - Script to build indexes manually

---

## Need Help?

If you get stuck:
1. Check Railway logs: Go to your project → Click "Deployments" → Click latest deployment → View logs
2. Check that all files were committed: `git status`
3. Make sure indexes exist: `ls src/alfanous/indexes/main/`

