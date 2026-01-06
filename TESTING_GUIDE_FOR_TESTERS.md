# 📱 Hikenity App - Testing Guide for Friends

Hi! Thanks for helping test the Hikenity app! 🎉

---

## 📥 Installation

1. **Download the APK** file I sent you
2. **Install** on your Android device
3. **Open the app** and start exploring!

---

## ✅ What You Can Test

### **Full Access Features:**
- ✅ **Sign Up / Login** (Email or Google)
- ✅ **Browse Hiking Trips** (search, filter by state)
- ✅ **View Trip Details** (photos, description, difficulty)
- ✅ **Bookmark Trips** (save your favorites)
- ✅ **View Your Profile** (edit info, view stats)
- ✅ **Book FREE Trips** (no payment needed)
- ✅ **View Bookings** (ongoing and completed)
- ✅ **Rate Organizers** (after completing trips)
- ✅ **Location Tracking** (during trips)

### **Limited Features:**
- ⚠️ **Paid Trip Bookings** - May not work if backend is offline
  - Try free trips instead for full testing experience

---

## 🎮 Test Scenarios

### **Scenario 1: Browse as Guest**
1. Open app
2. Click "Continue as Guest"
3. Browse available trips
4. View trip details
5. **Note:** You'll need to login to book trips

### **Scenario 2: Sign Up & Book Free Trip**
1. Click "Sign Up here"
2. Create account (email or Google)
3. Browse trips
4. Find a FREE trip (price: RM 0)
5. Click "Book Now"
6. Complete booking
7. Check "My Trips" tab

### **Scenario 3: Test Organizer Features**
1. Create account as Organizer
2. Wait for admin approval (or let me know to approve you)
3. Create a hiking trip
4. Upload photos
5. Set difficulty level
6. Publish trip

### **Scenario 4: Test Payment Flow** (if backend is running)
1. Find a paid trip
2. Click "Book Now"
3. Enter payment details (use Stripe test card)
4. Complete payment
5. Download receipt

**Stripe Test Card:**
```
Card Number: 4242 4242 4242 4242
Expiry: Any future date (e.g., 12/25)
CVC: Any 3 digits (e.g., 123)
```

---

## 🐛 What to Report

Please let me know if you encounter:
- ❌ App crashes
- ❌ Login issues
- ❌ Features not working
- ❌ Confusing UI/UX
- ❌ Slow performance
- ❌ Any errors or bugs

### **How to Report:**
Send me:
1. 📸 **Screenshot** of the issue
2. 📝 **Steps** to reproduce
3. 📱 **Device** info (model, Android version)
4. ⏰ **When** it happened

---

## ⚠️ Known Limitations

1. **Payment bookings might fail** if backend server is offline
   - **Solution:** Test with free trips instead

2. **Location tracking** requires GPS/Location permissions
   - **Solution:** Allow location permissions when prompted

3. **Firebase Messaging warnings** on some devices
   - **Solution:** Ignore these (not affecting functionality)

---

## 💬 Feedback Questions

Please share your thoughts on:
1. 🎨 **Design** - Is the UI attractive and easy to use?
2. 📱 **Navigation** - Can you find features easily?
3. ⚡ **Performance** - Is the app fast and responsive?
4. 🔧 **Features** - What features would you like to see?
5. 🐛 **Bugs** - Did you encounter any issues?

---

## 🆘 Troubleshooting

### **App won't install**
- Check if "Install from unknown sources" is enabled
- Android Settings → Security → Unknown Sources

### **Login not working**
- Check your internet connection
- Try different login method (Email vs Google)

### **Trips not loading**
- Check internet connection
- Pull down to refresh

### **Location not working**
- Enable GPS in device settings
- Grant location permission to app

---

## 📞 Contact

Issues or questions?  
Contact me: [Your contact info]

---

**Thank you for testing! Your feedback helps make Hikenity better! 🙏**
