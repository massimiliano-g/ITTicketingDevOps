using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.IdentityModel.Tokens;
using TicketApi.Models;

namespace TicketApi.Services;

public class JwtTokenService
{
    private readonly IConfiguration _configuration;

    public JwtTokenService(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    public (string Token, DateTime ExpiresAt) CreateToken(ApplicationUser user, IList<string> roles)
    {
        var key = _configuration["Jwt:Key"]
            ?? throw new InvalidOperationException("Configurazione mancante: Jwt:Key");
        var issuer = _configuration["Jwt:Issuer"] ?? "ticket-api";
        var audience = _configuration["Jwt:Audience"] ?? "ticket-web";
        var expiryMinutes = _configuration.GetValue("Jwt:ExpiryMinutes", 480);

        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, user.Id),
            new(JwtRegisteredClaimNames.Email, user.Email ?? string.Empty),
            new("displayName", user.DisplayName),
        };
        claims.AddRange(roles.Select(role => new Claim(ClaimTypes.Role, role)));

        var credentials = new SigningCredentials(
            new SymmetricSecurityKey(Encoding.UTF8.GetBytes(key)),
            SecurityAlgorithms.HmacSha256);

        var expiresAt = DateTime.UtcNow.AddMinutes(expiryMinutes);

        var token = new JwtSecurityToken(
            issuer: issuer,
            audience: audience,
            claims: claims,
            expires: expiresAt,
            signingCredentials: credentials);

        return (new JwtSecurityTokenHandler().WriteToken(token), expiresAt);
    }
}
