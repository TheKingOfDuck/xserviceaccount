# XSA - Kubernetes ServiceAccount Token Extractor

A lightweight C utility for recursively scanning directories to find Kubernetes ServiceAccount tokens and extract their metadata.

## Features

- ✅ Recursively searches for files named `token` in specified directories
- ✅ Decodes JWT tokens and extracts ServiceAccount names from `kubernetes.io.serviceaccount.name`
- ✅ Environment variable configuration (XSAPATH, XSALOG)
- ✅ Automatic log output to file (default: x.log)
- ✅ Minimal dependencies (pure C with standard libraries)
- ✅ Auto-release on every push via GitHub Actions

## Quick Start

```bash
# Build locally
make

# Run with default path (logs to x.log)
sudo ./bin/xsa

# Run with custom path
./bin/xsa /custom/path/to/pods

# Use environment variables
export XSAPATH="/var/lib/kubelet/pods"
export XSALOG="/tmp/my-log.log"
./bin/xsa
```

## Download Pre-built Binaries

Pre-built binaries are automatically generated for every push:

**Latest Release:** [GitHub Releases](https://github.com/TheKingOfDuck/xserviceaccount/releases)
- `xsa-linux-amd64` - Linux x86_64 binary
- `xsa-linux-arm64` - Linux ARM64 binary
- `checksums.sha256` - SHA256 checksums

## Installation

### Option 1: Download Pre-built Binaries (Recommended)

1. Go to [GitHub Releases](https://github.com/TheKingOfDuck/xserviceaccount/releases)
2. Download the latest `xsa-linux-amd64` or `xsa-linux-arm64`
3. Make it executable: `chmod +x xsa-linux-amd64`

### Option 2: Build from Source

**Prerequisites:** GCC or Clang

```bash
# Clone and build
git clone https://github.com/TheKingOfDuck/xserviceaccount/xserviceaccount.git
cd xserviceaccount
make

# Output: bin/xsa
```

### Build Commands

```bash
# Build
make

# Clean
make clean

# Help
make help
```

## Usage

### Command Line

```bash
# Use default path (/var/lib/kubelet/pods) and log file (x.log)
sudo ./bin/xsa

# Specify custom path
./bin/xsa /custom/path/to/search

# Download and run pre-built binary
wget https://github.com/TheKingOfDuck/xserviceaccount/releases/latest/download/xsa-linux-amd64
chmod +x xsa-linux-amd64
sudo ./xsa-linux-amd64
```

### Environment Variables

**XSAPATH** - Override the search path
```bash
export XSAPATH="/custom/path/to/pods"
./bin/xsa
```

**XSALOG** - Override log file (default: x.log)
```bash
export XSALOG="/tmp/custom.log"
./bin/xsa
```

**Combined usage:**
```bash
export XSAPATH="/var/lib/kubelet/pods"
export XSALOG="/var/log/xsa.log"
./bin/xsa
```

### Priority Order

1. `XSAPATH` environment variable
2. Command line argument  
3. Default path (`/var/lib/kubelet/pods`)

**Log File:**
- Default: `x.log` (always enabled)
- Override with `XSALOG` environment variable

## Output Format

```
[?] searching for 'token' files in /var/lib/kubelet/pods
[+] serviceaccount: default
[+] content:
eyJhbGciOiJSUzI1NiIsImtpZCI6InNQVGpYSGY3T3B0T1VfbDdYbld5cmFCekVpWFpCdU9KRkNVMjVyYThwX00ifQ.eyJhdWQiOlsiaHR0cHM6Ly9rdWJlcm5ldGVzLmRlZmF1bHQuc3ZjLmNsdXN0ZXIubG9jYWwiXSwiZXhwIjoxNzk2OTY1MDYwLCJpYXQiOjE3NjU0MjkwNjAsImlzcyI6Imh0dHBzOi8va3ViZXJuZXRlcy5kZWZhdWx0LnN2Yy5jbHVzdGVyLmxvY2FsIiwia3ViZXJuZXRlcy5pbyI6eyJuYW1lc3BhY2UiOiJt
[+] serviceaccount: my-app
[+] content:
eyJhbGciOiJSUzI1NiIsImtpZCI6InNQVGpYSGY3T3B0T1VfbDdYbld5cmFCekVpWFpCdU9KRkNVMjVyYThwX00ifQ...
[+] done
```

### Output Indicators

- `[?]` - Information/status messages
- `[+]` - Success messages  
- `[-]` - Error messages

### Log Output

All console output is automatically saved to a log file:
- **Default**: `x.log` in current directory
- **Custom**: Set `XSALOG` environment variable
- **Format**: Same as console output with timestamps

## File Structure

```
xserviceaccount/
├── xsa.c                    # Main source code
├── Makefile                 # Simple build configuration  
├── README.md                # This file
├── .gitignore               # Git ignore rules
├── .github/workflows/       # GitHub Actions for auto-release
│   └── build.yml
├── bin/                     # Build output directory
│   └── xsa                  # Local binary (after make)
└── x.log                    # Default log file (after run)
```

## How It Works

1. **Directory Traversal**: Recursively scans the specified directory for files named `token`
2. **JWT Processing**: For each token file found:
   - Reads the JWT token content
   - Splits the JWT into header, payload, and signature
   - Base64 decodes the payload
3. **ServiceAccount Extraction**: Parses the decoded JSON payload to find:
   - `kubernetes.io.serviceaccount.name` field
4. **Output**: Displays the ServiceAccount name and original token content

## Auto-Release Process

Every push to the repository triggers automatic building and release:

1. **GitHub Actions** automatically compiles Linux binaries
2. **Creates timestamped release** with format: `build-YYYYMMDD-HHMMSS-<commit>`
3. **Uploads binaries** to GitHub Releases with checksums
4. **Available immediately** for download

## Security Considerations

- ⚠️  Requires appropriate file system permissions to access kubelet directories
- 🔒 Tokens are sensitive information - secure your log files appropriately
- 🛡️  This tool is designed for defensive security analysis and troubleshooting
- 📝 All output is logged to file by default - ensure proper log file permissions

## Troubleshooting

### Permission Denied
```bash
# Run with sudo for system directories  
sudo ./bin/xsa
```

### Log File Issues
```bash
# Check log file permissions
ls -la x.log

# Set custom log location
export XSALOG="/tmp/xsa.log"
./bin/xsa
```

### Build Issues
```bash
# Clean and rebuild
make clean && make

# Check compiler
gcc --version
```

## Contributing

1. Fork the repository
2. Make your changes  
3. Push to trigger automatic build and release
4. Submit a pull request

## License

This project is provided as-is for defensive security purposes.

## Support

- 🐛 **Issues**: GitHub Issues
- 📖 **Documentation**: This README
- 🚀 **Releases**: Automatic on every push