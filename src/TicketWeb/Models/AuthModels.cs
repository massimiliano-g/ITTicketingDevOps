namespace TicketWeb.Models;

public class CurrentUser
{
    public string Id { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public List<string> Roles { get; set; } = new();
}

public class LoginResult
{
    public string Token { get; set; } = string.Empty;
    public DateTime ExpiresAt { get; set; }
    public CurrentUser User { get; set; } = new();
}
