using Azure.Identity;
using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;

namespace TicketApi.Services;

// DefaultAzureCredential: in Container Apps risolve automaticamente alla
// Managed Identity assegnata (stesso identity_id usato per ACR/SQL), niente
// connection string con chiave. Il container Blob viene creato dal
// Terraform del progetto (infra/modules/storage-account).
public class AzureBlobFileStorageService : IFileStorageService
{
    private readonly BlobContainerClient _container;

    public AzureBlobFileStorageService(IConfiguration configuration)
    {
        var containerUri = configuration["Storage:ContainerUri"]
            ?? throw new InvalidOperationException("Configurazione mancante: Storage:ContainerUri");

        _container = new BlobContainerClient(new Uri(containerUri), new DefaultAzureCredential());
    }

    public async Task<string> UploadAsync(Stream content, string fileName, string contentType, CancellationToken ct = default)
    {
        var blobName = $"{Guid.NewGuid():N}_{fileName}";
        var blobClient = _container.GetBlobClient(blobName);

        await blobClient.UploadAsync(
            content,
            new BlobHttpHeaders { ContentType = contentType },
            cancellationToken: ct);

        return blobName;
    }

    public async Task<Stream?> DownloadAsync(string blobName, CancellationToken ct = default)
    {
        var blobClient = _container.GetBlobClient(blobName);
        if (!await blobClient.ExistsAsync(ct))
        {
            return null;
        }

        var response = await blobClient.DownloadStreamingAsync(cancellationToken: ct);
        return response.Value.Content;
    }

    public async Task DeleteAsync(string blobName, CancellationToken ct = default)
    {
        await _container.GetBlobClient(blobName).DeleteIfExistsAsync(cancellationToken: ct);
    }
}
