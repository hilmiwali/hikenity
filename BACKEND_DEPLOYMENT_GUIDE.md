# 🚀 Backend Server & Deployment Guide

## Understanding the Backend Requirement

### **When Do You Need the Backend Server?**

The Node.js backend server (`backend/server.js`) is **ONLY** needed for:
- ✅ **Paid trip bookings** (Stripe payment processing)
- ✅ **Payment receipt generation**

The backend is **NOT** needed for:
- ❌ Browsing trips
- ❌ User authentication (handled by Firebase)
- ❌ Booking free trips
- ❌ Profile management
- ❌ Location tracking
- ❌ Most app features

---

## 📱 Scenarios & Solutions

### **Scenario 1: Local Testing (Development)**

**Question:** "Do I need to run `npm start` every time?"

**Answer:** YES, but only if you want to test paid bookings.

```bash
# Terminal 1 - Backend Server
cd backend
npm start

# Terminal 2 - Flutter App
flutter run
```

**Tip:** Use `npm run dev` for auto-restart during development:
```bash
cd backend
npm run dev  # Uses nodemon for auto-restart on code changes
```

---

### **Scenario 2: Send APK to Friend (Without Backend)**

**Question:** "What if I want to send the APK to my friend to test?"

**Answer:** You have 3 options:

#### **Option A: Deploy Backend to Cloud (Recommended)**
Deploy the backend server to a cloud service, then your friend doesn't need to run anything locally.

**Best Cloud Options:**
1. **Heroku** (Free tier available)
2. **Railway** (Free tier, easy setup)
3. **Render** (Free tier)
4. **AWS/Google Cloud** (More complex, but scalable)
5. **Vercel/Netlify** (Serverless functions)

Once deployed, update `.env`:
```env
BACKEND_URL=https://your-backend-url.herokuapp.com
```

Then rebuild the APK and share it.

#### **Option B: Friend Tests Without Payments**
If your friend is just testing the app features (not payments), they don't need the backend at all!

Just send the APK and they can:
- ✅ Browse trips
- ✅ Login with Google/Email
- ✅ Bookmark trips
- ✅ View profiles
- ✅ Book FREE trips
- ❌ Cannot book PAID trips (will fail without backend)

#### **Option C: Friend Runs Backend Locally**
Your friend can run the backend on their computer:

1. Share the backend folder (or Git repo)
2. Friend installs Node.js
3. Friend runs:
```bash
cd backend
npm install
npm start
```
4. Friend uses APK with `BACKEND_URL=http://localhost:4242`

**Not recommended** - too complex for testing.

---

## ☁️ Deploying Backend to Cloud (Step-by-Step)

### **Option 1: Heroku (Recommended for Beginners)**

#### Step 1: Install Heroku CLI
```bash
# Download from: https://devcenter.heroku.com/articles/heroku-cli
# Or use npm:
npm install -g heroku
```

#### Step 2: Login to Heroku
```bash
heroku login
```

#### Step 3: Create Heroku App
```bash
cd backend
heroku create hikenity-backend
```

#### Step 4: Set Environment Variables
```bash
heroku config:set STRIPE_SECRET_KEY=sk_test_51Q8t4GHoyDahNOUZ...
heroku config:set PORT=4242
```

#### Step 5: Deploy
```bash
# Add Procfile (tells Heroku how to start the app)
echo "web: node server.js" > Procfile

# Deploy
git init
git add .
git commit -m "Deploy backend"
git push heroku main
```

#### Step 6: Get Your Backend URL
```bash
heroku open
# Your URL will be: https://hikenity-backend-xxxxx.herokuapp.com
```

#### Step 7: Update Flutter App
Update `.env`:
```env
BACKEND_URL=https://hikenity-backend-xxxxx.herokuapp.com
```

Rebuild APK:
```bash
flutter build apk --release
```

**Done!** Now your APK works anywhere without running a local backend.

---

### **Option 2: Railway (Easiest Setup)**

#### Step 1: Go to Railway.app
Visit: https://railway.app/ and sign up with GitHub

#### Step 2: Create New Project
1. Click "New Project"
2. Select "Deploy from GitHub repo"
3. Connect your GitHub repo (or create new one for backend)

#### Step 3: Add Environment Variables
In Railway dashboard:
- Add `STRIPE_SECRET_KEY`
- Add `PORT` (Railway auto-assigns, but you can set 4242)

#### Step 4: Deploy
Railway automatically deploys when you push to GitHub!

#### Step 5: Get Your URL
Railway provides a URL like: `https://hikenity-backend-production.up.railway.app`

Update `.env` and rebuild APK.

---

### **Option 3: Render**

#### Step 1: Sign up at Render.com
Visit: https://render.com/

#### Step 2: Create Web Service
1. Click "New +"
2. Select "Web Service"
3. Connect GitHub repo (backend folder)

#### Step 3: Configure
- **Build Command:** `npm install`
- **Start Command:** `npm start`
- **Environment:** Node

#### Step 4: Add Environment Variables
In Render dashboard, add:
- `STRIPE_SECRET_KEY`
- `PORT=4242`

#### Step 5: Deploy
Render auto-deploys from GitHub.

---

## 🏗️ Backend Deployment Checklist

