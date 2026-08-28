using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;
using TicketWeb.Models;

namespace TicketWeb.Services;

public class TicketApiClient
{
    // Deve rispecchiare le JsonOptions configurate in TicketApi/Program.cs
    // (JsonStringEnumConverter): ticket-api restituisce Status/Priority come
    // stringhe ("Open", non "0"), quindi anche qui serve lo stesso converter
    // per (de)serializzare correttamente.
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        // ticket-api restituisce JSON in camelCase (default ASP.NET Core);
        // senza case-insensitive, "id"/"title"/... non veniva associato alle
        // proprietà C# Id/Title/... e tutto tornava al valore di default.
        PropertyNameCaseInsensitive = true,
        Converters = { new JsonStringEnumConverter() }
    };

    private readonly HttpClient _http;

    public TicketApiClient(HttpClient http)
    {
        _http = http;
    }

    public async Task<List<Ticket>> GetAllAsync() =>
        await _http.GetFromJsonAsync<List<Ticket>>("api/tickets", JsonOptions) ?? new List<Ticket>();

    public async Task<Ticket?> GetByIdAsync(int id) =>
        await _http.GetFromJsonAsync<Ticket>($"api/tickets/{id}", JsonOptions);

    public async Task<Ticket?> CreateAsync(Ticket ticket)
    {
        var response = await _http.PostAsJsonAsync("api/tickets", ticket, JsonOptions);
        response.EnsureSuccessStatusCode();
        return await response.Content.ReadFromJsonAsync<Ticket>(JsonOptions);
    }

    public async Task UpdateAsync(Ticket ticket)
    {
        var response = await _http.PutAsJsonAsync($"api/tickets/{ticket.Id}", ticket, JsonOptions);
        response.EnsureSuccessStatusCode();
    }

    public async Task DeleteAsync(int id)
    {
        var response = await _http.DeleteAsync($"api/tickets/{id}");
        response.EnsureSuccessStatusCode();
    }
}
