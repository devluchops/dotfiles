# =============================================================================
# USEFUL FUNCTIONS - Enhanced productivity functions
# =============================================================================

# Create directory and change into it
mkcd() {
    if [[ -z "$1" ]]; then
        echo "Usage: mkcd <directory_name>"
        return 1
    fi
    mkdir -p "$1" && cd "$1"
}

# Extract any archive
extract() {
    if [[ -z "$1" ]]; then
        echo "Usage: extract <archive_file>"
        return 1
    fi
    
    if [[ ! -f "$1" ]]; then
        echo "Error: '$1' is not a valid file"
        return 1
    fi
    
    case "$1" in
        *.tar.bz2)   tar xjf "$1"     ;;
        *.tar.gz)    tar xzf "$1"     ;;
        *.bz2)       bunzip2 "$1"     ;;
        *.rar)       unrar x "$1"     ;;
        *.gz)        gunzip "$1"      ;;
        *.tar)       tar xf "$1"      ;;
        *.tbz2)      tar xjf "$1"     ;;
        *.tgz)       tar xzf "$1"     ;;
        *.zip)       unzip "$1"       ;;
        *.Z)         uncompress "$1"  ;;
        *.7z)        7z x "$1"        ;;
        *)           echo "Error: '$1' cannot be extracted via extract()" ;;
    esac
}

# Find process by name
psg() {
    if [[ -z "$1" ]]; then
        echo "Usage: psg <process_name>"
        return 1
    fi
    ps aux | grep -i "$1" | grep -v grep
}

# Kill process by name
killp() {
    if [[ -z "$1" ]]; then
        echo "Usage: killp <process_name>"
        return 1
    fi
    local pids=$(pgrep -f "$1")
    if [[ -n "$pids" ]]; then
        echo "Killing processes matching '$1':"
        echo "$pids" | xargs ps -p
        echo "$pids" | xargs kill
    else
        echo "No processes found matching '$1'"
    fi
}

# Weather function
weather() {
    local city="${1:-Madrid}"
    curl -s "wttr.in/$city?format=3"
}

# Get detailed weather
weatherfull() {
    local city="${1:-Madrid}"
    curl -s "wttr.in/$city"
}

# Create a backup of a file
backup() {
    if [[ -z "$1" ]]; then
        echo "Usage: backup <file>"
        return 1
    fi
    cp "$1" "$1.backup.$(date +%Y%m%d_%H%M%S)"
    echo "Backup created: $1.backup.$(date +%Y%m%d_%H%M%S)"
}

# Find files by name
ff() {
    if [[ -z "$1" ]]; then
        echo "Usage: ff <filename_pattern>"
        return 1
    fi
    find . -type f -iname "*$1*" 2>/dev/null
}

# Find directories by name
fd_dir() {
    if [[ -z "$1" ]]; then
        echo "Usage: fd_dir <dirname_pattern>"
        return 1
    fi
    find . -type d -iname "*$1*" 2>/dev/null
}

# Get file size in human readable format
fsize() {
    if [[ -z "$1" ]]; then
        echo "Usage: fsize <file>"
        return 1
    fi
    if [[ -f "$1" ]]; then
        ls -lh "$1" | awk '{print $5}'
    else
        echo "File not found: $1"
    fi
}

# Quick HTTP server with port selection
httpserver() {
    local port="${1:-8000}"
    echo "Starting HTTP server on port $port"
    echo "Access at: http://localhost:$port"
    python3 -m http.server "$port"
}

# Generate random password
genpass() {
    local length="${1:-16}"
    openssl rand -base64 $((length * 3 / 4)) | tr -d "=+/" | cut -c1-"$length"
}

# Get public IP
myip() {
    curl -s https://httpbin.org/ip | jq -r .origin
}

# Get local IP
localip() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        ipconfig getifaddr en0
    else
        hostname -I | awk '{print $1}'
    fi
}

# URL encode
urlencode() {
    if [[ -z "$1" ]]; then
        echo "Usage: urlencode <string>"
        return 1
    fi
    python3 -c "import urllib.parse; print(urllib.parse.quote('$1'))"
}

# URL decode
urldecode() {
    if [[ -z "$1" ]]; then
        echo "Usage: urldecode <encoded_string>"
        return 1
    fi
    python3 -c "import urllib.parse; print(urllib.parse.unquote('$1'))"
}

# JSON pretty print
jsonpp() {
    if [[ -z "$1" ]]; then
        python3 -m json.tool
    else
        cat "$1" | python3 -m json.tool
    fi
}

# Base64 encode
b64encode() {
    if [[ -z "$1" ]]; then
        echo "Usage: b64encode <string>"
        return 1
    fi
    echo -n "$1" | base64
}

# Base64 decode
b64decode() {
    if [[ -z "$1" ]]; then
        echo "Usage: b64decode <encoded_string>"
        return 1
    fi
    echo "$1" | base64 --decode
}

# Quick note taking
note() {
    local note_file="$HOME/notes.txt"
    if [[ -z "$1" ]]; then
        if [[ -f "$note_file" ]]; then
            cat "$note_file"
        else
            echo "No notes found. Use: note 'your note here'"
        fi
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $*" >> "$note_file"
        echo "Note added to $note_file"
    fi
}

# Calculator
calc() {
    if [[ -z "$1" ]]; then
        echo "Usage: calc <expression>"
        echo "Example: calc '2 + 2'"
        return 1
    fi
    python3 -c "print($1)"
}
