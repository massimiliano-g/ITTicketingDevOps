# ==============================================================================
# Dockerfile multi-stage per TicketWeb (Blazor Server)
# ==============================================================================
# Stesso pattern di TicketApi/Dockerfile: build con l'SDK, runtime finale con
# la sola immagine ASP.NET.
# ==============================================================================

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY TicketWeb.csproj .
RUN dotnet restore

COPY . .
RUN dotnet publish -c Release -o /app/publish --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app

COPY --from=build /app/publish .

EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080
ENV ASPNETCORE_ENVIRONMENT=Production

ENTRYPOINT ["dotnet", "TicketWeb.dll"]
