# ==============================================================================
# Dockerfile multi-stage per TicketApi
# ==============================================================================
# Stage "build": usa l'immagine SDK completa (~800MB, include compilatore)
# solo per compilare/pubblicare.
# Stage "final": usa la sola immagine runtime ASP.NET (~200MB, niente SDK/
# compilatore) — superficie di attacco più piccola, ed è l'UNICA immagine
# che viene davvero pushata su ACR e girata dal Container App. Lo stage
# "build" viene scartato a fine build (pattern multi-stage).
# ==============================================================================

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY TicketApi.csproj .
RUN dotnet restore

COPY . .
RUN dotnet publish -c Release -o /app/publish --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app

COPY --from=build /app/publish .

EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080
ENV ASPNETCORE_ENVIRONMENT=Production

ENTRYPOINT ["dotnet", "TicketApi.dll"]
