using TicketWeb.Components;
using TicketWeb.Services;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddRazorComponents()
    .AddInteractiveServerComponents();

// Client HTTP tipizzato verso ticket-api. In locale punta a localhost (vedi
// appsettings.Development.json); nel Container Apps Environment punterà
// all'FQDN interno del Container App di ticket-api (comunicazione
// servizio-a-servizio, da configurare quando creeremo le Container App vere
// e proprie).
builder.Services.AddHttpClient<TicketApiClient>(client =>
{
    var baseUrl = builder.Configuration["TicketApi:BaseUrl"]
        ?? throw new InvalidOperationException("Configurazione mancante: TicketApi:BaseUrl");
    client.BaseAddress = new Uri(baseUrl);
});

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

app.Run();
