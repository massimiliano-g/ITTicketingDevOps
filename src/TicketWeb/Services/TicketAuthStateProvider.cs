using System.Security.Claims;
using Microsoft.AspNetCore.Components.Authorization;

namespace TicketWeb.Services;

// Ponte tra AuthStateService (il nostro stato, JWT + utente) e il modello
// di autorizzazione nativo di Blazor ([Authorize], <AuthorizeView>, ecc.) —
// senza questo, gli attributi [Authorize] non avrebbero nulla da leggere.
public class TicketAuthStateProvider : AuthenticationStateProvider
{
    private readonly AuthStateService _authState;
    private static readonly AuthenticationState Anonymous = new(new ClaimsPrincipal(new ClaimsIdentity()));

    public TicketAuthStateProvider(AuthStateService authState)
    {
        _authState = authState;
        _authState.OnChange += () => NotifyAuthenticationStateChanged(GetAuthenticationStateAsync());
    }

    public override Task<AuthenticationState> GetAuthenticationStateAsync()
    {
        if (_authState.User is null)
        {
            return Task.FromResult(Anonymous);
        }

        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, _authState.User.Id),
            new(ClaimTypes.Name, _authState.User.DisplayName),
            new(ClaimTypes.Email, _authState.User.Email),
        };
        claims.AddRange(_authState.User.Roles.Select(role => new Claim(ClaimTypes.Role, role)));

        var identity = new ClaimsIdentity(claims, authenticationType: "jwt");
        return Task.FromResult(new AuthenticationState(new ClaimsPrincipal(identity)));
    }
}
