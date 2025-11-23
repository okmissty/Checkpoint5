import struct
from PIL import Image
import os

# Config area, you can change these values as needed
# Change filename if you want to use a different image and make sure the image is 256x256 pixels
IMAGE_FILENAME = "mango.png" 
OUTPUT_FILENAME = "image_data.hex" # Outputting Logisim v3.0 hex file
IMAGE_SIZE = 256
START_ADDRESS = 0x00010000 # Must match the address used in draw_mango.asm
# ---------------------

def image_to_v3_hex(image_path, output_path, target_size, start_address):
    """
    Converts image data into Logisim's v3.0 hex format for direct RAM loading.
    Format: v3.0 hex <start_address> <word1> <word2> ...
    """
    if not os.path.exists(image_path):
        print(f"Error: Image file not found at '{image_path}'")
        return

    print(f"Loading image: {image_path}...")
    try:
        img = Image.open(image_path).convert("RGB")
    except Exception as e:
        print(f"Error opening or processing image: {e}")
        return

    if img.width != target_size or img.height != target_size:
        print(f"Resizing image from {img.width}x{img.height} to {target_size}x{target_size}...")
        img = img.resize((target_size, target_size))

    pixels = list(img.getdata())
    total_pixels = target_size * target_size
    
    print(f"Processing {total_pixels} pixels...")

    with open(output_path, 'w') as f:
        # Writes the v3.0 hex header and start address
        f.write("v3.0 hex\n")
        f.write(f"{start_address:X}\n")

        # Writes the pixel data as 32-bit words in hex format
        line_count = 0
        for r, g, b in pixels:
            # Combine R, G, B into a single 32-bit word (0x00RRGGBB)
            # The word is written in text, so Logisim handles the endianness on import
            word = (0x00 << 24) | (r << 16) | (g << 8) | b
            f.write(f"{word:08X} ") # Write as 8-digit hex (e.g., FF A5 00)
            
            line_count += 1
            if line_count % 8 == 0: # 8 words per line for readability
                f.write("\n")
        
    print(f"\nSuccessfully generated Logisim-compatible hex data in '{output_path}'.")
    print(f"*** Load the file directly into your Data RAM starting at address {start_address:X}. ***")

if __name__ == "__main__":
    image_to_v3_hex(IMAGE_FILENAME, OUTPUT_FILENAME, IMAGE_SIZE, START_ADDRESS)