using System.Net.Http.Headers;
using Microsoft.AspNetCore.Components.Authorization;
using TicketWeb.Components;
using TicketWeb.Services;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddRazorComponents()
    .AddInteractiveServerComponents();

// AuthStateService/TicketAuthStateProvider sono Scoped: un'istanza per
// circuito Blazor Server, cioè per sessione utente nel browser — nessuna
// fuga di stato tra utenti diversi collegati contemporaneamente.
builder.Services.AddAuthorizationCore();
builder.Services.AddScoped<AuthStateService>();
builder.Services.AddScoped<AuthenticationStateProvider, TicketAuthStateProvider>();
builder.Services.AddTransient<AuthHeaderHandler>();

// Client HTTP tipizzato verso ticket-api. In locale punta a localhost (vedi
// appsettings.Development.json); nel Container Apps Environment punterà
// all'FQDN interno del Container App di ticket-api (comunicazione
// servizio-a-servizio). AuthHeaderHandler aggiunge automaticamente il
// token JWT dell'utente loggato a ogni richiesta.
builder.Services.AddHttpClient<TicketApiClient>(client =>
{
    var baseUrl = builder.Configuration["TicketApi:BaseUrl"]
        ?? throw new InvalidOperationException("Configurazione mancante: TicketApi:BaseUrl");
    client.BaseAddress = new Uri(baseUrl);
}).AddHttpMessageHandler<AuthHeaderHandler>();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error", createScopeForErrors: true);
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

// Niente UseHttpsRedirection(): come per ticket-api, in Container Apps il
// TLS viene terminato dall'ingress dell'environment.
app.UseStaticFiles();
app.UseAntiforgery();

app.MapRazorComponents<App>()
    .AddInteractiveServerRenderMode();

// Proxy di download: il browser non può raggiungere ticket-api (ingress
// interno) direttamente, quindi il link scaricabile passa da qui. Il token
// viaggia come query string — accettabile per un token demo a vita breve
// su rete interna, non è il pattern che useresti con dati reali sensibili
// (un vero sistema userebbe un URL di download firmato a scadenza breve).
app.MapGet("/download/{ticketId:int}/{attachmentId:int}", async (
    int ticketId, int attachmentId, string? token, IHttpClientFactory httpClientFactory, IConfiguration configuration) =>
{
    if (string.IsNullOrEmpty(token))
    {
        return Results.Unauthorized();
    }

    var baseUrl = configuration["TicketApi:BaseUrl"]!;
    var client = httpClientFactory.CreateClient();
    client.BaseAddress = new Uri(baseUrl);
    client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

    var response = await client.GetAsync($"api/tickets/{ticketId}/attachments/{attachmentId}");
    if (!response.IsSuccessStatusCode)
    {
        return Results.StatusCode((int)response.StatusCode);
    }

    var contentType = response.Content.Headers.ContentType?.ToString() ?? "application/octet-stream";
    var fileName = response.Content.Headers.ContentDisposition?.FileNameStar
        ?? response.Content.Headers.ContentDisposition?.FileName
        ?? "download";
    var stream = await response.Content.ReadAsStreamAsync();

    return Results.Stream(stream, contentType, fileName);
});

app.Run();
