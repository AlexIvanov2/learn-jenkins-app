FROM mcr.microsoft.com/playwright:v1.39.0-jammy

# Install jq once (so you can parse Netlify JSON without apt-get in the pipeline)
RUN apt-get update \
  && apt-get install -y --no-install-recommends jq \
  && rm -rf /var/lib/apt/lists/*

# Install Netlify CLI globally (pin a version for stability)
RUN npm install -g netlify-cli@17