# Use an official Go runtime as a parent image
FROM golang:1.23rc1-bullseye

# Set the working directory in the container
WORKDIR /app

# Copy the current directory contents into the container
COPY . .

# Remove any toolchain directives and update Go version
RUN sed -i '/^toolchain/d' go.mod

# Download all dependencies
RUN go mod tidy && go mod download

# Build the application
RUN go build -o server .

# Expose port 8080
ENV PORT=8080
EXPOSE 8080

# Run the executable
CMD ["./server"] 