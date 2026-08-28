using Microsoft.EntityFrameworkCore;
using TicketApi.Models;

namespace TicketApi.Data;

public class TicketDbContext : DbContext
{
    public TicketDbContext(DbContextOptions<TicketDbContext> options) : base(options)
    {
    }

    public DbSet<Ticket> Tickets => Set<Ticket>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // Enum salvati come stringa (es. "Open", non "0"): più leggibili
        // quando si ispeziona il database direttamente (SSMS/Azure Data Studio).
        modelBuilder.Entity<Ticket>()
            .Property(t => t.Status)
            .HasConversion<string>()
            .HasMaxLength(20);

        modelBuilder.Entity<Ticket>()
            .Property(t => t.Priority)
            .HasConversion<string>()
            .HasMaxLength(20);
    }
}
