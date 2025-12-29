# Hikenity Notifications - Firebase Cloud Functions

This directory contains Firebase Cloud Functions for handling push notifications in the Hikenity app.

## 🔐 Security Setup

### Firebase Service Account Credentials

**⚠️ IMPORTANT: NEVER commit your actual service account credentials to Git!**

1. **Download your Firebase service account key:**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Select your project (hikenity)
   - Go to Project Settings > Service Accounts
   - Click "Generate New Private Key"
   - Save the JSON file

2. **Rename and place the file:**
   ```bash
   # Rename your downloaded file to match the expected name
   mv ~/Downloads/hikenity-firebase-adminsdk-*.json ./notifications/hikenity-firebase-adminsdk-e1ws1-71d0f7c495.json
   ```

3. **Verify it's ignored by Git:**
   ```bash
   git status
   # The service account JSON file should NOT appear in the output
   ```

4. **File structure reference:**
   - See `serviceAccountKey.json.example` for the expected structure
   - Your actual file should follow the same format but with real credentials

## 📦 Installation

```bash
cd notifications
npm install
```

## 🚀 Deployment

```bash
# Deploy to Firebase
firebase deploy --only functions:notifications
```

## 🔧 Environment Variables

If you need to use the service account in your local development, consider using environment variables or Firebase emulators instead of committing the actual file.

## 📄 Files in this Directory

- `index.js` - Cloud Functions code
- `package.json` - Dependencies
- `serviceAccountKey.json.example` - Template file (safe to commit)
- `hikenity-firebase-adminsdk-*.json` - **ACTUAL CREDENTIALS (NEVER COMMIT)**

## 🆘 If Credentials Were Accidentally Committed

1. Immediately revoke the service account key in Firebase Console
2. Generate a new key
3. Remove the file from Git history (see root README for instructions)
4. Update the new key in your local environment
