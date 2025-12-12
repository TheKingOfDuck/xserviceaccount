CC = gcc
CFLAGS = -Wall -O2
CLANG_CFLAGS = -Wall -O2
SOURCE = xsa.c
BINDIR = bin
TARGETS = $(BINDIR)/xsa-darwin-arm64 $(BINDIR)/xsa-linux-amd64 $(BINDIR)/xsa-linux-arm64

# Check for cross-compilation tools (multiple naming conventions)
X86_64_GCC := $(shell which x86_64-linux-gnu-gcc 2>/dev/null || which x86_64-unknown-linux-gnu-gcc 2>/dev/null || which x86_64-pc-linux-gnu-gcc 2>/dev/null)
AARCH64_GCC := $(shell which aarch64-linux-gnu-gcc 2>/dev/null || which aarch64-unknown-linux-gnu-gcc 2>/dev/null || which aarch64-linux-musl-gcc 2>/dev/null)

# Check for LLVM/Clang
CLANG := $(shell which clang 2>/dev/null)

# Check for crosstool-ng installations in common locations
CROSSTOOL_X86_64 := $(shell find ~/x-tools -name "*x86_64*linux*gcc" 2>/dev/null | head -1)
CROSSTOOL_AARCH64 := $(shell find ~/x-tools -name "*aarch64*linux*gcc" 2>/dev/null | head -1)

# Determine the best cross-compilation method
# Priority: 1. Native GCC, 2. Crosstool-ng GCC, 3. Clang
ifeq ($(X86_64_GCC),)
  ifneq ($(CROSSTOOL_X86_64),)
    X86_64_GCC := $(CROSSTOOL_X86_64)
  else ifneq ($(CLANG),)
    X86_64_GCC := $(CLANG) --target=x86_64-linux-gnu
  endif
endif

ifeq ($(AARCH64_GCC),)
  ifneq ($(CROSSTOOL_AARCH64),)
    AARCH64_GCC := $(CROSSTOOL_AARCH64)
  else ifneq ($(CLANG),)
    AARCH64_GCC := $(CLANG) --target=aarch64-linux-gnu
  endif
endif

.PHONY: all clean native install-deps help check-tools setup-clang-sysroot

all: $(BINDIR) native
	@if [ -n "$(X86_64_GCC)" ]; then \
		echo "Building Linux AMD64..."; \
		$(MAKE) $(BINDIR)/xsa-linux-amd64 || echo "⚠️  Linux AMD64 build failed"; \
	else \
		echo "Warning: x86_64 cross-compiler not found, skipping Linux AMD64 build"; \
	fi
	@if [ -n "$(AARCH64_GCC)" ]; then \
		echo "Building Linux ARM64..."; \
		$(MAKE) $(BINDIR)/xsa-linux-arm64 || echo "⚠️  Linux ARM64 build failed"; \
	else \
		echo "Warning: aarch64 cross-compiler not found, skipping Linux ARM64 build"; \
	fi
	@echo ""
	@echo "Build summary:"
	@ls -la $(BINDIR)/ 2>/dev/null || echo "No binaries found in $(BINDIR)/"

native: $(BINDIR)/xsa-darwin-arm64

$(BINDIR):
	mkdir -p $(BINDIR)

$(BINDIR)/xsa-darwin-arm64: $(SOURCE) | $(BINDIR)
	$(CC) $(CFLAGS) -o $@ $<

$(BINDIR)/xsa-linux-amd64: $(SOURCE) | $(BINDIR)
	@echo "Building Linux AMD64 with: $(X86_64_GCC)"
	@if echo "$(X86_64_GCC)" | grep -q "clang"; then \
		echo "Note: Clang cross-compilation requires Linux headers..."; \
		if $(X86_64_GCC) $(CLANG_CFLAGS) -o $@ $< 2>/dev/null; then \
			echo "✅ Linux AMD64 build successful"; \
		else \
			echo "❌ Clang cross-compilation failed. Need Linux sysroot/headers."; \
			false; \
		fi; \
	else \
		$(X86_64_GCC) $(CFLAGS) -static -o $@ $< && echo "✅ Linux AMD64 build successful"; \
	fi

