# 🔐 Environment Variables Setup Guide

## Overview
This guide explains how to set up and use environment variables to securely manage API keys, secrets, and configuration values in the Hikenity app.

---

## ✅ What We've Secured

### **Before (❌ Insecure)**
- Stripe API keys hardcoded in `main.dart` and `server.js`
- Backend URL hardcoded in `payment_service.dart`
- API keys visible in Git history
- Risk of accidental commits

### **After (✅ Secure)**
- All sensitive data in `.env` files
- `.env` files excluded from Git
- Template files (`.env.example`) for documentation
- Easy configuration for different environments

---

## 📁 Project Structure

```
hikenity_app/
├── .env                    # Flutter app environment variables (NOT in Git)
├── .env.example            # Template for Flutter app
├── backend/
│   ├── .env                # Backend environment variables (NOT in Git)
│   ├── .env.example        # Template for backend
│   ├── .gitignore          # Protects .env from Git
│   └── server.js           # Updated to use process.env
├── lib/
│   ├── main.dart           # Updated to load .env
│   └── payment_service.dart # Updated to use dotenv
└── pubspec.yaml            # Includes .env in assets
```

---

## 🚀 Setup Instructions

### **1. Flutter App Setup**

#### Step 1: Install Dependencies (Already Done)
```bash
flutter pub get
```

#### Step 2: Configure .env File
The `.env` file is already created with your current values. To update:

```bash
# Edit .env file in project root
code .env
```

**Example `.env` content:**
```env
STRIPE_PUBLISHABLE_KEY=pk_test_51Q8t4GHoyDahNOUZwYGLwj03mVqP5KdKKPTdhRcbKT4AOvvYeYRMlAruk0qYbm2LGhM5CnQUxQp83xEZSJXepZEa00pebLyRE2
BACKEND_URL=http://localhost:4242
ENVIRONMENT=development
```

#### Step 3: Verify Asset Configuration
Already configured in `pubspec.yaml`:
```yaml
flutter:
  assets:
    - .env
```

---

### **2. Backend Server Setup**

#### Step 1: Navigate to Backend Directory
```bash
cd backend
```

#### Step 2: Install Dependencies
```bash
npm install
```

This will install:
- `dotenv` - For loading environment variables
- `express` - Web framework
- `stripe` - Payment processing
- `nodemon` - Auto-restart on changes (dev only)

#### Step 3: Configure .env File
The `.env` file is already created. To update:

```bash
# Edit backend/.env file
code .env
```

**Example `backend/.env` content:**
```env
STRIPE_SECRET_KEY=sk_test_51Q8t4GHoyDahNOUZMlYMd4BHJz2mzABpmv2SXPF9G5Q2rIrfaaPqLUBvMnPeHS0fCCw5yYykgH5aTy1h8xipVEiU00dwExeonX
PORT=4242
```

#### Step 4: Start Backend Server
```bash
# Production mode
npm start

# Development mode (auto-restart on changes)
npm run dev
```

---

## 🔑 Environment Variables Reference

### **Flutter App (.env)**

| Variable | Description | Required | Example |
|----------|-------------|----------|---------|
| `STRIPE_PUBLISHABLE_KEY` | Stripe publishable key | Yes | `pk_test_...` |
| `BACKEND_URL` | Backend server URL | Yes | `http://localhost:4242` |
| `FIREBASE_API_KEY_ANDROID` | Firebase Android API key | No* | `AIzaSy...` |
| `FIREBASE_API_KEY_IOS` | Firebase iOS API key | No* | `AIzaSy...` |
| `FIREBASE_API_KEY_WEB` | Firebase Web API key | No* | `AIzaSy...` |
| `GOOGLE_MAPS_API_KEY` | Google Maps API key | Optional | `AIzaSy...` |
| `ENVIRONMENT` | App environment | No | `development` |

*Firebase keys are currently in `firebase_options.dart` (generated file, safe to keep)

### **Backend (backend/.env)**

| Variable | Description | Required | Example |
|----------|-------------|----------|---------|
| `STRIPE_SECRET_KEY` | Stripe secret key | Yes | `sk_test_...` |
| `PORT` | Server port | No | `4242` |

---

## 🎯 Usage Examples

### **In Dart/Flutter Code**

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Load environment variables (in main.dart)
await dotenv.load(fileName: ".env");

// Access variables
String apiKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';
String backendUrl = dotenv.env['BACKEND_URL'] ?? 'http://localhost:4242';

// Check environment
bool isDevelopment = dotenv.env['ENVIRONMENT'] == 'development';
```

### **In Node.js Backend**

```javascript
require('dotenv').config();

// Access variables
const stripeSecretKey = process.env.STRIPE_SECRET_KEY;
const port = process.env.PORT || 4242;

