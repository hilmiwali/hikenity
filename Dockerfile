# Use a stable Flutter image from cirrusci
FROM cirrusci/flutter:stable AS build

# Set the working directory
WORKDIR /app

# Copy pubspec files and fetch Flutter dependencies
COPY pubspec.* /app/
RUN flutter pub get

# Copy the rest of the application
COPY . /app

# Build the Flutter app
RUN flutter build web
