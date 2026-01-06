@echo off
REM Switch backend to LOCAL (localhost:4242)

echo Switching to LOCAL backend...
echo.

(
echo # Hikenity App Environment Variables
echo # LOCAL DEVELOPMENT CONFIGURATION
echo.
echo # ======================
echo # STRIPE CONFIGURATION
echo # ======================
echo STRIPE_PUBLISHABLE_KEY=pk_test_51Q8t4GHoyDahNOUZwYGLwj03mVqP5KdKKPTdhRcbKT4AOvvYeYRMlAruk0qYbm2LGhM5CnQUxQp83xEZSJXepZEa00pebLyRE2
echo.
echo # ======================
echo # BACKEND CONFIGURATION
echo # ======================
echo BACKEND_URL=http://localhost:4242
echo.
echo # ======================
echo # FIREBASE CONFIGURATION
echo # ======================
echo FIREBASE_API_KEY_ANDROID=AIzaSyA5V7vHvZuIEBKJHszjC_qA04zGfhuEvfE
echo FIREBASE_API_KEY_IOS=AIzaSyCZdYZqaZ8tXIhBvyRNkzaUWb4Mn50dLtE
echo FIREBASE_API_KEY_WEB=AIzaSyDxy8a5MCmFoyI_2yhDSnpVEvFoOGUPfzw
echo FIREBASE_PROJECT_ID=hikenity
echo FIREBASE_APP_ID_ANDROID=1:464200726815:android:2ebd747d46bbf2e2d0d82a
echo FIREBASE_APP_ID_IOS=1:464200726815:ios:a1e15cd92a17f79cd0d82a
echo FIREBASE_MESSAGING_SENDER_ID=464200726815
echo.
echo # ======================
echo # OTHER CONFIGURATION
echo # ======================
echo ENVIRONMENT=development
) > .env

echo ✅ Switched to LOCAL backend: http://localhost:4242
echo.
echo Remember to run backend server:
echo   cd backend
echo   npm start
echo.
pause