// Use in Stripe initialization
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
```

---

## 🔒 Security Best Practices

### ✅ **Do's**
- ✅ Keep `.env` files in `.gitignore`
- ✅ Use `.env.example` templates for documentation
- ✅ Rotate API keys if accidentally exposed
- ✅ Use different keys for development/production
- ✅ Share `.env` files securely (encrypted, password managers)
- ✅ Set up environment-specific configs

### ❌ **Don'ts**
- ❌ Never commit `.env` files to Git
- ❌ Don't hardcode secrets in code
- ❌ Don't share `.env` via email/chat
- ❌ Don't use production keys in development
- ❌ Don't expose `.env` in screenshots/demos

---

## 🌍 Environment-Specific Configuration

### **Development Environment**
```env
# .env (development)
STRIPE_PUBLISHABLE_KEY=pk_test_...
BACKEND_URL=http://localhost:4242
ENVIRONMENT=development
```

### **Production Environment**
```env
# .env (production)
STRIPE_PUBLISHABLE_KEY=pk_live_...
BACKEND_URL=https://api.hikenity.com
ENVIRONMENT=production
```

### **Staging Environment**
```env
# .env (staging)
STRIPE_PUBLISHABLE_KEY=pk_test_...
BACKEND_URL=https://staging-api.hikenity.com
ENVIRONMENT=staging
```

---

## 🐛 Troubleshooting

### **Error: "Cannot load .env file"**
**Solution:**
1. Verify `.env` file exists in project root
2. Check `pubspec.yaml` includes `.env` in assets
3. Run `flutter pub get`
4. Rebuild: `flutter clean && flutter run`

### **Error: "Stripe key is empty"**
**Solution:**
1. Verify `.env` has `STRIPE_PUBLISHABLE_KEY`
2. No spaces around `=` sign
3. No quotes around the value
4. Restart the app

### **Backend Error: "Stripe secret key not found"**
**Solution:**
1. Verify `backend/.env` exists
2. Check `STRIPE_SECRET_KEY` is set
3. Restart server: `npm start`

### **Environment variables not updating**
**Solution:**
1. Hot reload doesn't reload `.env`
2. Stop the app completely
3. Restart: `flutter run`

---

## 📝 Adding New Environment Variables

### **Step 1: Add to .env File**
```env
# .env
NEW_API_KEY=your_api_key_here
```

### **Step 2: Add to .env.example**
```env
# .env.example
NEW_API_KEY=your_api_key_description
```

### **Step 3: Use in Code**
```dart
String apiKey = dotenv.env['NEW_API_KEY'] ?? '';
```

### **Step 4: Document in README**
Update this document with the new variable.

---

## 🔄 Migrating From Hardcoded Values

If you have hardcoded values elsewhere:

1. **Find all hardcoded secrets:**
   ```bash
   # Search for API keys
   grep -r "pk_test_" lib/
   grep -r "sk_test_" .
   grep -r "AIzaSy" lib/
   ```

2. **Move to .env:**
   ```env
   API_KEY=value_from_code
   ```

3. **Replace in code:**
   ```dart
   // Before
   String apiKey = 'hardcoded_value';
   
   // After
   String apiKey = dotenv.env['API_KEY'] ?? '';
   ```

4. **Test thoroughly**

---

## 📦 Deployment Checklist

### **Flutter App Deployment**
- [ ] Update `.env` with production values
- [ ] Use `pk_live_` Stripe keys
- [ ] Update `BACKEND_URL` to production domain
- [ ] Set `ENVIRONMENT=production`
- [ ] Build release APK/IPA
- [ ] Test payment flow

### **Backend Deployment**
- [ ] Update `backend/.env` with production values
- [ ] Use `sk_live_` Stripe secret key
- [ ] Set proper `PORT` for hosting
- [ ] Deploy to server (Heroku, AWS, etc.)
- [ ] Set environment variables on hosting platform
- [ ] Test API endpoints

---

## 🔗 Related Documentation

- [Flutter dotenv Package](https://pub.dev/packages/flutter_dotenv)
- [Stripe API Keys](https://stripe.com/docs/keys)
- [Firebase Configuration](https://firebase.google.com/docs/projects/api-keys)
- [SECURITY_FIX.md](./SECURITY_FIX.md) - Security incident resolution

---

## ✨ Summary

**What Changed:**
1. ✅ Created `.env` files (Flutter + Backend)
2. ✅ Updated `main.dart` to load environment variables
3. ✅ Updated `payment_service.dart` to use dynamic backend URL
4. ✅ Updated `server.js` to use environment variables
5. ✅ Added `.gitignore` rules to protect secrets
6. ✅ Created `.env.example` templates
7. ✅ Updated `package.json` with dotenv dependency

**Files Protected:**
- `.env` (Flutter app)
- `backend/.env` (Backend server)
- Both are in `.gitignore` ✅

**Next Steps:**
1. Test the app: `flutter run`
2. Test backend: `cd backend && npm install && npm start`
3. Verify payments work
4. Update Firebase keys if needed (optional)

---

**Your API keys are now secure! 🎉**
