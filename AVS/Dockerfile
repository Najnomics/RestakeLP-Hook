FROM golang:1.23.6-bookworm AS build

WORKDIR /build

# Copy full source
ADD . /build

# Build the RestakeLP Hook AVS performer
RUN make build

FROM debian:stable-slim

# Copy the built performer binary
COPY --from=build /build/bin/restake-lp-performer /usr/local/bin/restake-lp-performer

# Install required packages
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
     ca-certificates \
     curl \
     jq \
  && rm -rf /var/lib/apt/lists/*

# Create non-root user for security
RUN useradd -m -u 1000 restakelp && \
    chown -R restakelp:restakelp /usr/local/bin/restake-lp-performer

# Switch to non-root user
USER restakelp

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

# Expose port
EXPOSE 8080

# Set environment variables
ENV RESTAKE_LP_AVS_MODE=production
ENV LOG_LEVEL=info

# Run the RestakeLP Hook AVS performer
CMD ["/usr/local/bin/restake-lp-performer"]
