#!/bin/bash
# Logging utilities

# Source colors
_LOGGING_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${_LOGGING_DIR}/colors.sh"

# Log functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[${CHECK_MARK}]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[${CROSS_MARK}]${NC} $1" >&2
}

log_step() {
    echo -e "\n${BOLD_CYAN}${ARROW} $1${NC}"
}

log_header() {
    echo -e "\n${BOLD_PURPLE}========================================${NC}"
    echo -e "${BOLD_PURPLE}  $1${NC}"
    echo -e "${BOLD_PURPLE}========================================${NC}\n"
}

log_subheader() {
    echo -e "\n${CYAN}--- $1 ---${NC}"
}

# Progress spinner
show_spinner() {
    local pid=$1
    local message=$2
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) %10 ))
        printf "\r${CYAN}${spin:$i:1}${NC} ${message}"
        sleep 0.1
    done
    printf "\r${GREEN}${CHECK_MARK}${NC} ${message}\n"
}

# Progress bar
progress_bar() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local filled=$((width * current / total))
    
    printf "\r${CYAN}["
    printf "%${filled}s" | tr ' ' '='
    printf "%$((width - filled))s" | tr ' ' ' '
    printf "]${NC} ${percentage}%%"
    
    if [ $current -eq $total ]; then
        echo ""
    fi
}

# Confirmation prompt
confirm() {
    local message=$1
    local default=${2:-n}
    
    if [ "$default" = "y" ]; then
        prompt="${message} [Y/n]: "
    else
        prompt="${message} [y/N]: "
    fi
    
    read -p "$(echo -e ${YELLOW}${prompt}${NC})" response
    response=${response:-$default}
    
    case "$response" in
        [yY][eE][sS]|[yY]) 
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Select from options
select_option() {
    local prompt="$1"
    shift
    local options=("$@")
    
    echo -e "${CYAN}${prompt}${NC}"
    select opt in "${options[@]}"; do
        if [ -n "$opt" ]; then
            echo "$opt"
            return 0
        fi
    done
}

