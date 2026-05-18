var builder = WebApplication.CreateBuilder(args);

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddHealthChecks();

var app = builder.Build();

var serviceName = "${{ values.name }}";

app.MapGet("/", () => new
{
    service = serviceName,
    status = "ok",
    timestamp = DateTime.UtcNow
});

app.MapHealthChecks("/healthz");

app.Run();
