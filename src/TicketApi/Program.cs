using System.Text.Json.Serialization;
using Microsoft.EntityFrameworkCore;
using TicketApi.Data;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers()
    // Status/Priority in JSON come stringhe ("Open", non "0") — contratto API
    // più leggibile per i client (incluso TicketWeb) e coerente con come sono
    // salvati nel database (vedi TicketDbContext.OnModelCreating).
    .AddJsonOptions(options => options.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter()));
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// La connection string usa "Authentication=Active Directory Default" (vedi
// appsettings.Development.json / user-secrets) — nessuna password: in locale
// autentica con la tua identità "az login", in Container Apps autenticherà
// con la Managed Identity dell'app (da configurare quando creeremo la
// Container App vera e propria).
builder.Services.AddDbContext<TicketDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("TicketDb")));

builder.Services.AddHealthChecks()
    .AddDbContextCheck<TicketDbContext>();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// Applica automaticamente le migration pendenti all'avvio: per un progetto
// di pratica con ambienti effimeri (destroy/apply frequenti) evita di dover
// rilanciare "dotnet ef database update" a mano ogni volta. In un servizio
// di produzione reale le migration andrebbero invece eseguite come step
// separato della pipeline CI/CD, non ad ogni avvio del container.
using (var scope = app.Services.CreateScope())
{
    scope.ServiceProvider.GetRequiredService<TicketDbContext>().Database.Migrate();
}

// Niente UseHttpsRedirection(): in Container Apps il TLS viene terminato
// dall'ingress dell'environment, il container espone solo HTTP internamente.
app.UseAuthorization();

app.MapControllers();
app.MapHealthChecks("/health");

app.Run();
