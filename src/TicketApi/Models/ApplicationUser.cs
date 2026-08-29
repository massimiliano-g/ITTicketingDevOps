using Microsoft.AspNetCore.Identity;

namespace TicketApi.Models;

public class ApplicationUser : IdentityUser
{
    public string DisplayName { get; set; } = string.Empty;
}

public static class Roles
{
    public const string Admin = "Admin";
    public const string Agent = "Agent";
    public const string Requester = "Requester";

    public static readonly string[] All = { Admin, Agent, Requester };
}
