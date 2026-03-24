# Use the official Dart image for building
FROM dart:stable AS build

WORKDIR /app

# Copy pubspec and get dependencies
COPY pubspec.* ./
RUN dart pub get

# Copy the rest of the source code
COPY . .

# Compile the server
RUN dart compile exe bin/lambo_server.dart -o bin/server

# Use a minimal runtime image
FROM debian:buster-slim

# Copy the compiled binary and required runtime libraries from the build stage
COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/server

# Set default environment variables
ENV LAMBO_HOST=0.0.0.0
ENV LAMBO_PORT=8080

# Expose the port
EXPOSE 8080

# Run the server
ENTRYPOINT ["/app/bin/server"]
