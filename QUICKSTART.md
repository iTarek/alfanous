# Quick Start: Deploy to Railway in 5 Steps

## Option A: If you have Python 2.7 installed

```bash
# 1. Build indexes
cd /Users/itarek/Projects/alfanous
make build

# 2. Commit everything
git add .
git commit -m "Add Railway deployment"
git push origin master

# 3. Go to railway.app and login with GitHub
# 4. Click "New Project" → "Deploy from GitHub repo" → Select "alfanous"
# 5. Wait 3-5 minutes, then click "Generate Domain" to get your URL
```

## Option B: If you DON'T have Python 2.7

```bash
# 1. Commit the deployment files (without indexes)
cd /Users/itarek/Projects/alfanous
git add .
git commit -m "Add Railway deployment with Docker"
git push origin master

# 2. Update railway.json to use Docker
# (Edit railway.json and change "NIXPACKS" to "DOCKERFILE")

# 3. Commit again
git add railway.json
git commit -m "Use Docker for deployment"
git push origin master

# 4. Go to railway.app and login with GitHub
# 5. Click "New Project" → "Deploy from GitHub repo" → Select "alfanous"
# 6. Railway will build everything including indexes
# 7. Wait 5-10 minutes, then click "Generate Domain" to get your URL
```

## Test Your Deployment

Once deployed, visit:
- `https://your-url.railway.app/health` ← Should say "healthy"
- `https://your-url.railway.app/api/search?query=الله` ← Should return results

## Recommended: Use Docker (Option B)

Docker is simpler because:
- ✅ No need to install Python 2.7
- ✅ Railway builds everything automatically
- ✅ Indexes are built during deployment
- ✅ No large files to commit to Git

Just make sure `railway.json` has:
```json
{
  "build": {
    "builder": "DOCKERFILE"
  }
}
```

