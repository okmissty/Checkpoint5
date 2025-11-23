import struct
from PIL import Image
import os

# --- CONFIGURATION ---
IMAGE_FILENAME = "mango.png" # Using the provided image file name
OUTPUT_FILENAME = "image_data.txt" # The static memory file for the assembler
IMAGE_SIZE = 256 # As per Project 5 Challenge requirement (256x256)
# ---------------------

def image_to_static_memory(image_path, output_path, target_size):
    """
    Converts a square image into a list of 32-bit (ARGB) pixel values
    suitable for MIPS static memory storage.
    Format: 0x00RRGGBB (32-bit word, where R, G, B are 8 bits each)
    """
    if not os.path.exists(image_path):
        print(f"Error: Image file not found at '{image_path}'")
        print("Please ensure the image is in the same directory and named correctly.")
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
    
    if len(pixels) != total_pixels:
        print(f"Warning: Expected {total_pixels} pixels, but found {len(pixels)}. Check image size.")
        return

    print(f"Processing {total_pixels} pixels...")

    pixel_data_words = []

    for r, g, b in pixels:
        # Combine R, G, B into a single 32-bit word (0x00RRGGBB)
        word = (0x00 << 24) | (r << 16) | (g << 8) | b
        pixel_data_words.append(word)

    with open(output_path, 'w') as f:
        f.write(f"# Static memory image data for {image_path}, {target_size}x{target_size} pixels.\n")
        f.write(f"# Total pixels: {total_pixels}\n")
        
        for word in pixel_data_words:
            f.write(f"0x{word:08X}\n")

    print(f"Successfully generated static memory data in '{output_path}'.")
    print(f"Total pixel words generated: {len(pixel_data_words)}")

if __name__ == "__main__":
    image_to_static_memory(IMAGE_FILENAME, OUTPUT_FILENAME, IMAGE_SIZE)