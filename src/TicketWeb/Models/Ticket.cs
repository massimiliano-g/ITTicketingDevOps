namespace TicketWeb.Models;

// DTO che rispecchiano quelli esposti da ticket-api — ticket-web non ha mai
// accesso diretto al database, solo a quello che l'API decide di esporre.
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

public class UserSummary
{
    public string Id { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
}

public class Ticket
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public TicketType Type { get; set; }
    public TicketStatus Status { get; set; }
    public TicketPriority Priority { get; set; }
    public UserSummary? Reporter { get; set; }
    public UserSummary? Assignee { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public DateTime? ResolvedAt { get; set; }
    public DateTime? ClosedAt { get; set; }
    public DateTime ResponseDueAt { get; set; }
    public DateTime ResolutionDueAt { get; set; }
    public DateTime? FirstResponseAt { get; set; }
    public List<TicketStatus> AllowedNextStates { get; set; } = new();
}

public class TicketComment
{
    public int Id { get; set; }
    public UserSummary Author { get; set; } = new();
    public string Body { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}

public class Attachment
{
    public int Id { get; set; }
    public string FileName { get; set; } = string.Empty;
    public string ContentType { get; set; } = string.Empty;
    public long SizeBytes { get; set; }
    public UserSummary? UploadedBy { get; set; }
    public DateTime UploadedAt { get; set; }
}

public class TicketHistoryEntry
{
    public string FieldName { get; set; } = string.Empty;
    public string? OldValue { get; set; }
    public string? NewValue { get; set; }
    public UserSummary? ChangedBy { get; set; }
    public DateTime ChangedAt { get; set; }
}