### **Before Deployment:**
- [ ] Backend code is in Git repository
- [ ] `package.json` includes all dependencies
- [ ] `.env.example` is documented
- [ ] `.gitignore` protects `.env`

### **During Deployment:**
- [ ] Set environment variables on hosting platform
- [ ] Verify `PORT` is configured correctly
- [ ] Test endpoints (use Postman or curl)

### **After Deployment:**
- [ ] Test `/create-payment-intent` endpoint
- [ ] Test `/retrieve-receipt` endpoint
- [ ] Update Flutter `.env` with production URL
- [ ] Rebuild APK: `flutter build apk --release`
- [ ] Test payment flow end-to-end

---

## 📦 Building & Sharing APK

### **Build Release APK:**
```bash
# Build release APK (with current .env configuration)
flutter build apk --release

# APK location:
# build/app/outputs/flutter-apk/app-release.apk
```

### **Build for Different Environments:**

#### Development APK (local backend):
```env
# .env
BACKEND_URL=http://localhost:4242
ENVIRONMENT=development
```
```bash
flutter build apk --release
```

#### Production APK (cloud backend):
```env
# .env
BACKEND_URL=https://your-backend-url.herokuapp.com
ENVIRONMENT=production
```
```bash
flutter build apk --release
```

### **Share APK:**
```bash
# Copy APK to easy location
copy build\app\outputs\flutter-apk\app-release.apk C:\hikenity-v1.0.apk

# Share via:
# - Google Drive
# - Dropbox
# - WeTransfer
# - Email (if < 25MB)
# - GitHub Releases
```

---

## 🔄 Development Workflow Options

### **Option 1: Always Run Backend Locally**
```bash
# Terminal 1
cd backend
npm run dev

# Terminal 2
flutter run
```

**Pros:** Full control, instant testing  
**Cons:** Need to remember to start backend

---

### **Option 2: Use Cloud Backend for Development**
Deploy once to cloud, always use that URL.

```env
# .env (always use cloud)
BACKEND_URL=https://hikenity-dev.herokuapp.com
```

**Pros:** No need to run backend locally  
**Cons:** Slower iteration, uses cloud resources

---

### **Option 3: Hybrid Approach (Recommended)**
- **Development:** Local backend (`http://localhost:4242`)
- **Testing/Sharing:** Cloud backend (`https://...`)

Switch between them by changing `.env`:

```bash
# Quick switch script (create switch-backend.sh)
# For local:
echo "BACKEND_URL=http://localhost:4242" > .env

# For cloud:
echo "BACKEND_URL=https://hikenity-backend.herokuapp.com" > .env
```

---

## 💡 Best Practices

### **For Development:**
1. Use local backend for fast iteration
2. Use `npm run dev` with nodemon
3. Test payments with Stripe test cards

### **For Testing (Friends/Team):**
1. Deploy backend to free cloud service
2. Update `.env` with cloud URL
3. Build release APK
4. Share APK (backend always available)

### **For Production:**
1. Deploy to reliable hosting (AWS, Google Cloud)
2. Use production Stripe keys (`pk_live_`, `sk_live_`)
3. Set up monitoring and logging
4. Configure auto-scaling if needed

---

## 🧪 Testing Without Backend

Your friend can test most features without the backend:

### **Works Without Backend:**
✅ Login (Google/Email/Password)  
✅ Browse trips  
✅ Search and filter trips  
✅ View trip details  
✅ Bookmark trips  
✅ View profile  
✅ Book FREE trips  
✅ View location tracking  
✅ Rate trips  

### **Requires Backend:**
❌ Book PAID trips (Stripe payment)  
❌ Generate payment receipts  

**Solution:** Have at least 1 free trip for testing without backend!

---

## 🚦 Quick Decision Guide

### **You should deploy backend to cloud if:**
- You want to share APK with others
- You don't want to run `npm start` every time
- Your app has paid trips
- You're preparing for production

### **You can skip backend deployment if:**
- Only testing for yourself
- Only testing free trips
- Early development stage
- Just testing UI/UX

---

## 📝 Summary

| Scenario | Backend Needed? | Solution |
|----------|----------------|----------|
| Local development (paid trips) | ✅ Yes | Run `npm start` |
| Local development (free trips) | ❌ No | Just run Flutter app |
| Share APK with friends | ⚠️ Optional | Deploy to cloud (recommended) |
| Production release | ✅ Yes | Deploy to cloud (required) |
| Testing UI/UX only | ❌ No | No backend needed |

---

## 🎯 Recommended Approach

**For Your Current Stage:**

1. **Now (Development):**
   - Run backend locally when testing payments
   - Use free trips for testing without backend

2. **Soon (Testing with Friends):**
   - Deploy backend to Railway/Heroku (free tier)
   - Update `.env` with cloud URL
   - Build and share APK

3. **Later (Production):**
   - Move to paid hosting (better reliability)
   - Use production Stripe keys
   - Set up monitoring and backups

---

## 🔗 Next Steps

Ready to deploy? Check out:
- **Railway:** https://railway.app/ (Easiest)
- **Heroku:** https://www.heroku.com/ (Most popular)
- **Render:** https://render.com/ (Good free tier)

Need help with deployment? Let me know! 🚀
