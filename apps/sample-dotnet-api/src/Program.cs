using System.Reflection;
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.Extensions.Diagnostics.HealthChecks;

var builder = WebApplication.CreateBuilder(args);

// Application Insights — only wires up if the connection string is present
// (azd injects APPLICATIONINSIGHTS_CONNECTION_STRING via Container Apps env vars).
var appInsightsConn = builder.Configuration["APPLICATIONINSIGHTS_CONNECTION_STRING"]
                      ?? Environment.GetEnvironmentVariable("APPLICATIONINSIGHTS_CONNECTION_STRING");
if (!string.IsNullOrWhiteSpace(appInsightsConn))
{
    builder.Services.AddApplicationInsightsTelemetry(options =>
    {
        options.ConnectionString = appInsightsConn;
    });
}

// Key Vault — opt-in. We skip silently if AZURE_KEY_VAULT_URI is not set so the
// app still boots locally without an Azure identity.
var keyVaultUri = builder.Configuration["AZURE_KEY_VAULT_URI"]
                  ?? Environment.GetEnvironmentVariable("AZURE_KEY_VAULT_URI");
if (!string.IsNullOrWhiteSpace(keyVaultUri) && Uri.TryCreate(keyVaultUri, UriKind.Absolute, out var kvUri))
{
    try
    {
        var credential = new DefaultAzureCredential();
        builder.Configuration.AddAzureKeyVault(kvUri, credential);
        builder.Services.AddSingleton(_ => new SecretClient(kvUri, credential));
    }
    catch (Exception ex)
    {
        // Don't crash startup if the managed identity isn't ready yet — just log.
        Console.Error.WriteLine($"[startup] Key Vault wiring failed: {ex.Message}");
    }
}

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddHealthChecks()
    .AddCheck("self", () => HealthCheckResult.Healthy("ok"));

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

var version = Assembly.GetExecutingAssembly().GetName().Version?.ToString() ?? "1.0.0";

app.MapGet("/", () => Results.Ok(new
{
    service = "sample-dotnet-api",
    version,
    status = "running",
    timestamp = DateTimeOffset.UtcNow,
    environment = app.Environment.EnvironmentName
}));

app.MapGet("/health", () => Results.Ok(new { status = "healthy" }));

app.MapHealthChecks("/healthz");

app.MapGet("/api/info", () => Results.Ok(new
{
    region = Environment.GetEnvironmentVariable("REGION_NAME")
             ?? Environment.GetEnvironmentVariable("AZURE_REGION")
             ?? "unknown",
    instance = Environment.GetEnvironmentVariable("CONTAINER_APP_REVISION")
               ?? Environment.MachineName,
    dotnetVersion = Environment.Version.ToString()
}));

app.Run();

// Expose Program for WebApplicationFactory<Program> in the test project.
public partial class Program { }
