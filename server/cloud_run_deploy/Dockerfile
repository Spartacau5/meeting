FROM debian:bullseye-slim

# Set the working directory in the container
WORKDIR /app

# Copy the application binary
COPY server .

# Make sure the binary is executable
RUN chmod +x ./server

# Container will listen on the port provided by Cloud Run
EXPOSE 8080

# Run the executable
CMD ["./server"]
