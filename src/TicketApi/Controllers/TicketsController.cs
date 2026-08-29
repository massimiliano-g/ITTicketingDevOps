using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TicketApi.Data;
using TicketApi.Dtos;
using TicketApi.Models;
using TicketApi.Services;

namespace TicketApi.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class TicketsController : ControllerBase
{
    private readonly TicketDbContext _db;
    private readonly IFileStorageService _fileStorage;

    public TicketsController(TicketDbContext db, IFileStorageService fileStorage)
    {
        _db = db;
        _fileStorage = fileStorage;
    }

    private string CurrentUserId => User.FindFirstValue(JwtRegisteredClaimNames.Sub)!;
    private bool IsAgentOrAdmin => User.IsInRole(Roles.Agent) || User.IsInRole(Roles.Admin);

    [HttpGet]
    public async Task<ActionResult<IEnumerable<TicketDto>>> GetAll([FromQuery] TicketStatus? status, [FromQuery] string? assigneeId)
    {
        var query = _db.Tickets
            .Include(t => t.Reporter)
            .Include(t => t.Assignee)
            .AsQueryable();

        // Un Requester vede solo i propri ticket — un Agent/Admin vede tutto.
        // Stessa distinzione che un vero helpdesk applica: un utente finale
        // non deve poter sfogliare i ticket di qualcun altro.
        if (!IsAgentOrAdmin)
        {
            query = query.Where(t => t.ReporterId == CurrentUserId);
        }

        if (status is not null)
        {
            query = query.Where(t => t.Status == status);
        }

        if (!string.IsNullOrEmpty(assigneeId))
        {
            query = query.Where(t => t.AssigneeId == assigneeId);
        }

        var tickets = await query.OrderByDescending(t => t.CreatedAt).ToListAsync();
        return tickets.Select(ToDto).ToList();
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<TicketDto>> GetById(int id)
    {
        var ticket = await _db.Tickets
            .Include(t => t.Reporter)
            .Include(t => t.Assignee)
            .FirstOrDefaultAsync(t => t.Id == id);

        if (ticket is null)
        {
            return NotFound();
        }

        if (!IsAgentOrAdmin && ticket.ReporterId != CurrentUserId)
        {
            return Forbid();
        }

        return ToDto(ticket);
    }

    [HttpPost]
    public async Task<ActionResult<TicketDto>> Create(CreateTicketRequest request)
    {
        var (responseTarget, resolutionTarget) = SlaPolicy.GetTargets(request.Priority);
        var now = DateTime.UtcNow;

        var ticket = new Ticket
        {
            Title = request.Title,
            Description = request.Description,
            Type = request.Type,
            Priority = request.Priority,
            Status = TicketStatus.Open,
            ReporterId = CurrentUserId,
            CreatedAt = now,
            ResponseDueAt = now.Add(responseTarget),
            ResolutionDueAt = now.Add(resolutionTarget),
        };

        _db.Tickets.Add(ticket);
        await _db.SaveChangesAsync();

        await _db.Entry(ticket).Reference(t => t.Reporter).LoadAsync();

        return CreatedAtAction(nameof(GetById), new { id = ticket.Id }, ToDto(ticket));
    }

    [HttpPut("{id:int}")]
    [Authorize(Roles = Roles.Agent + "," + Roles.Admin)]
    public async Task<IActionResult> Update(int id, UpdateTicketRequest request)
    {
        var ticket = await _db.Tickets.FindAsync(id);
        if (ticket is null)
        {
            return NotFound();
        }

        await LogChangeAsync(ticket.Id, "Title", ticket.Title, request.Title);
        await LogChangeAsync(ticket.Id, "Priority", ticket.Priority.ToString(), request.Priority.ToString());
        await LogChangeAsync(ticket.Id, "AssigneeId", ticket.AssigneeId, request.AssigneeId);

        ticket.Title = request.Title;
        ticket.Description = request.Description;
        ticket.Priority = request.Priority;
        ticket.AssigneeId = request.AssigneeId;
        ticket.UpdatedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync();
        return NoContent();
    }

    [HttpPost("{id:int}/transition")]
    [Authorize(Roles = Roles.Agent + "," + Roles.Admin)]
    public async Task<ActionResult<TicketDto>> Transition(int id, TransitionTicketRequest request)
    {
        var ticket = await _db.Tickets
            .Include(t => t.Reporter)
            .Include(t => t.Assignee)
            .FirstOrDefaultAsync(t => t.Id == id);

        if (ticket is null)
        {
            return NotFound();
        }

        if (!TicketWorkflow.CanTransition(ticket.Status, request.NewStatus))
        {
            return BadRequest(new
            {
                message = $"Transizione non valida: {ticket.Status} -> {request.NewStatus}.",
                allowedNextStates = TicketWorkflow.GetAllowedNextStates(ticket.Status),
            });
        }

        await LogChangeAsync(ticket.Id, "Status", ticket.Status.ToString(), request.NewStatus.ToString());

        var now = DateTime.UtcNow;
        ticket.FirstResponseAt ??= now; // La prima transizione conta come prima risposta, ai fini SLA.
        ticket.Status = request.NewStatus;
        ticket.UpdatedAt = now;

        if (request.NewStatus == TicketStatus.Resolved)
        {
            ticket.ResolvedAt = now;
        }
        else if (request.NewStatus == TicketStatus.Closed)
        {
            ticket.ClosedAt = now;
        }
        else if (request.NewStatus == TicketStatus.Open)
        {
            // Riapertura: azzera i timestamp di chiusura, il ticket torna "attivo".
            ticket.ResolvedAt = null;
            ticket.ClosedAt = null;
        }

        await _db.SaveChangesAsync();
        return ToDto(ticket);
    }

    [HttpDelete("{id:int}")]
    [Authorize(Roles = Roles.Admin)]
    public async Task<IActionResult> Delete(int id)
    {
        var ticket = await _db.Tickets.FindAsync(id);
        if (ticket is null)
        {
            return NotFound();
        }

        _db.Tickets.Remove(ticket);
        await _db.SaveChangesAsync();
        return NoContent();
    }

    [HttpGet("{id:int}/comments")]
    public async Task<ActionResult<IEnumerable<CommentDto>>> GetComments(int id)
    {
        var ticket = await _db.Tickets.FindAsync(id);
        if (ticket is null)
        {
            return NotFound();
        }

        if (!IsAgentOrAdmin && ticket.ReporterId != CurrentUserId)
        {
            return Forbid();
        }

        var comments = await _db.TicketComments
            .Include(c => c.Author)
            .Where(c => c.TicketId == id)
            .OrderBy(c => c.CreatedAt)
            .ToListAsync();

        return comments.Select(c => new CommentDto(
            c.Id,
            new UserSummaryDto(c.Author!.Id, c.Author.DisplayName, c.Author.Email!),
            c.Body,
            c.CreatedAt)).ToList();
    }

    [HttpPost("{id:int}/comments")]
    public async Task<ActionResult<CommentDto>> AddComment(int id, CreateCommentRequest request)
    {
        var ticket = await _db.Tickets.FindAsync(id);
        if (ticket is null)
        {
            return NotFound();
        }

        if (!IsAgentOrAdmin && ticket.ReporterId != CurrentUserId)
        {
            return Forbid();
        }

        var comment = new TicketComment
        {
            TicketId = id,
            AuthorId = CurrentUserId,
            Body = request.Body,
            CreatedAt = DateTime.UtcNow,
        };

        _db.TicketComments.Add(comment);
        await _db.SaveChangesAsync();
        await _db.Entry(comment).Reference(c => c.Author).LoadAsync();

        return new CommentDto(
            comment.Id,
            new UserSummaryDto(comment.Author!.Id, comment.Author.DisplayName, comment.Author.Email!),
            comment.Body,
            comment.CreatedAt);
    }

    [HttpGet("{id:int}/history")]
    [Authorize(Roles = Roles.Agent + "," + Roles.Admin)]
    public async Task<ActionResult<IEnumerable<HistoryEntryDto>>> GetHistory(int id)
    {
        var entries = await _db.TicketHistoryEntries
            .Include(h => h.ChangedByUser)
            .Where(h => h.TicketId == id)
            .OrderByDescending(h => h.ChangedAt)
            .ToListAsync();

        return entries.Select(h => new HistoryEntryDto(
            h.FieldName,
            h.OldValue,
            h.NewValue,
            h.ChangedByUser is null ? null : new UserSummaryDto(h.ChangedByUser.Id, h.ChangedByUser.DisplayName, h.ChangedByUser.Email!),
            h.ChangedAt)).ToList();
    }

    [HttpGet("{id:int}/attachments")]
    public async Task<ActionResult<IEnumerable<AttachmentDto>>> GetAttachments(int id)
    {
        var ticket = await _db.Tickets.FindAsync(id);
        if (ticket is null)
        {
            return NotFound();
        }

        if (!IsAgentOrAdmin && ticket.ReporterId != CurrentUserId)
        {
            return Forbid();
        }

        var attachments = await _db.TicketAttachments
            .Include(a => a.UploadedByUser)
            .Where(a => a.TicketId == id)
            .OrderByDescending(a => a.UploadedAt)
            .ToListAsync();

        return attachments.Select(ToAttachmentDto).ToList();
    }

    // 10 MB: limite ragionevole per screenshot/log di un helpdesk didattico,
    // non pensato per file di grandi dimensioni.
    [HttpPost("{id:int}/attachments")]
    [RequestSizeLimit(10 * 1024 * 1024)]
    public async Task<ActionResult<AttachmentDto>> UploadAttachment(int id, IFormFile file)
    {
        var ticket = await _db.Tickets.FindAsync(id);
        if (ticket is null)
        {
            return NotFound();
        }

        if (!IsAgentOrAdmin && ticket.ReporterId != CurrentUserId)
        {
            return Forbid();
        }

        if (file.Length == 0)
        {
            return BadRequest(new { message = "File vuoto." });
        }

        await using var stream = file.OpenReadStream();
        var blobName = await _fileStorage.UploadAsync(stream, file.FileName, file.ContentType);

        var attachment = new TicketAttachment
        {
            TicketId = id,
            FileName = file.FileName,
            BlobUrl = blobName,
            ContentType = string.IsNullOrEmpty(file.ContentType) ? "application/octet-stream" : file.ContentType,
            SizeBytes = file.Length,
            UploadedByUserId = CurrentUserId,
            UploadedAt = DateTime.UtcNow,
        };

        _db.TicketAttachments.Add(attachment);
        await _db.SaveChangesAsync();
        await _db.Entry(attachment).Reference(a => a.UploadedByUser).LoadAsync();

        return ToAttachmentDto(attachment);
    }

    [HttpGet("{id:int}/attachments/{attachmentId:int}")]
    public async Task<IActionResult> DownloadAttachment(int id, int attachmentId)
    {
        var ticket = await _db.Tickets.FindAsync(id);
        if (ticket is null)
        {
            return NotFound();
        }

        if (!IsAgentOrAdmin && ticket.ReporterId != CurrentUserId)
        {
            return Forbid();
        }

        var attachment = await _db.TicketAttachments.FirstOrDefaultAsync(a => a.Id == attachmentId && a.TicketId == id);
        if (attachment is null)
        {
            return NotFound();
        }

        var stream = await _fileStorage.DownloadAsync(attachment.BlobUrl);
        if (stream is null)
        {
            return NotFound();
        }

        return File(stream, attachment.ContentType, attachment.FileName);
    }

    private static AttachmentDto ToAttachmentDto(TicketAttachment a) => new(
        a.Id,
        a.FileName,
        a.ContentType,
        a.SizeBytes,
        a.UploadedByUser is null ? null : new UserSummaryDto(a.UploadedByUser.Id, a.UploadedByUser.DisplayName, a.UploadedByUser.Email!),
        a.UploadedAt);

    private async Task LogChangeAsync(int ticketId, string fieldName, string? oldValue, string? newValue)
    {
        if (oldValue == newValue)
        {
            return;
        }

        _db.TicketHistoryEntries.Add(new TicketHistoryEntry
        {
            TicketId = ticketId,
            ChangedByUserId = CurrentUserId,
            FieldName = fieldName,
            OldValue = oldValue,
            NewValue = newValue,
            ChangedAt = DateTime.UtcNow,
        });
        await Task.CompletedTask;
    }

    private static TicketDto ToDto(Ticket t) => new(
        t.Id,
        t.Title,
        t.Description,
        t.Type,
        t.Status,
        t.Priority,
        t.Reporter is null ? null : new UserSummaryDto(t.Reporter.Id, t.Reporter.DisplayName, t.Reporter.Email!),
        t.Assignee is null ? null : new UserSummaryDto(t.Assignee.Id, t.Assignee.DisplayName, t.Assignee.Email!),
        t.CreatedAt,
        t.UpdatedAt,
        t.ResolvedAt,
        t.ClosedAt,
        t.ResponseDueAt,
        t.ResolutionDueAt,
        t.FirstResponseAt,
        TicketWorkflow.GetAllowedNextStates(t.Status).ToList());
}
