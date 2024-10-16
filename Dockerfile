# Use a stable Flutter image from cirrusci
FROM cirrusci/flutter:stable AS build

# Set the working directory
WORKDIR /app

# Fix permissions for the Flutter SDK
RUN sudo chown -R flutteruser /sdks/flutter

# Copy pubspec files and fetch Flutter dependencies
COPY pubspec.* /app/
RUN flutter pub get

# Copy the rest of the application
COPY . /app

# Build the Flutter app
RUN flutter build web
