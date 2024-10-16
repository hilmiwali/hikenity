# Use the official Dart SDK image from Dart
FROM dart:3.5.0 AS build

# Set the working directory in the container
WORKDIR /app

# Copy the pubspec and pubspec.lock files
COPY pubspec.* /app/

# Get dependencies
RUN dart pub get

# Copy the rest of the application
COPY . /app

# Compile the application
RUN dart compile exe bin/hikenity_app.dart -o bin/hikenity_app

# Create a second stage with a smaller base image
FROM scratch AS runtime

# Copy the compiled application from the build stage
COPY --from=build /app/bin/hikenity_app /app/hikenity_app

# Set the default command to run the compiled executable
CMD ["/app/hikenity_app"]
