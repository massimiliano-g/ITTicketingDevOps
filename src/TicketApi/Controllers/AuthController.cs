using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using TicketApi.Dtos;
using TicketApi.Models;
using TicketApi.Services;

namespace TicketApi.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController : ControllerBase
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly JwtTokenService _jwtTokenService;

    public AuthController(UserManager<ApplicationUser> userManager, JwtTokenService jwtTokenService)
    {
        _userManager = userManager;
        _jwtTokenService = jwtTokenService;
    }

    [HttpPost("login")]
    [AllowAnonymous]
    public async Task<ActionResult<LoginResponse>> Login(LoginRequest request)
    {
        var user = await _userManager.FindByEmailAsync(request.Email);
        if (user is null || !await _userManager.CheckPasswordAsync(user, request.Password))
        {
            return Unauthorized(new { message = "Email o password non validi." });
        }

        var roles = await _userManager.GetRolesAsync(user);
        var (token, expiresAt) = _jwtTokenService.CreateToken(user, roles);

        return new LoginResponse(token, expiresAt, new UserDto(user.Id, user.DisplayName, user.Email!, roles.ToList()));
    }

    // Creazione utenti riservata agli Admin — non c'è auto-registrazione
    // pubblica: in un helpdesk aziendale gli account li crea chi amministra
    // il sistema, non chi vuole accedervi.
    [HttpPost("users")]
    [Authorize(Roles = Roles.Admin)]
    public async Task<ActionResult<UserDto>> CreateUser(CreateUserRequest request)
    {
        var user = new ApplicationUser
        {
            UserName = request.Email,
            Email = request.Email,
            DisplayName = request.DisplayName,
            EmailConfirmed = true,
        };

        var result = await _userManager.CreateAsync(user, request.Password);
        if (!result.Succeeded)
        {
            return BadRequest(result.Errors.Select(e => e.Description));
        }

        await _userManager.AddToRoleAsync(user, request.Role);

        return new UserDto(user.Id, user.DisplayName, user.Email!, new List<string> { request.Role });
    }
}

public record CreateUserRequest(string Email, string Password, string DisplayName, string Role);
