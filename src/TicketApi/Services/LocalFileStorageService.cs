namespace TicketApi.Services;

public class LocalFileStorageService : IFileStorageService
{
    private readonly string _rootPath;

    public LocalFileStorageService(IWebHostEnvironment env)
    {
        _rootPath = Path.Combine(env.ContentRootPath, "App_Data", "uploads");
        Directory.CreateDirectory(_rootPath);
    }

    public async Task<string> UploadAsync(Stream content, string fileName, string contentType, CancellationToken ct = default)
    {
        var storedName = $"{Guid.NewGuid():N}_{Path.GetFileName(fileName)}";
        var path = Path.Combine(_rootPath, storedName);

        await using var fileStream = File.Create(path);
        await content.CopyToAsync(fileStream, ct);

        return storedName;
    }

    public Task<Stream?> DownloadAsync(string blobName, CancellationToken ct = default)
    {
        var path = Path.Combine(_rootPath, blobName);
        Stream? stream = File.Exists(path) ? File.OpenRead(path) : null;
        return Task.FromResult(stream);
    }

    public Task DeleteAsync(string blobName, CancellationToken ct = default)
    {
        var path = Path.Combine(_rootPath, blobName);
        if (File.Exists(path))
        {
            File.Delete(path);
        }

        return Task.CompletedTask;
    }
}
