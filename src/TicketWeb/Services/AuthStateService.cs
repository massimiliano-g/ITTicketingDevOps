using TicketWeb.Models;

namespace TicketWeb.Services;

// Scoped = per-circuito Blazor Server, che equivale a "per sessione utente
// nel browser" — ogni scheda/utente ha la propria istanza, isolata dalle
// altre. Nessuna persistenza oltre la sessione: un refresh di pagina o la
// chiusura del circuito richiede un nuovo login (accettabile per uno
// strumento didattico; una vera app produttiva userebbe anche un refresh
// token persistito, fuori scope qui).
public class AuthStateService
{
    public string? Token { get; private set; }
    public CurrentUser? User { get; private set; }
    public bool IsAuthenticated => Token is not null;

    public event Action? OnChange;

    public void SetSession(string token, CurrentUser user)
    {
        Token = token;
        User = user;
        OnChange?.Invoke();
    }

    public void Clear()
    {
        Token = null;
        User = null;
        OnChange?.Invoke();
    }
}
