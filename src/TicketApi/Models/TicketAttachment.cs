namespace TicketApi.Models;

// Il contenuto del file vive su Azure Blob Storage (fase 3) — qui salviamo
// solo i metadati e l'URL del blob, mai il file stesso nel database.
public class TicketAttachment
{
    public int Id { get; set; }
    public int TicketId { get; set; }
    public Ticket? Ticket { get; set; }

    public string FileName { get; set; } = string.Empty;
    public string BlobUrl { get; set; } = string.Empty;
    public string ContentType { get; set; } = string.Empty;
    public long SizeBytes { get; set; }

    public string UploadedByUserId { get; set; } = string.Empty;
    public ApplicationUser? UploadedByUser { get; set; }
    public DateTime UploadedAt { get; set; } = DateTime.UtcNow;
}
