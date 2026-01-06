# 🎯 Quick Reference: Backend & APK Sharing

## ❓ Common Questions Answered

### **Q: Do I need to run `npm start` every time I test the app?**

**A:** Only if testing PAID trip bookings locally.

- **Testing locally WITH payments:** YES - Run `npm start` in backend folder
- **Testing locally WITHOUT payments:** NO - Just run `flutter run`
- **Sharing APK with friends:** NO - Deploy backend to cloud first

---

### **Q: How do I share APK with my friend?**

**A:** Two options:

#### **Option 1: Cloud Backend (Recommended)**
1. Deploy backend to cloud (Railway, Heroku, etc.)
2. Update `.env` with cloud URL
3. Build APK: `flutter build apk --release`
4. Share APK file (found in `build/app/outputs/flutter-apk/app-release.apk`)

#### **Option 2: No Backend (Free Trips Only)**
1. Build APK: `flutter build apk --release`
2. Share APK file
3. Friend can test all features EXCEPT paid bookings

---

## 🚀 Quick Commands

### **Local Development (with payments):**
```bash
# Terminal 1 - Backend
cd backend
npm install      # First time only
npm start        # Every time

# Terminal 2 - Flutter
flutter run
```

### **Build APK for Sharing:**
```bash
# Switch to cloud backend (if deployed)
# Run: switch-to-cloud.bat
# OR manually edit .env: BACKEND_URL=https://your-backend-url.com

# Build APK
flutter clean
flutter build apk --release

# APK location:
# build\app\outputs\flutter-apk\app-release.apk
```

### **Switch Between Backends:**
```bash
# Switch to local backend
switch-to-local.bat

# Switch to cloud backend
switch-to-cloud.bat
```

---

## 🏗️ Deploy Backend (5-Minute Guide)

### **Railway (Easiest):**
1. Go to https://railway.app/
2. Sign up with GitHub
3. Click "New Project" → "Deploy from GitHub repo"
4. Select your backend folder
5. Add environment variables:
   - `STRIPE_SECRET_KEY=sk_test_...`
   - `PORT=4242`
6. Get your URL (e.g., `https://hikenity-backend-production.up.railway.app`)
7. Update Flutter `.env`: `BACKEND_URL=https://...`
8. Rebuild APK

---

## 📦 Files Location

| File | Location |
|------|----------|
| APK for sharing | `build\app\outputs\flutter-apk\app-release.apk` |
| Flutter .env | `.env` (project root) |
| Backend .env | `backend\.env` |
| Environment guide | `ENVIRONMENT_VARIABLES_GUIDE.md` |
| Deployment guide | `BACKEND_DEPLOYMENT_GUIDE.md` |
| Testing guide | `TESTING_GUIDE_FOR_TESTERS.md` |

---

## ✅ What Works Without Backend

Your friend can test these features without backend:
- ✅ Login/Sign up
- ✅ Browse trips
- ✅ View trip details
- ✅ Bookmark trips
- ✅ Profile management
- ✅ Book FREE trips
- ✅ Location tracking
- ✅ Rate trips
- ❌ Book PAID trips (requires backend)

---

## 🎯 Recommended Workflow

### **For You (Developer):**
1. **Local testing:** Run `npm start` when testing payments
2. **Quick testing:** Test free trips without backend
3. **Sharing:** Deploy to cloud, share APK

### **For Your Friend (Tester):**
1. Install APK you sent
2. Test all features
3. Report bugs/feedback
4. Payment testing only if backend is deployed

---

## 📝 Summary

| Your Goal | Backend Needed? | What to Do |
|-----------|----------------|------------|
| Test locally (with payments) | ✅ Yes | Run `npm start` |
| Test locally (without payments) | ❌ No | Just run app |
| Share APK | ⚠️ Recommended | Deploy to cloud first |
| Production release | ✅ Yes | Deploy to cloud |

---

## 🔗 Important Links

- **Deploy Backend:** See `BACKEND_DEPLOYMENT_GUIDE.md`
- **Environment Setup:** See `ENVIRONMENT_VARIABLES_GUIDE.md`
- **Testing Guide:** See `TESTING_GUIDE_FOR_TESTERS.md` (share with friends)

---

**💡 Pro Tip:** Deploy your backend to Railway/Heroku once, then you never need to run `npm start` locally again! Just update `.env` with the cloud URL and you're good to go! 🚀
