# Use a recent Flutter image from cirrusci with Dart >= 3.5.0
FROM cirrusci/flutter:3.13.3 AS build

# Set the working directory
WORKDIR /app

# Copy pubspec files and fetch Flutter dependencies
COPY pubspec.* /app/
RUN flutter pub get

# Copy the rest of the application
COPY . /app

# Build the Flutter app
RUN flutter build web
