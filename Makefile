# Makefile for processing OpenVEX files and generating reports in various formats

.PHONY: build clean help

# Variables
FORMATS ?= csv trivyignore

# Default target
build: clean
	@echo "Building reports in formats: $(FORMATS)"
	@mkdir -p dist
	@find pkg -name "openvex.json" -type f | while read vex_file; do \
		echo "Processing $$vex_file..."; \
		relative_path=$$(echo $$vex_file | sed 's|^pkg/||' | sed 's|/openvex.json$$||'); \
		for format in $(FORMATS); do \
			case "$$format" in \
				csv) \
					output_file="dist/$$(echo $$relative_path | tr '/' '_').csv"; \
					echo "CVE_ID,Status,Justification,Impact_Statement" > "$$output_file"; \
					jq -r '.statements[] | [.vulnerability.name, .status, (.justification // ""), (.impact_statement // "")] | @csv' "$$vex_file" >> "$$output_file"; \
					echo "  Created $$output_file"; \
					;; \
				trivyignore) \
					output_file="dist/$$(echo $$relative_path | tr '/' '_').trivyignore.yaml"; \
					echo "vulnerabilities:" > "$$output_file"; \
					jq -r '.statements[] | select(.status == "not_affected") | "  - id: " + .vulnerability.name + (if .impact_statement then "\n    statement: " + .impact_statement else "" end)' "$$vex_file" >> "$$output_file"; \
					echo "  Created $$output_file"; \
					;; \
				*) \
					echo "  Warning: Unknown format '$$format' - skipping"; \
					;; \
			esac; \
		done; \
	done
	@echo "Build completed at: $$(date -u +"%Y-%m-%d %H:%M:%S UTC")" >> dist/build_info.txt
	@echo "Build complete! Files are in the dist/ directory."

# Clean the dist directory
clean:
	@echo "Cleaning dist directory..."
	@rm -rf dist
	@echo "Clean complete."

# Show help
help:
	@echo "Available targets:"
	@echo "  build     - Process all OpenVEX files and generate reports"
	@echo "  clean     - Remove the dist directory and all generated files"
	@echo "  help      - Show this help message"
	@echo ""
	@echo "Variables:"
	@echo "  FORMATS   - Space-separated list of output formats (default: csv trivyignore)"
	@echo "            Available formats: csv trivyignore"
	@echo ""
	@echo "Examples:"
	@echo "  make build                      # Generate both CSV and trivyignore files (default)"
	@echo "  make build FORMATS=csv         # Generate only CSV files"
	@echo "  make build FORMATS=trivyignore # Generate only trivyignore files"
	@echo "  make build FORMATS=\"csv trivyignore\" # Generate both formats (explicit)"
