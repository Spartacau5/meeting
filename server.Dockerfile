FROM alpine:3.18

# Install CA certificates and timezone data
RUN apk --no-cache add ca-certificates tzdata && \
    cp /usr/share/zoneinfo/UTC /etc/localtime && \
    echo "UTC" > /etc/timezone

# Set the working directory
WORKDIR /app

# Copy the pre-built binary from the build step
ARG SERVER_PATH
COPY ${SERVER_PATH} /app/server

# Copy necessary config files
COPY server/.env /app/

# Make the binary executable
RUN chmod +x /app/server

# Expose port
ENV PORT=8080
EXPOSE 8080

# Run the binary
CMD ["./server"] 