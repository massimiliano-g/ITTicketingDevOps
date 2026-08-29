using System.Text;
using System.Text.Json.Serialization;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using TicketApi.Data;
using TicketApi.Models;
using TicketApi.Services;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers()
    .AddJsonOptions(options => options.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter()));
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

builder.Services.AddDbContext<TicketDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("TicketDb")));

builder.Services
    .AddIdentityCore<ApplicationUser>(options =>
    {
        // Requisiti password ridotti apposta: è uno strumento didattico
        // usato in aula con account demo, non un sistema con dati reali.
        options.Password.RequireNonAlphanumeric = false;
        options.Password.RequireUppercase = false;
        options.Password.RequiredLength = 6;
    })
    .AddRoles<IdentityRole>()
    .AddEntityFrameworkStores<TicketDbContext>();

var jwtKey = builder.Configuration["Jwt:Key"]
    ?? throw new InvalidOperationException("Configurazione mancante: Jwt:Key");

builder.Services
    .AddAuthentication(options =>
    {
        options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
        options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
    })
    .AddJwtBearer(options =>
    {
        options.MapInboundClaims = false; // Mantiene "sub" come "sub", non lo rimappa a un claim type legacy.
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"] ?? "ticket-api",
            ValidAudience = builder.Configuration["Jwt:Audience"] ?? "ticket-web",
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),
        };
    });

builder.Services.AddAuthorization();
builder.Services.AddScoped<JwtTokenService>();

// In sviluppo salva su disco locale (nessuna dipendenza Azure per
// testare gli allegati); altrove usa Azure Blob Storage con Managed
// Identity — vedi commenti in AzureBlobFileStorageService.
if (builder.Environment.IsDevelopment())
{
    builder.Services.AddSingleton<IFileStorageService, LocalFileStorageService>();
}
else
{
    builder.Services.AddSingleton<IFileStorageService, AzureBlobFileStorageService>();
}

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
    var db = scope.ServiceProvider.GetRequiredService<TicketDbContext>();
    db.Database.Migrate();
    await DemoSeeder.SeedAsync(scope.ServiceProvider);
}

// Niente UseHttpsRedirection(): in Container Apps il TLS viene terminato
// dall'ingress dell'environment, il container espone solo HTTP internamente.
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.MapHealthChecks("/health");

app.Run();
