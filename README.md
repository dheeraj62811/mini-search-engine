# Shell-Based Mini Search Engine

An interactive Bash search engine that scans directories of text and code files for multiple keywords, ranks matching files by relevance, highlights matches in the terminal, and generates a summary report.

## Features
- **Interactive Menu:** Choose between local folders, Windows drives (via WSL), or custom paths.
- **AND / OR Search:** Match files containing *all* keywords (`AND`) or *any* keyword (`OR`).
- **Relevance Ranking:** Counts total keyword occurrences per file and sorts results from highest to lowest.
- **Highlighted Output:** Highlights matched terms directly in the terminal.
- **Summary Report:** Automatically saves file names, match counts, and sample lines to `search_summary.txt`.

## Tools Used
- **`grep`** – Filters files for keyword matches and extracts sample lines with line numbers.
- **`awk`** – Counts case-insensitive keyword occurrences to calculate relevance scores.
- **`sed`** – Highlights matched keywords in terminal output and formats summary lines.
- **`find` & `sort`** – Recursively locates readable files (skipping system folders) and ranks results.

## How to Run
1. Make the script executable:
   ```bash
   chmod +x mini_search.sh
