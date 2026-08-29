using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;
using TicketWeb.Models;

namespace TicketWeb.Services;

public class TicketApiClient
{
    // ticket-api restituisce JSON in camelCase con enum come stringhe ("Open",
    // non "0") — serve lo stesso converter e il matching case-insensitive
    // per (de)serializzare correttamente (vedi lezione appresa: senza
    // PropertyNameCaseInsensitive tutto torna ai valori di default).
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true,
        Converters = { new JsonStringEnumConverter() }
    };

    private readonly HttpClient _http;

    public TicketApiClient(HttpClient http)
    {
        _http = http;
    }

    public async Task<LoginResult> LoginAsync(string email, string password)
    {
        var response = await _http.PostAsJsonAsync("api/auth/login", new { email, password }, JsonOptions);
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<LoginResult>(JsonOptions))!;
    }

    public async Task<List<Ticket>> GetAllAsync(TicketStatus? status = null) =>
        await _http.GetFromJsonAsync<List<Ticket>>(
            status is null ? "api/tickets" : $"api/tickets?status={status}", JsonOptions) ?? new List<Ticket>();

    public async Task<Ticket?> GetByIdAsync(int id) =>
        await _http.GetFromJsonAsync<Ticket>($"api/tickets/{id}", JsonOptions);

    public async Task<Ticket?> CreateAsync(string title, string? description, TicketType type, TicketPriority priority)
    {
        var response = await _http.PostAsJsonAsync("api/tickets", new { title, description, type, priority }, JsonOptions);
        response.EnsureSuccessStatusCode();
        return await response.Content.ReadFromJsonAsync<Ticket>(JsonOptions);
    }

    public async Task UpdateAsync(int id, string title, string? description, TicketPriority priority, string? assigneeId)
    {
        var response = await _http.PutAsJsonAsync($"api/tickets/{id}", new { title, description, priority, assigneeId }, JsonOptions);
        response.EnsureSuccessStatusCode();
    }

    public async Task<Ticket?> TransitionAsync(int id, TicketStatus newStatus)
    {
        var response = await _http.PostAsJsonAsync($"api/tickets/{id}/transition", new { newStatus }, JsonOptions);
        response.EnsureSuccessStatusCode();
        return await response.Content.ReadFromJsonAsync<Ticket>(JsonOptions);
    }

    public async Task DeleteAsync(int id)
    {
        var response = await _http.DeleteAsync($"api/tickets/{id}");
        response.EnsureSuccessStatusCode();
    }

    public async Task<List<TicketComment>> GetCommentsAsync(int ticketId) =>
        await _http.GetFromJsonAsync<List<TicketComment>>($"api/tickets/{ticketId}/comments", JsonOptions) ?? new List<TicketComment>();

    public async Task<TicketComment?> AddCommentAsync(int ticketId, string body)
    {
        var response = await _http.PostAsJsonAsync($"api/tickets/{ticketId}/comments", new { body }, JsonOptions);
        response.EnsureSuccessStatusCode();
        return await response.Content.ReadFromJsonAsync<TicketComment>(JsonOptions);
    }

    public async Task<List<Attachment>> GetAttachmentsAsync(int ticketId) =>
        await _http.GetFromJsonAsync<List<Attachment>>($"api/tickets/{ticketId}/attachments", JsonOptions) ?? new List<Attachment>();

    public async Task UploadAttachmentAsync(int ticketId, Stream content, string fileName, string contentType)
    {
        using var formContent = new MultipartFormDataContent();
        using var streamContent = new StreamContent(content);
        streamContent.Headers.ContentType = new System.Net.Http.Headers.MediaTypeHeaderValue(
            string.IsNullOrEmpty(contentType) ? "application/octet-stream" : contentType);
        formContent.Add(streamContent, "file", fileName);

        var response = await _http.PostAsync($"api/tickets/{ticketId}/attachments", formContent);
        response.EnsureSuccessStatusCode();
    }

    public async Task ResetDemoDataAsync()
    {
        var response = await _http.PostAsync("api/admin/reset-demo-data", null);
        response.EnsureSuccessStatusCode();
    }

    public async Task<List<TicketHistoryEntry>> GetHistoryAsync(int ticketId) =>
        await _http.GetFromJsonAsync<List<TicketHistoryEntry>>($"api/tickets/{ticketId}/history", JsonOptions) ?? new List<TicketHistoryEntry>();
}