$(BINDIR)/xsa-linux-arm64: $(SOURCE) | $(BINDIR)
	@echo "Building Linux ARM64 with: $(AARCH64_GCC)"
	@if echo "$(AARCH64_GCC)" | grep -q "clang"; then \
		echo "Note: Clang cross-compilation requires Linux headers..."; \
		if $(AARCH64_GCC) $(CLANG_CFLAGS) -o $@ $< 2>/dev/null; then \
			echo "✅ Linux ARM64 build successful"; \
		else \
			echo "❌ Clang cross-compilation failed. Need Linux sysroot/headers."; \
			false; \
		fi; \
	else \
		$(AARCH64_GCC) $(CFLAGS) -static -o $@ $< && echo "✅ Linux ARM64 build successful"; \
	fi

clean:
	rm -rf $(BINDIR)

install-deps:
	@echo "Install cross-compilation toolchains:"
	@echo ""
	@echo "Option 1 - Using crosstool-ng (Recommended for complete toolchain):"
	@echo "  brew install crosstool-ng"
	@echo "  ct-ng list-samples | grep linux"
	@echo "  ct-ng x86_64-unknown-linux-gnu && ct-ng build"
	@echo "  ct-ng aarch64-unknown-linux-gnu && ct-ng build"
	@echo ""
	@echo "Option 2 - Quick setup for Clang cross-compilation:"
	@echo "  make setup-clang-sysroot"
	@echo ""
	@echo "Option 3 - Using package managers:"
	@echo "  macOS: brew install x86_64-linux-gnu-gcc aarch64-linux-gnu-gcc"
	@echo "  Ubuntu: apt-get install gcc-x86-64-linux-gnu gcc-aarch64-linux-gnu"
	@echo ""
	@echo "Option 4 - macOS native:"
	@echo "  xcode-select --install"

setup-clang-sysroot:
	@echo "Setting up Linux sysroot for Clang cross-compilation..."
	@echo "This will download a minimal Linux sysroot for cross-compilation."
	@echo ""
	@if [ ! -d "/usr/local/sysroot" ]; then \
		echo "Creating sysroot directory..."; \
		sudo mkdir -p /usr/local/sysroot; \
		echo "Note: You can also manually download a Linux sysroot and update CLANG_CFLAGS in Makefile"; \
		echo "Example: --sysroot=/path/to/linux-sysroot"; \
	else \
		echo "Sysroot directory already exists at /usr/local/sysroot"; \
	fi
	@echo ""
	@echo "Manual setup alternative:"
	@echo "1. Download a Linux Docker image: docker pull ubuntu:20.04"
	@echo "2. Extract headers: docker export \$$(docker create ubuntu:20.04) | tar -C /tmp/sysroot -xf -"
	@echo "3. Update Makefile to use: --sysroot=/tmp/sysroot"

check-tools:
	@echo "Checking available cross-compilation tools:"
	@echo ""
	@echo "Clang/LLVM: $(if $(CLANG),✅ $(CLANG),❌ Not found)"
	@echo "X86_64 Compiler: $(if $(X86_64_GCC),✅ $(X86_64_GCC),❌ Not found)"
	@echo "AARCH64 Compiler: $(if $(AARCH64_GCC),✅ $(AARCH64_GCC),❌ Not found)"
	@echo ""
	@echo "Available options:"
	@if [ -n "$(CROSSTOOL_X86_64)" ]; then echo "  Crosstool-ng X86_64: ✅ $(CROSSTOOL_X86_64)"; fi
	@if [ -n "$(CROSSTOOL_AARCH64)" ]; then echo "  Crosstool-ng AARCH64: ✅ $(CROSSTOOL_AARCH64)"; fi
	@if [ -n "$(CLANG)" ]; then \
		echo "  Clang X86_64: ✅ $(CLANG) --target=x86_64-linux-gnu"; \
		echo "  Clang AARCH64: ✅ $(CLANG) --target=aarch64-linux-gnu"; \
	fi

help:
	@echo "Available targets:"
	@echo "  all                 - Build all available targets (default)"
	@echo "  native              - Build native target only (macOS ARM64)"
	@echo "  clean               - Remove bin directory and all built binaries"
	@echo "  check-tools         - Check available cross-compilation tools"
	@echo "  install-deps        - Show cross-compilation toolchain installation instructions"
	@echo "  setup-clang-sysroot - Setup Linux sysroot for Clang cross-compilation"
	@echo ""
	@echo "Output directory: $(BINDIR)/"
	@echo "Potential targets:"
	@echo "  $(BINDIR)/xsa-darwin-arm64  - macOS ARM64"
	@echo "  $(BINDIR)/xsa-linux-amd64   - Linux AMD64 (requires cross-compiler)"
	@echo "  $(BINDIR)/xsa-linux-arm64   - Linux ARM64 (requires cross-compiler)"