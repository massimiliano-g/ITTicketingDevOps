namespace TicketApi.Services;

// Un'astrazione, due implementazioni: in locale (Development) salva su
// disco, nessuna dipendenza da Azure per sviluppare/testare gli allegati;
// altrove usa Azure Blob Storage con Managed Identity — stesso pattern
// "passwordless" già usato per SQL. Il valore restituito da UploadAsync
// (blobName) è ciò che salviamo in TicketAttachment.BlobUrl: un
// riferimento opaco, non un URL pubblico diretto.
public interface IFileStorageService
{
    Task<string> UploadAsync(Stream content, string fileName, string contentType, CancellationToken ct = default);
    Task<Stream?> DownloadAsync(string blobName, CancellationToken ct = default);
    Task DeleteAsync(string blobName, CancellationToken ct = default);
}
