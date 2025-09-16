FROM nginx:alpine

# Copy unified nginx config
COPY nginx.conf /etc/nginx/nginx.conf

# Create certs directory inside image (will be over-mounted in compose)
RUN mkdir -p /etc/nginx/certs

# Expose HTTP and HTTPS
EXPOSE 80 443

# Run nginx
CMD ["nginx", "-g", "daemon off;"]
