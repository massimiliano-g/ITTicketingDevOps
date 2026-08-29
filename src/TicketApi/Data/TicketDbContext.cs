using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using TicketApi.Models;

namespace TicketApi.Data;

// IdentityDbContext<ApplicationUser> invece di DbContext: porta con sé le
// tabelle di ASP.NET Core Identity (utenti, ruoli, claim) nello stesso
// database dei ticket — un solo database da gestire/backuppare, invece di
// due store separati.
public class TicketDbContext : IdentityDbContext<ApplicationUser>
{
    public TicketDbContext(DbContextOptions<TicketDbContext> options) : base(options)
    {
    }

    public DbSet<Ticket> Tickets => Set<Ticket>();
    public DbSet<TicketComment> TicketComments => Set<TicketComment>();
    public DbSet<TicketHistoryEntry> TicketHistoryEntries => Set<TicketHistoryEntry>();
    public DbSet<TicketAttachment> TicketAttachments => Set<TicketAttachment>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder); // Necessario: configura le tabelle Identity.

        modelBuilder.Entity<Ticket>(entity =>
        {
            entity.Property(t => t.Type).HasConversion<string>().HasMaxLength(20);
            entity.Property(t => t.Status).HasConversion<string>().HasMaxLength(20);
            entity.Property(t => t.Priority).HasConversion<string>().HasMaxLength(20);

            entity.HasOne(t => t.Reporter)
                .WithMany()
                .HasForeignKey(t => t.ReporterId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(t => t.Assignee)
                .WithMany()
                .HasForeignKey(t => t.AssigneeId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasMany(t => t.Comments)
                .WithOne(c => c.Ticket)
                .HasForeignKey(c => c.TicketId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasMany(t => t.History)
                .WithOne(h => h.Ticket)
                .HasForeignKey(h => h.TicketId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasMany(t => t.Attachments)
                .WithOne(a => a.Ticket)
                .HasForeignKey(a => a.TicketId)
                .OnDelete(DeleteBehavior.Cascade);
        });
    }
}
