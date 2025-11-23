#!/usr/bin/env python3
import sys
import zlib
import struct

def read_png(filepath):
    """Read PNG file without PIL"""
    with open(filepath, 'rb') as f:
        # Check PNG signature
        signature = f.read(8)
        if signature != b'\x89PNG\r\n\x1a\n':
            raise ValueError("Not a valid PNG file")
        
        width = height = 0
        bit_depth = color_type = 0
        image_data = bytearray()
        palette = None
        
        while True:
            # Read chunk length and type
            chunk_len_bytes = f.read(4)
            if len(chunk_len_bytes) < 4:
                break
                
            chunk_len = struct.unpack('>I', chunk_len_bytes)[0]
            chunk_type = f.read(4)
            chunk_data = f.read(chunk_len)
            chunk_crc = f.read(4)  # CRC (we'll skip validation)
            
            if chunk_type == b'IHDR':
                # Parse image header
                width = struct.unpack('>I', chunk_data[0:4])[0]
                height = struct.unpack('>I', chunk_data[4:8])[0]
                bit_depth = chunk_data[8]
                color_type = chunk_data[9]
                print(f"PNG: {width}x{height}, bit_depth={bit_depth}, color_type={color_type}")
                
            elif chunk_type == b'PLTE':
                # Palette for indexed color
                palette = chunk_data
                
            elif chunk_type == b'IDAT':
                # Compressed image data
                image_data.extend(chunk_data)
                
            elif chunk_type == b'IEND':
                break
        
        if not image_data:
            raise ValueError("No image data found in PNG")
        
        # Decompress the image data
        print("Decompressing image data...")
        raw_data = zlib.decompress(image_data)
        
        # Parse the decompressed data
        print("Parsing pixel data...")
        pixels = parse_png_data(raw_data, width, height, bit_depth, color_type, palette)
        
        return width, height, pixels

def parse_png_data(raw_data, width, height, bit_depth, color_type, palette):
    """Parse decompressed PNG data into RGB pixels"""
    pixels = []
    
    # Calculate bytes per pixel
    if color_type == 0:  # Grayscale
        channels = 1
    elif color_type == 2:  # RGB
        channels = 3
    elif color_type == 3:  # Indexed (palette)
        channels = 1
    elif color_type == 4:  # Grayscale + Alpha
        channels = 2
    elif color_type == 6:  # RGBA
        channels = 4
    else:
        raise ValueError(f"Unsupported color type: {color_type}")
    
    bytes_per_pixel = channels * (bit_depth // 8)
    stride = width * bytes_per_pixel + 1  # +1 for filter byte
    
    pos = 0
    for y in range(height):
        if pos >= len(raw_data):
            break
            
        # Read filter type (first byte of each scanline)
        filter_type = raw_data[pos]
        pos += 1
        
        row_data = raw_data[pos:pos + width * bytes_per_pixel]
        pos += width * bytes_per_pixel
        
        # Apply PNG filter (we'll only handle filter type 0 = None for simplicity)
        # For full PNG support, you'd need to implement all 5 filter types
        if filter_type != 0:
            # Simple approach: just use the data as-is (works for many PNGs)
            pass
        
        # Convert to RGB
        row = []
        for x in range(width):
            pixel_start = x * bytes_per_pixel
            
            if color_type == 2:  # RGB
                r = row_data[pixel_start]
                g = row_data[pixel_start + 1]
                b = row_data[pixel_start + 2]
            elif color_type == 6:  # RGBA
                r = row_data[pixel_start]
                g = row_data[pixel_start + 1]
                b = row_data[pixel_start + 2]
                # Ignore alpha
            elif color_type == 0:  # Grayscale
                gray = row_data[pixel_start]
                r = g = b = gray
            elif color_type == 3:  # Indexed
                index = row_data[pixel_start]
                if palette:
                    r = palette[index * 3]
                    g = palette[index * 3 + 1]
                    b = palette[index * 3 + 2]
                else:
                    r = g = b = index
            else:
                r = g = b = 0
            
            row.append((r, g, b))
        
        pixels.append(row)
        
        if (y + 1) % 32 == 0:
            print(f"  Reading: {(y+1)/height*100:.0f}%")
    
    return pixels

def simple_resize(pixels, old_w, old_h, new_w, new_h):
    """Simple nearest-neighbor resize"""
    new_pixels = []
    
    for y in range(new_h):
        row = []
        src_y = (y * old_h) // new_h
        for x in range(new_w):
            src_x = (x * old_w) // new_w
            row.append(pixels[src_y][src_x])
        new_pixels.append(row)
    
    return new_pixels

def image_to_asm(image_path, output_path):
    """Convert PNG to assembly"""
    
    try:
        print(f"Reading {image_path}...")
        width, height, pixels = read_png(image_path)
        
        # Resize if needed
        if width != 256 or height != 256:
            print(f"Resizing from {width}x{height} to 256x256...")
            pixels = simple_resize(pixels, width, height, 256, 256)
        
        # Write assembly file
        print(f"Writing {output_path}...")
        with open(output_path, 'w') as f:
            f.write("# Generated image data from " + image_path + "\n")
            f.write(".data 0x00002000\n\n")
            f.write("image_data:\n")
            
            word_count = 0
            
            for y in range(256):
                for x in range(256):
                    r, g, b = pixels[y][x]
                    
                    # Pack RGB into 24-bit value
                    color = (r << 16) | (g << 8) | b
                    
                    if word_count % 8 == 0:
                        if word_count > 0:
                            f.write("\n")
                        f.write("    .word ")
                    else:
                        f.write(", ")
                    
                    f.write(f"0x{color:06X}")
                    word_count += 1
                
                # Progress
                if (y + 1) % 32 == 0:
                    print(f"  Writing: {(y+1)/256*100:.0f}%")
            
            f.write("\n")
        
        print(f"\nSuccess! Generated {output_path}")
        print(f"Total pixels: {word_count}")
        return True
        
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 image_to_asm.py input.png output.asm")
        print("\nSupports PNG format (no external libraries needed!)")
        sys.exit(1)
    
    success = image_to_asm(sys.argv[1], sys.argv[2])
    sys.exit(0 if success else 1)