# Multi-stage build for .NET 8 minimal API.
# Build context is apps/sample-dotnet-api/ (set in azure.yaml), so paths
# below are relative to that directory.

# ---------- Build stage ----------
FROM mcr.microsoft.com/dotnet/sdk:8.0-alpine AS build
WORKDIR /source

# Copy csproj first to leverage Docker layer caching for restore.
COPY src/sample-dotnet-api.csproj src/
RUN dotnet restore src/sample-dotnet-api.csproj

# Copy the rest of the source and publish.
COPY src/ src/
RUN dotnet publish src/sample-dotnet-api.csproj \
    -c Release \
    -o /app/publish \
    --no-restore \
    /p:UseAppHost=false

# ---------- Runtime stage ----------
FROM mcr.microsoft.com/dotnet/aspnet:8.0-alpine AS runtime
WORKDIR /app

# Run as the non-root 'app' user that ships in the aspnet:8.0-alpine image.
USER app

ENV ASPNETCORE_URLS=http://+:8080 \
    DOTNET_RUNNING_IN_CONTAINER=true \
    DOTNET_EnableDiagnostics=0

EXPOSE 8080

COPY --from=build --chown=app:app /app/publish .

ENTRYPOINT ["dotnet", "sample-dotnet-api.dll"]
