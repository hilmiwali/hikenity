# Use the official Flutter image from Google's Flutter repository
FROM google/flutter:3.24.3 AS build

# Set the working directory
WORKDIR /app

# Copy pubspec files
COPY pubspec.* /app/

# Fetch Flutter dependencies
RUN flutter pub get

# Copy the rest of the application
COPY . /app

# Build the Flutter app (if applicable, for example for web or desktop)
# Uncomment the next line if you're building for Flutter web:
# RUN flutter build web

# Optionally, compile the app if you need a native executable for a specific platform:
# RUN dart compile exe bin/hikenity_app.dart -o bin/hikenity_app

# Default command to run the Flutter app
CMD ["flutter", "run", "--no-sound-null-safety"]
