#!/bin/bash

# Function to convert hex to RGB
hex_to_rgb() {
    local hex="$1"
    if [[ ${hex} == "#"* ]]; then
        hex="${hex:1}"
    fi
    if [[ ${#hex} == 3 ]]; then
        hex="${hex:0:1}${hex:0:1}${hex:1:1}${hex:1:1}${hex:2:1}${hex:2:1}"
    fi
    r=$((16#${hex:0:2}))
    g=$((16#${hex:2:2}))
    b=$((16#${hex:4:2}))
    echo "$r $g $b"
}

# Function to find closest ANSI 256 color
find_closest_ansi() {
    local r=$1 g=$2 b=$3
    local min_dist=999999
    local closest_code=0
    
    # Check standard colors (0-15)
    for code in {0..15}; do
        case $code in
            0) cr=0; cg=0; cb=0;;
            1) cr=205; cg=0; cb=0;;
            2) cr=0; cg=205; cb=0;;
            3) cr=205; cg=205; cb=0;;
            4) cr=0; cg=0; cb=238;;
            5) cr=205; cg=0; cb=205;;
            6) cr=0; cg=205; cb=205;;
            7) cr=229; cg=229; cb=229;;
            8) cr=127; cg=127; cb=127;;
            9) cr=255; cg=0; cb=0;;
            10) cr=0; cg=255; cb=0;;
            11) cr=255; cg=255; cb=0;;
            12) cr=92; cg=92; cb=255;;
            13) cr=255; cg=0; cb=255;;
            14) cr=0; cg=255; cb=255;;
            15) cr=255; cg=255; cb=255;;
        esac
        
        dist=$(( (r-cr)**2 + (g-cg)**2 + (b-cb)**2 ))
        if [ $dist -lt $min_dist ]; then
            min_dist=$dist
            closest_code=$code
        fi
    done
    
    # Check extended colors (16-231)
    for code in {16..231}; do
        base=$((code - 16))
        r_code=$((base / 36))
        g_code=$(( (base % 36) / 6 ))
        b_code=$((base % 6))
        
        cr=$(( r_code > 0 ? 55 + r_code * 40 : 0 ))
        cg=$(( g_code > 0 ? 55 + g_code * 40 : 0 ))
        cb=$(( b_code > 0 ? 55 + b_code * 40 : 0 ))
        
        dist=$(( (r-cr)**2 + (g-cg)**2 + (b-cb)**2 ))
        if [ $dist -lt $min_dist ]; then
            min_dist=$dist
            closest_code=$code
        fi
    done
    
    # Check grayscale colors (232-255)
    for code in {232..255}; do
        gray=$(( (code - 232) * 10 + 8 ))
        dist=$(( (r-gray)**2 + (g-gray)**2 + (b-gray)**2 ))
        if [ $dist -lt $min_dist ]; then
            min_dist=$dist
            closest_code=$code
        fi
    done
    
    echo $closest_code
}

# Function to interpolate between two colors
interpolate_color() {
    local r1=$1 g1=$2 b1=$3
    local r2=$4 g2=$5 b2=$6
    local factor=$7
    
    r=$(echo "scale=0; $r1 + ($r2 - $r1) * $factor" | bc -l)
    g=$(echo "scale=0; $g1 + ($g2 - $g1) * $factor" | bc -l)
    b=$(echo "scale=0; $b1 + ($b2 - $b1) * $factor" | bc -l)
    
    r=${r%.*}
    g=${g%.*}
    b=${b%.*}
    
    [ $r -lt 0 ] && r=0
    [ $r -gt 255 ] && r=255
    [ $g -lt 0 ] && g=0
    [ $g -gt 255 ] && g=255
    [ $b -lt 0 ] && b=0
    [ $b -gt 255 ] && b=255
    
    echo "$r $g $b"
}

# Function to convert RGB to hex
rgb_to_hex() {
    printf "#%02x%02x%02x" "$1" "$2" "$3"
}

