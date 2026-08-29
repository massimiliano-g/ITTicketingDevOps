using Microsoft.AspNetCore.Identity;
using TicketApi.Models;

namespace TicketApi.Services;

// Idempotente: sicuro da eseguire ad ogni avvio del container, crea solo
// ciò che manca. Il reset completo (con dati ticket di esempio) per le
// esercitazioni in aula arriva in una fase successiva — questo seed di base
// serve solo a garantire che esista sempre almeno un utente per ruolo con
// cui fare login.
public static class DemoSeeder
{
    public static async Task SeedAsync(IServiceProvider services)
    {
        var roleManager = services.GetRequiredService<RoleManager<IdentityRole>>();
        var userManager = services.GetRequiredService<UserManager<ApplicationUser>>();
        var configuration = services.GetRequiredService<IConfiguration>();

        foreach (var role in Roles.All)
        {
            if (!await roleManager.RoleExistsAsync(role))
            {
                await roleManager.CreateAsync(new IdentityRole(role));
            }
        }

        var demoPassword = configuration["DemoUsers:Password"] ?? "Demo123!";

        await EnsureUserAsync(userManager, "admin@ticketsystem.local", "Amministratore Demo", Roles.Admin, demoPassword);
        await EnsureUserAsync(userManager, "agent@ticketsystem.local", "Agente Demo", Roles.Agent, demoPassword);
        await EnsureUserAsync(userManager, "requester@ticketsystem.local", "Utente Demo", Roles.Requester, demoPassword);
    }

    private static async Task EnsureUserAsync(UserManager<ApplicationUser> userManager, string email, string displayName, string role, string password)
    {
        if (await userManager.FindByEmailAsync(email) is not null)
        {
            return;
        }

        var user = new ApplicationUser
        {
            UserName = email,
            Email = email,
            DisplayName = displayName,
            EmailConfirmed = true,
        };

        var result = await userManager.CreateAsync(user, password);
        if (result.Succeeded)
        {
            await userManager.AddToRoleAsync(user, role);
        }
    }
}
