namespace TicketApi.Models;

public enum TicketType
{
    Incident,
    ServiceRequest,
    Problem,
    Change
}

public enum TicketStatus
{
    Open,
    InProgress,
    Pending,
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
    public TicketType Type { get; set; } = TicketType.Incident;
    public TicketStatus Status { get; set; } = TicketStatus.Open;
    public TicketPriority Priority { get; set; } = TicketPriority.Medium;

    public string ReporterId { get; set; } = string.Empty;
    public ApplicationUser? Reporter { get; set; }

    public string? AssigneeId { get; set; }
    public ApplicationUser? Assignee { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }
    public DateTime? ResolvedAt { get; set; }
    public DateTime? ClosedAt { get; set; }

    // SLA: calcolate alla creazione in base alla priorità (vedi SlaPolicy).
    public DateTime ResponseDueAt { get; set; }
    public DateTime ResolutionDueAt { get; set; }
    public DateTime? FirstResponseAt { get; set; }

    public List<TicketComment> Comments { get; set; } = new();
    public List<TicketHistoryEntry> History { get; set; } = new();
    public List<TicketAttachment> Attachments { get; set; } = new();
}
