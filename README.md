# XSA - Kubernetes ServiceAccount Token Extractor

A lightweight C utility for recursively scanning directories to find Kubernetes ServiceAccount tokens and extract their metadata.

## Features

- Recursively searches for files named `token` in specified directories
- Decodes JWT tokens and extracts ServiceAccount names from `kubernetes.io.serviceaccount.name`
- Cross-platform compilation support (macOS ARM64, Linux AMD64, Linux ARM64)
- Environment variable configuration
- Optional log file output
- Minimal dependencies (pure C with standard libraries)

## Quick Start

```bash
# Build all targets
make

# Run with default path
sudo ./xsa-darwin-arm64

# Run with custom path
./xsa-darwin-arm64 /custom/path/to/pods
```

## Installation

### Prerequisites

For cross-compilation, install the required toolchains:

**macOS:**
```bash
xcode-select --install
```

**Linux (Ubuntu/Debian):**
```bash
apt-get install gcc-x86-64-linux-gnu gcc-aarch64-linux-gnu
```

**macOS with Homebrew:**
```bash
brew install x86_64-linux-gnu-gcc aarch64-linux-gnu-gcc
```

### Build

```bash
# Build all targets
make

# Build specific target
make xsa-darwin-arm64

# Clean build artifacts
make clean

# Show help
make help
```

## Usage

### Command Line

```bash
# Use default path (/var/lib/kubelet/pods)
sudo ./xsa-darwin-arm64

# Specify custom path
./xsa-darwin-arm64 /path/to/search

# View help
make help
```

### Environment Variables

**XSAPATH** - Override the search path
```bash
export XSAPATH="/custom/path/to/pods"
./xsa-darwin-arm64
```

**XSALOG** - Enable logging to file
```bash
export XSALOG="/tmp/xsa.log"
./xsa-darwin-arm64
```

**Combined usage:**
```bash
export XSAPATH="/var/lib/kubelet/pods"
export XSALOG="/var/log/xsa.log"
./xsa-darwin-arm64
```

### Priority Order

1. `XSAPATH` environment variable
2. Command line argument
3. Default path (`/var/lib/kubelet/pods`)

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

## File Structure

```
xserviceaccount/
├── xsa.c                 # Main source code
├── Makefile             # Build configuration
├── README.md            # This file
├── .gitignore          # Git ignore rules
├── xsa-darwin-arm64    # macOS ARM64 binary (after build)
├── xsa-linux-amd64     # Linux AMD64 binary (after build)
└── xsa-linux-arm64     # Linux ARM64 binary (after build)
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

## Security Considerations

- Requires appropriate file system permissions to access kubelet directories
- Tokens are sensitive information - use appropriate log file permissions when using `XSALOG`
- This tool is designed for defensive security analysis and troubleshooting

## Troubleshooting

### Permission Denied
```bash
# Run with sudo for system directories
sudo ./xsa-darwin-arm64
```

### Cross-compilation Errors
```bash
# Install missing toolchains
make install-deps
```

### Log File Issues
```bash
# Ensure log directory exists and is writable
mkdir -p /var/log
chmod 755 /var/log
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on multiple platforms
5. Submit a pull request

## License

This project is provided as-is for defensive security purposes.

## Support

For issues and feature requests, please check the source code documentation and ensure you have the required build dependencies installed.