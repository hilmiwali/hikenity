# Use the Cirrus Labs Flutter image
FROM ghcr.io/cirruslabs/flutter:3.13.6 AS build

# Set the working directory
WORKDIR /app

# Copy pubspec files
COPY pubspec.* /app/

# Fetch Flutter dependencies
RUN flutter pub get

# Copy the rest of the application
COPY . /app

# Uncomment this if you are building for Flutter web or desktop:
# RUN flutter build web

# Default command to run the Flutter app
CMD ["flutter", "run", "--no-sound-null-safety"]