# Function to export gradient to GPL file
export_to_gpl() {
    echo -e "\nExporting gradient to GIMP Palette (GPL) file..."
    read -p "Enter a name for your palette: " palette_name
    read -p "Enter directory to save (default: current directory): " save_dir
    
    # Use current directory if none specified
    [ -z "$save_dir" ] && save_dir="."
    
    # Create filename (replace spaces with underscores)
    filename="${save_dir}/${palette_name// /_}.gpl"
    
    # Write GPL file header
    echo "GIMP Palette" > "$filename"
    echo "Name: $palette_name" >> "$filename"
    echo "Columns: 4" >> "$filename"
    echo "#" >> "$filename"
    
    # Write color entries
    for i in "${!gradient_colors[@]}"; do
        rgb=($(hex_to_rgb "${gradient_colors[i]}"))
        printf "%-3d %-3d %-3d Color %02d\n" "${rgb[0]}" "${rgb[1]}" "${rgb[2]}" "$((i+1))" >> "$filename"
    done
    
    echo -e "\n\e[32mPalette saved to: $filename\e[0m"
    
    # Also export hex codes to a text file
    hex_filename="${save_dir}/${palette_name// /_}_hex.txt"
    for color in "${gradient_colors[@]}"; do
        echo "$color" >> "$hex_filename"
    done
    
    echo -e "\e[32mHex codes saved to: $hex_filename\e[0m"
    echo -e "You can now import the GPL file into GIMP or other compatible software.\n"
}

# Main script execution
clear
echo "Hex Color Gradient Generator"
echo "==========================="

# Get user input for colors
echo -e "\nEnter 3 hex color values (e.g., #FF0000 #00FF00 #0000FF)"
read -p "Start color: " start_hex
read -p "Middle color: " middle_hex
read -p "End color: " end_hex

# Convert to RGB
start_rgb=($(hex_to_rgb "$start_hex"))
middle_rgb=($(hex_to_rgb "$middle_hex"))
end_rgb=($(hex_to_rgb "$end_hex"))

# Find closest ANSI colors
start_ansi=$(find_closest_ansi ${start_rgb[0]} ${start_rgb[1]} ${start_rgb[2]})
middle_ansi=$(find_closest_ansi ${middle_rgb[0]} ${middle_rgb[1]} ${middle_rgb[2]})
end_ansi=$(find_closest_ansi ${end_rgb[0]} ${end_rgb[1]} ${end_rgb[2]})

echo -e "\nClosest ANSI matches:"
echo -e "Start:  \e[38;5;${start_ansi}m${start_hex} (ANSI ${start_ansi})\e[0m"
echo -e "Middle: \e[38;5;${middle_ansi}m${middle_hex} (ANSI ${middle_ansi})\e[0m"
echo -e "End:    \e[38;5;${end_ansi}m${end_hex} (ANSI ${end_ansi})\e[0m"

# Generate gradient (16 stops)
gradient_colors=()
gradient_ansi=()

# First half (start to middle, 8 steps)
for i in {0..7}; do
    factor=$(echo "scale=2; $i/7" | bc)
    rgb=($(interpolate_color ${start_rgb[0]} ${start_rgb[1]} ${start_rgb[2]} \
                               ${middle_rgb[0]} ${middle_rgb[1]} ${middle_rgb[2]} \
                               $factor))
    hex=$(rgb_to_hex ${rgb[0]} ${rgb[1]} ${rgb[2]})
    ansi=$(find_closest_ansi ${rgb[0]} ${rgb[1]} ${rgb[2]})
    gradient_colors+=("$hex")
    gradient_ansi+=("$ansi")
done

# Second half (middle to end, 8 steps)
for i in {0..7}; do
    factor=$(echo "scale=2; $i/7" | bc)
    rgb=($(interpolate_color ${middle_rgb[0]} ${middle_rgb[1]} ${middle_rgb[2]} \
                               ${end_rgb[0]} ${end_rgb[1]} ${end_rgb[2]} \
                               $factor))
    hex=$(rgb_to_hex ${rgb[0]} ${rgb[1]} ${rgb[2]})
    ansi=$(find_closest_ansi ${rgb[0]} ${rgb[1]} ${rgb[2]})
    gradient_colors+=("$hex")
    gradient_ansi+=("$ansi")
done

# Display gradient preview
echo -e "\nGradient Preview:"
for i in "${!gradient_colors[@]}"; do
    printf "\e[48;5;${gradient_ansi[i]}m  \e[0m"
done
echo -e "\n"

# Colorized output table
echo "Hex       ANSI"
echo "--------  ----"
for i in "${!gradient_colors[@]}"; do
    printf "\e[38;5;${gradient_ansi[i]}m%-9s %3d\e[0m\n" "${gradient_colors[i]}" "${gradient_ansi[i]}"
done

# Export prompt
while true; do
    read -p $'\nDo you want to export this gradient to files? (y/n) ' yn
    case $yn in
        [Yy]* ) export_to_gpl; break;;
        [Nn]* ) echo -e "\nDone!"; exit;;
        * ) echo "Please answer yes or no.";;
    esac
done
