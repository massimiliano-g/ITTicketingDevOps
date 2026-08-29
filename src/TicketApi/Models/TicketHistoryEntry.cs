namespace TicketApi.Models;

// Audit trail: una riga per ogni campo cambiato, non un record cumulativo
// per modifica — così si può interrogare "tutte le modifiche allo Status"
// senza dover fare parsing di un blob di testo libero.
public class TicketHistoryEntry
{
    public int Id { get; set; }
    public int TicketId { get; set; }
    public Ticket? Ticket { get; set; }

    public string ChangedByUserId { get; set; } = string.Empty;
    public ApplicationUser? ChangedByUser { get; set; }

    public string FieldName { get; set; } = string.Empty;
    public string? OldValue { get; set; }
    public string? NewValue { get; set; }
    public DateTime ChangedAt { get; set; } = DateTime.UtcNow;
}
