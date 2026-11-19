#!/bin/bash

# ==============================================================================
# User-Friendly Shell-Based Mini Search Engine
# Uses: grep (search), awk (scoring/ranking), sed (highlighting)
# ==============================================================================

SUMMARY_FILE="search_summary.txt"

# Terminal Colors
CYAN=$(printf '\033[1;36m')
GREEN=$(printf '\033[1;32m')
YELLOW=$(printf '\033[1;33m')
RED=$(printf '\033[1;31m')
BOLD=$(printf '\033[1m')
RESET=$(printf '\033[0m')

while true; do
    clear
    echo "${CYAN}==================================================${RESET}"
    echo "${CYAN}                 MINI SEARCH ENGINE               ${RESET}"
    echo "${CYAN}==================================================${RESET}"
    echo ""

    # 1. Choose Location
    echo "${BOLD}Step 1: Where do you want to search?${RESET}"
    echo "  1) Test Folder (./test_docs)"
    echo "  2) My Windows Files (Desktop, Documents, Downloads)"
    echo "  3) Entire C: Drive (Slower)"
    echo "  4) Current Folder (.)"
    echo "  5) Enter a Custom Folder Path"
    echo "  0) Exit"
    echo ""
    read -rp "Choose an option [1-5, 0 to exit]: " LOC_CHOICE

    case "$LOC_CHOICE" in
        1) SEARCH_DIR="./test_docs" ;;
        2) SEARCH_DIR="/mnt/c/Users" ;;
        3) SEARCH_DIR="/mnt/c" ;;
        4) SEARCH_DIR="." ;;
        5) read -rp "Enter full folder path: " SEARCH_DIR ;;
        0) echo "${GREEN}Goodbye!${RESET}"; exit 0 ;;
        *) echo "${RED}Invalid option.${RESET}"; sleep 1; continue ;;
    esac

    if [ ! -d "$SEARCH_DIR" ]; then
        echo ""
        echo "${RED}Error: Folder '$SEARCH_DIR' does not exist.${RESET}"
        read -rp "Press Enter to try again..."
        continue
    fi

    # 2. Choose File Types
    echo ""
    echo "${BOLD}Step 2: Which file types should be searched?${RESET}"
    echo "  1) Text files only (.txt)"
    echo "  2) Text & Code files (.txt, .md, .csv, .log, .py, .c, .java, .sh)"
    echo ""
    read -rp "Choose an option [1-2] (default: 1): " TYPE_CHOICE
    TYPE_CHOICE=${TYPE_CHOICE:-1}

    # 3. Choose Search Mode
    echo ""
    echo "${BOLD}Step 3: How should multiple keywords be matched?${RESET}"
    echo "  1) AND - File must contain ALL keywords"
    echo "  2) OR  - File can contain ANY keyword"
    echo ""
    read -rp "Choose an option [1-2] (default: 2): " MODE_CHOICE
    if [ "$MODE_CHOICE" == "1" ]; then
        MODE="AND"
    else
        MODE="OR"
    fi

    # 4. Enter Keywords
    echo ""
    while true; do
        read -rp "${BOLD}Step 4: Enter keywords (separated by spaces): ${RESET}" -a KEYWORDS
        if [ "${#KEYWORDS[@]}" -gt 0 ]; then
            break
        else
            echo "${RED}Please type at least one keyword.${RESET}"
        fi
    done

    TEMP_SCORES=$(mktemp)
    OR_PATTERN=$(IFS="|"; echo "${KEYWORDS[*]}")
    KW_LIST=$(IFS=" "; echo "${KEYWORDS[*]}")

    echo ""
    echo "${YELLOW}Searching in '$SEARCH_DIR' for [${KEYWORDS[*]}] ($MODE mode)... Please wait.${RESET}"

    # Function to generate the list of files while skipping locked Windows/system folders
    get_files() {
        if [ "$TYPE_CHOICE" == "2" ]; then
            find "$SEARCH_DIR" \
                \( -name "Windows" -o -name "Program Files" -o -name "Program Files (x86)" -o -name "AppData" -o -name '$Recycle.Bin' -o -name "node_modules" -o -name ".git" \) -prune \
                -o -type f \( -name "*.txt" -o -name "*.md" -o -name "*.csv" -o -name "*.log" -o -name "*.py" -o -name "*.c" -o -name "*.java" -o -name "*.sh" \) -readable -print 2>/dev/null
        else
            find "$SEARCH_DIR" \
                \( -name "Windows" -o -name "Program Files" -o -name "Program Files (x86)" -o -name "AppData" -o -name '$Recycle.Bin' -o -name "node_modules" -o -name ".git" \) -prune \
                -o -type f -name "*.txt" -readable -print 2>/dev/null
        fi
    }

    # 5. Search with grep and score with awk
    while IFS= read -r file; do
        match_file=false

        if [ "$MODE" == "AND" ]; then
            match_file=true
            for kw in "${KEYWORDS[@]}"; do
                if ! grep -iq -- "$kw" "$file" 2>/dev/null; then
                    match_file=false
                    break
                fi
            done
        else
            if grep -iqE -- "$OR_PATTERN" "$file" 2>/dev/null; then
                match_file=true
            fi
        fi

        if [ "$match_file" = true ]; then
            count=$(awk -v kws="$KW_LIST" '
                BEGIN {
                    n = split(tolower(kws), arr, " ")
                    total = 0
                }
                {
                    line = tolower($0)
                    for (i = 1; i <= n; i++) {
                        tmp = line
                        total += gsub(arr[i], "", tmp)
                    }
                }
                END { print total }
            ' "$file" 2>/dev/null)

            if [ -n "$count" ] && [ "$count" -gt 0 ]; then
                echo "$count|$file" >> "$TEMP_SCORES"
            fi
        fi
    done < <(get_files)

    # 6. Display Results & Save Summary
    echo ""
    if [ ! -s "$TEMP_SCORES" ]; then
        echo "${RED}No matching files found for [${KEYWORDS[*]}] in $MODE mode.${RESET}"
        rm -f "$TEMP_SCORES"
    else
        RANKED_RESULTS=$(sort -t'|' -k1,1nr "$TEMP_SCORES")
        TOTAL_FILES=$(echo "$RANKED_RESULTS" | wc -l)
        rm -f "$TEMP_SCORES"

        {
            echo "=================================================="
            echo "            MINI SEARCH ENGINE SUMMARY            "
            echo "=================================================="
            echo "Directory : $SEARCH_DIR"
            echo "Mode      : $MODE"
            echo "Keywords  : ${KEYWORDS[*]}"
            echo "Files Hit : $TOTAL_FILES"
            echo "Date      : $(date)"
            echo "=================================================="
            echo ""
        } > "$SUMMARY_FILE"

        echo "${GREEN}Found $TOTAL_FILES matching file(s) — Ranked by Relevance:${RESET}"
        echo ""

        rank=1
        while IFS='|' read -r count file; do
            echo "${CYAN}Rank #$rank${RESET} | ${BOLD}Matches: $count${RESET} | $file"
            echo "--------------------------------------------------"

            # Highlight matches with sed
            grep -inE -- "$OR_PATTERN" "$file" 2>/dev/null | head -n 3 | \
                sed -E "s/($OR_PATTERN)/${YELLOW}\1${RESET}/gi"
            echo ""

            # Append plain-text version to summary file
            {
                echo "Rank #$rank | Matches: $count | File: $file"
                echo "Sample Lines:"
                grep -inE -- "$OR_PATTERN" "$file" 2>/dev/null | head -n 3 | sed 's/^/  Line /'
                echo ""
            } >> "$SUMMARY_FILE"

            ((rank++))
        done <<< "$RANKED_RESULTS"

        echo "${GREEN}Full report saved to: $SUMMARY_FILE${RESET}"
    fi

    # 7. Next Action Menu
    echo ""
    echo "${BOLD}What would you like to do next?${RESET}"
    echo "  1) Run another search"
    echo "  2) View saved summary file ($SUMMARY_FILE)"
    echo "  3) Exit"
    read -rp "Choose an option [1-3]: " NEXT_ACTION

    case "$NEXT_ACTION" in
        2)
            clear
            if [ -f "$SUMMARY_FILE" ]; then
                cat "$SUMMARY_FILE"
            else
                echo "${RED}No summary file found.${RESET}"
            fi
            echo ""
            read -rp "Press Enter to return to the menu..."
            ;;
        3)
            echo "${GREEN}Exiting Mini Search Engine. Goodbye!${RESET}"
            break
            ;;
    esac
done
