CC = gcc
CFLAGS = -Wall -O2
SOURCE = xsa.c
BINDIR = bin
TARGET = $(BINDIR)/xsa

.PHONY: all clean help

all: $(BINDIR) $(TARGET)

$(TARGET): $(SOURCE) | $(BINDIR)
	$(CC) $(CFLAGS) -o $@ $<
	@echo "✅ Build successful: $@"

$(BINDIR):
	mkdir -p $(BINDIR)

clean:
	rm -rf $(BINDIR)

help:
	@echo "Available targets:"
	@echo "  all    - Build xsa binary (default)"
	@echo "  clean  - Remove bin directory and all built binaries"
	@echo "  help   - Show this help message"
	@echo ""
	@echo "Output: $(TARGET)"