#!/bin/bash
# Machine Detection & Configuration Loader
# Detects hardware and loads appropriate configurations

detect_machine_type() {
    local machine_type
    
    # Check for laptop indicators
    if ls /sys/class/power_supply/ | grep -q BAT; then
        machine_type="laptop"
    else
        machine_type="desktop"
    fi
    
    echo "$machine_type"
}

detect_monitor_count() {
    local count=0
    
    # Count connected monitors using hyprctl
    if command -v hyprctl &>/dev/null; then
        count=$(hyprctl monitors | grep -c "Monitor" || echo "1")
    else
        count="1"  # Default to single monitor
    fi
    
    echo "$count"
}

detect_monitor_names() {
    local names=()
    
    if command -v hyprctl &>/dev/null; then
        while IFS= read -r line; do
            if [[ "$line" =~ ^Monitor[[:space:]]+([a-zA-Z0-9-]+) ]]; then
                names+=("${BASH_REMATCH[1]}")
            fi
        done < <(hyprctl monitors 2>/dev/null)
    fi
    
    # Fallback to common monitor names
    if [[ ${#names[@]} -eq 0 ]]; then
        names=("eDP-1")  # Default laptop screen
    fi
    
    printf '%s\n' "${names[@]}"
}

detect_gpu_type() {
    local gpu
    
    # Check for NVIDIA
    if lspci | grep -i "NVIDIA" &>/dev/null; then
        gpu="nvidia"
    # Check for AMD
    elif lspci | grep -i "AMD.*VGA\|AMD.*Display" &>/dev/null; then
        gpu="amd"
    # Check for Intel
    elif lspci | grep -i "Intel.*VGA\|Intel.*Display" &>/dev/null; then
        gpu="intel"
    else
        gpu="hybrid"
    fi
    
    echo "$gpu"
}

load_machine_config() {
    local machine_type hostname
    
    machine_type=$(detect_machine_type)
    hostname=$(hostname)
    
    # Load machine-specific configs in order:
    # 1. Global config (always loaded)
    # 2. Machine type config (laptop/desktop)
    # 3. Hostname-specific config (arch-thinkpad, etc.)
    # 4. .env.local overrides
    
    local configs=(
        "$HOME/.config/hypr/config.conf"           # Base config
        "$HOME/.config/hypr/${machine_type}.conf"  # Type-specific
        "$HOME/.config/hypr/${hostname}.conf"     # Host-specific
    )
    
    for config in "${configs[@]}"; do
        if [[ -f "$config" ]]; then
            echo "source=$config" >> "/tmp/hyprland-dynamic.conf"
        fi
    done
    
    # Source .env.local if exists
    if [[ -f "$HOME/.config/hypr/.env.local" ]]; then
        source "$HOME/.config/hypr/.env.local"
    fi
    
    # Set detected variables
    export MACHINE_TYPE="$machine_type"
    export HOSTNAME="$hostname"
    export MONITOR_COUNT=$(detect_monitor_count)
    export MONITOR_NAMES=($(detect_monitor_names))
    export GPU_TYPE=$(detect_gpu_type)
}

# Export functions for use in other scripts
export -f detect_machine_type
export -f detect_monitor_count  
export -f detect_monitor_names
export -f detect_gpu_type
export -f load_machine_config