namespace TicketWeb.Models;

// Copia del modello di TicketApi: due servizi indipendenti, ognuno con il
// proprio DTO — evita di introdurre una libreria condivisa solo per questo,
// che sarebbe complessità ingiustificata per due soli servizi.
public enum TicketStatus
{
    Open,
    InProgress,
    Resolved,
    Closed
}

public enum TicketPriority
{
    Low,
    Medium,
    High,
    Critical
}

public class Ticket
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public TicketStatus Status { get; set; } = TicketStatus.Open;
    public TicketPriority Priority { get; set; } = TicketPriority.Medium;
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}
