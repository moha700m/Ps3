param(
	[Parameter(Mandatory = $true)]
	[string]$Executable,
	[Parameter(Mandatory = $true)]
	[string]$OutputDirectory
)

$ErrorActionPreference = 'Stop'
$screenshotPath = Join-Path $OutputDirectory 'first-run.png'
$metadataPath = Join-Path $OutputDirectory 'first-run.txt'
$appDataRoot = Join-Path $env:RUNNER_TEMP 'mohammedlab-first-run'
$captured = $false
$reason = 'Screenshot capture did not complete.'
$process = $null

function Set-CaptureOutput([bool]$Value) {
	if ($env:GITHUB_OUTPUT) {
		Add-Content -Path $env:GITHUB_OUTPUT -Value "captured=$($Value.ToString().ToLowerInvariant())" -Encoding utf8
	}
}

function Add-StepSummary([string]$Message) {
	if ($env:GITHUB_STEP_SUMMARY) {
		Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value $Message -Encoding utf8
	}
}

$nativeWindowSource = @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;

public static class FirstRunWindow
{
	public sealed class WindowInfo
	{
		public IntPtr Handle { get; set; }
		public string Title { get; set; }
		public int Left { get; set; }
		public int Top { get; set; }
		public int Width { get; set; }
		public int Height { get; set; }
		public long Area { get { return (long)Width * Height; } }
	}

	private delegate bool EnumWindowsCallback(IntPtr handle, IntPtr parameter);

	[StructLayout(LayoutKind.Sequential)]
	private struct Rectangle
	{
		public int Left;
		public int Top;
		public int Right;
		public int Bottom;
	}

	[DllImport("user32.dll")]
	private static extern bool EnumWindows(EnumWindowsCallback callback, IntPtr parameter);

	[DllImport("user32.dll")]
	private static extern bool IsWindowVisible(IntPtr handle);

	[DllImport("user32.dll")]
	private static extern uint GetWindowThreadProcessId(IntPtr handle, out uint processId);

	[DllImport("user32.dll", CharSet = CharSet.Unicode)]
	private static extern int GetWindowText(IntPtr handle, StringBuilder text, int maximumLength);

	[DllImport("user32.dll")]
	private static extern bool GetWindowRect(IntPtr handle, out Rectangle rectangle);

	[DllImport("user32.dll")]
	public static extern bool SetForegroundWindow(IntPtr handle);

	[DllImport("user32.dll")]
	public static extern bool ShowWindow(IntPtr handle, int command);

	public static WindowInfo[] FindForProcess(int targetProcessId)
	{
		var windows = new List<WindowInfo>();
		EnumWindows(delegate(IntPtr handle, IntPtr parameter)
		{
			uint processId;
			GetWindowThreadProcessId(handle, out processId);
			if (processId != targetProcessId || !IsWindowVisible(handle))
			{
				return true;
			}

			Rectangle rectangle;
			if (!GetWindowRect(handle, out rectangle))
			{
				return true;
			}

			int width = rectangle.Right - rectangle.Left;
			int height = rectangle.Bottom - rectangle.Top;
			if (width <= 100 || height <= 100)
			{
				return true;
			}

			var title = new StringBuilder(512);
			GetWindowText(handle, title, title.Capacity);
			windows.Add(new WindowInfo
			{
				Handle = handle,
				Title = title.ToString(),
				Left = rectangle.Left,
				Top = rectangle.Top,
				Width = width,
				Height = height
			});
			return true;
		}, IntPtr.Zero);

		return windows.ToArray();
	}
}
'@

try {
	if (-not (Test-Path -LiteralPath $Executable -PathType Leaf)) {
		throw "Built executable not found: $Executable"
	}

	Remove-Item -LiteralPath $appDataRoot -Recurse -Force -ErrorAction SilentlyContinue
	$null = New-Item -ItemType Directory -Path $OutputDirectory -Force
	$null = New-Item -ItemType Directory -Path (Join-Path $appDataRoot 'Roaming') -Force
	$null = New-Item -ItemType Directory -Path (Join-Path $appDataRoot 'Local') -Force

	Add-Type -TypeDefinition $nativeWindowSource
	Add-Type -AssemblyName System.Drawing

	$env:APPDATA = Join-Path $appDataRoot 'Roaming'
	$env:LOCALAPPDATA = Join-Path $appDataRoot 'Local'
	$process = Start-Process -FilePath (Resolve-Path -LiteralPath $Executable).Path `
		-WorkingDirectory (Split-Path -Parent (Resolve-Path -LiteralPath $Executable).Path) `
		-PassThru

	$deadline = [DateTime]::UtcNow.AddSeconds(90)
	$window = $null
	while ([DateTime]::UtcNow -lt $deadline) {
		$process.Refresh()
		if ($process.HasExited) {
			throw "Built GUI process exited before showing its first-run window (exit code $($process.ExitCode))."
		}

		$window = [FirstRunWindow]::FindForProcess($process.Id) |
			Where-Object { $_.Title -eq 'Welcome to RPCS3' } |
			Sort-Object -Property Area -Descending |
			Select-Object -First 1
		if ($window) {
			break
		}
		Start-Sleep -Seconds 1
	}

	if (-not $window) {
		throw 'The built process did not show its expected first-run welcome window within 90 seconds; this Windows runner may not provide an interactive desktop.'
	}

	[void][FirstRunWindow]::ShowWindow($window.Handle, 9)
	[void][FirstRunWindow]::SetForegroundWindow($window.Handle)
	Start-Sleep -Seconds 2

	$bitmap = [System.Drawing.Bitmap]::new($window.Width, $window.Height)
	try {
		$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
		try {
			$graphics.CopyFromScreen(
				$window.Left,
				$window.Top,
				0,
				0,
				$bitmap.Size,
				[System.Drawing.CopyPixelOperation]::SourceCopy
			)
		}
		finally {
			$graphics.Dispose()
		}

		$sampledColors = [System.Collections.Generic.HashSet[int]]::new()
		for ($x = 0; $x -lt $bitmap.Width; $x += [Math]::Max(1, [int]($bitmap.Width / 20))) {
			for ($y = 0; $y -lt $bitmap.Height; $y += [Math]::Max(1, [int]($bitmap.Height / 20))) {
				$sampledColors.Add($bitmap.GetPixel($x, $y).ToArgb()) | Out-Null
			}
		}
		if ($sampledColors.Count -lt 5) {
			throw 'Window capture was blank or unavailable on the runner desktop; no screenshot artifact will be published.'
		}

		$bitmap.Save($screenshotPath, [System.Drawing.Imaging.ImageFormat]::Png)
	}
	finally {
		$bitmap.Dispose()
	}

	@(
		'Capture: actual built RPCS3-derived executable first-run window'
		"Commit: $env:GITHUB_SHA"
		"Workflow run: $env:GITHUB_SERVER_URL/$env:GITHUB_REPOSITORY/actions/runs/$env:GITHUB_RUN_ID"
		"Window title: $($window.Title)"
		"Captured UTC: $([DateTime]::UtcNow.ToString('o'))"
		'Firmware, games, and controller devices: not supplied for this capture'
	) | Set-Content -LiteralPath $metadataPath -Encoding utf8

	$captured = $true
	$reason = "Captured the visible application window '$($window.Title)' from the built executable."
}
catch {
	$reason = $_.Exception.Message
	Write-Warning "First-run screenshot was not captured: $reason"
}
finally {
	if ($process -and -not $process.HasExited) {
		Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
	}
	Set-CaptureOutput $captured
	Add-StepSummary "### First-run GUI screenshot`n`n$reason`n"
}
