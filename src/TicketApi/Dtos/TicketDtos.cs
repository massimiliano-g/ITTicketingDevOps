using TicketApi.Models;

namespace TicketApi.Dtos;

// DTO sempre, mai le entità EF dirette in risposta: ApplicationUser contiene
// PasswordHash/SecurityStamp che non devono mai lasciare il server.
public record UserSummaryDto(string Id, string DisplayName, string Email);

public record UserDto(string Id, string DisplayName, string Email, IReadOnlyList<string> Roles);

public record TicketDto(
    int Id,
    string Title,
    string? Description,
    TicketType Type,
    TicketStatus Status,
    TicketPriority Priority,
    UserSummaryDto? Reporter,
    UserSummaryDto? Assignee,
    DateTime CreatedAt,
    DateTime? UpdatedAt,
    DateTime? ResolvedAt,
    DateTime? ClosedAt,
    DateTime ResponseDueAt,
    DateTime ResolutionDueAt,
    DateTime? FirstResponseAt,
    IReadOnlyList<TicketStatus> AllowedNextStates);

public record CreateTicketRequest(string Title, string? Description, TicketType Type, TicketPriority Priority);

public record UpdateTicketRequest(string Title, string? Description, TicketPriority Priority, string? AssigneeId);

public record TransitionTicketRequest(TicketStatus NewStatus);

public record CommentDto(int Id, UserSummaryDto Author, string Body, DateTime CreatedAt);

public record CreateCommentRequest(string Body);

public record HistoryEntryDto(string FieldName, string? OldValue, string? NewValue, UserSummaryDto? ChangedBy, DateTime ChangedAt);

public record AttachmentDto(int Id, string FileName, string ContentType, long SizeBytes, UserSummaryDto? UploadedBy, DateTime UploadedAt);

public record LoginRequest(string Email, string Password);

public record LoginResponse(string Token, DateTime ExpiresAt, UserDto User);
