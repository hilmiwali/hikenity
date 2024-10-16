# Use the Cirrus Labs Flutter image with a compatible Dart SDK version
FROM ghcr.io/cirruslabs/flutter:3.13.6 AS build

# Set the working directory
WORKDIR /app

# Avoid running Flutter as root by switching to a non-root user
RUN useradd -ms /bin/bash flutteruser
USER flutteruser

# Ensure Git doesn't block due to safe directory checks
RUN git config --global --add safe.directory /sdks/flutter

# Copy pubspec files and fetch Flutter dependencies
COPY pubspec.* /app/
RUN flutter pub get

# Copy the rest of the application
COPY . /app

# Default command to run the Flutter app
CMD ["flutter", "run", "--no-sound-null-safety"]
