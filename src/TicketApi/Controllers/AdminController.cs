using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using TicketApi.Data;
using TicketApi.Models;

namespace TicketApi.Controllers;

// Riservato agli Admin: pensato per l'uso didattico in aula, per far
// ripartire ogni classe/esercitazione da uno stato di dati prevedibile
// senza dover ricreare i ticket a mano.
[ApiController]
[Route("api/admin")]
[Authorize(Roles = Roles.Admin)]
public class AdminController : ControllerBase
{
    private readonly TicketDbContext _db;
    private readonly UserManager<ApplicationUser> _userManager;

    public AdminController(TicketDbContext db, UserManager<ApplicationUser> userManager)
    {
        _db = db;
        _userManager = userManager;
    }

    [HttpPost("reset-demo-data")]
    public async Task<IActionResult> ResetDemoData()
    {
        _db.Tickets.RemoveRange(_db.Tickets); // Cascade: rimuove anche commenti/cronologia/allegati collegati.
        await _db.SaveChangesAsync();

        var agent = await _userManager.FindByEmailAsync("agent@ticketsystem.local");
        var requester = await _userManager.FindByEmailAsync("requester@ticketsystem.local");

        if (agent is null || requester is null)
        {
            return Problem("Utenti demo non trovati — il seed di base non è stato eseguito correttamente.");
        }

        var samples = new (string Title, TicketType Type, TicketPriority Priority, TicketStatus Status)[]
        {
            ("Stampante ufficio non risponde", TicketType.Incident, TicketPriority.High, TicketStatus.Open),
            ("Richiesta accesso VPN", TicketType.ServiceRequest, TicketPriority.Medium, TicketStatus.InProgress),
            ("Server di posta lento", TicketType.Problem, TicketPriority.Critical, TicketStatus.Pending),
            ("Aggiornamento antivirus su tutti i PC", TicketType.Change, TicketPriority.Low, TicketStatus.Resolved),
            ("Nuovo monitor per postazione", TicketType.ServiceRequest, TicketPriority.Low, TicketStatus.Open),
        };

        foreach (var s in samples)
        {
            var (responseTarget, resolutionTarget) = SlaPolicy.GetTargets(s.Priority);
            var now = DateTime.UtcNow;

            _db.Tickets.Add(new Ticket
            {
                Title = s.Title,
                Type = s.Type,
                Priority = s.Priority,
                Status = s.Status,
                ReporterId = requester.Id,
                AssigneeId = s.Status == TicketStatus.Open ? null : agent.Id,
                CreatedAt = now,
                ResponseDueAt = now.Add(responseTarget),
                ResolutionDueAt = now.Add(resolutionTarget),
                ResolvedAt = s.Status == TicketStatus.Resolved ? now : null,
                FirstResponseAt = s.Status == TicketStatus.Open ? null : now,
            });
        }

        await _db.SaveChangesAsync();
        return NoContent();
    }
}
