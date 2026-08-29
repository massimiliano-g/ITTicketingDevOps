using System.Net.Http.Headers;

namespace TicketWeb.Services;

// Aggiunge automaticamente "Authorization: Bearer <token>" a ogni chiamata
// verso ticket-api, se l'utente ha fatto login — un solo punto invece di
// ripetere la stessa riga in ogni metodo di TicketApiClient.
public class AuthHeaderHandler : DelegatingHandler
{
    private readonly AuthStateService _authState;

    public AuthHeaderHandler(AuthStateService authState)
    {
        _authState = authState;
    }

    protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
    {
        if (_authState.Token is not null)
        {
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", _authState.Token);
        }

        return base.SendAsync(request, cancellationToken);
    }
}
