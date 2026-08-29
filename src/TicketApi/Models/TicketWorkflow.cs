namespace TicketApi.Models;

// Workflow FISSO (non un motore configurabile): per uno strumento didattico
// è più utile un processo chiaro e prevedibile da insegnare che un sistema
// generico — la stessa scelta già fatta per la migration EF Core
// automatica (semplicità over flessibilità, per questo progetto).
public static class TicketWorkflow
{
    private static readonly Dictionary<TicketStatus, TicketStatus[]> AllowedTransitions = new()
    {
        [TicketStatus.Open] = new[] { TicketStatus.InProgress },
        [TicketStatus.InProgress] = new[] { TicketStatus.Pending, TicketStatus.Resolved, TicketStatus.Open },
        [TicketStatus.Pending] = new[] { TicketStatus.InProgress },
        [TicketStatus.Resolved] = new[] { TicketStatus.Closed, TicketStatus.Open },
        [TicketStatus.Closed] = new[] { TicketStatus.Open },
    };

    public static bool CanTransition(TicketStatus from, TicketStatus to) =>
        from == to || (AllowedTransitions.TryGetValue(from, out var allowed) && allowed.Contains(to));

    public static IReadOnlyList<TicketStatus> GetAllowedNextStates(TicketStatus from) =>
        AllowedTransitions.TryGetValue(from, out var allowed) ? allowed : Array.Empty<TicketStatus>();
}

// Tempi di risposta/risoluzione target in base alla priorità — valori
// dimostrativi ragionevoli per un helpdesk didattico, non uno standard
// normativo. Facilmente regolabili in un secondo momento.
public static class SlaPolicy
{
    public static (TimeSpan Response, TimeSpan Resolution) GetTargets(TicketPriority priority) => priority switch
    {
        TicketPriority.Critical => (TimeSpan.FromHours(1), TimeSpan.FromHours(4)),
        TicketPriority.High => (TimeSpan.FromHours(2), TimeSpan.FromHours(8)),
        TicketPriority.Medium => (TimeSpan.FromHours(4), TimeSpan.FromHours(24)),
        TicketPriority.Low => (TimeSpan.FromHours(8), TimeSpan.FromHours(72)),
        _ => (TimeSpan.FromHours(4), TimeSpan.FromHours(24)),
    };
}
