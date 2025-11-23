#!/usr/bin/env python3
import sys
import zlib
import struct

def read_png(filepath):
    """Read PNG file without PIL"""
    with open(filepath, 'rb') as f:
        signature = f.read(8)
        if signature != b'\x89PNG\r\n\x1a\n':
            raise ValueError("Not a valid PNG file")
        
        width = height = 0
        bit_depth = color_type = 0
        image_data = bytearray()
        palette = None
        
        while True:
            chunk_len_bytes = f.read(4)
            if len(chunk_len_bytes) < 4:
                break
                
            chunk_len = struct.unpack('>I', chunk_len_bytes)[0]
            chunk_type = f.read(4)
            chunk_data = f.read(chunk_len)
            chunk_crc = f.read(4)
            
            if chunk_type == b'IHDR':
                width = struct.unpack('>I', chunk_data[0:4])[0]
                height = struct.unpack('>I', chunk_data[4:8])[0]
                bit_depth = chunk_data[8]
                color_type = chunk_data[9]
                print(f"PNG: {width}x{height}, bit_depth={bit_depth}, color_type={color_type}")
                
            elif chunk_type == b'PLTE':
                palette = chunk_data
                
            elif chunk_type == b'IDAT':
                image_data.extend(chunk_data)
                
            elif chunk_type == b'IEND':
                break
        
        if not image_data:
            raise ValueError("No image data found in PNG")
        
        print("Decompressing image data...")
        raw_data = zlib.decompress(image_data)
        
        print("Parsing pixel data...")
        pixels = parse_png_data(raw_data, width, height, bit_depth, color_type, palette)
        
        return width, height, pixels

def parse_png_data(raw_data, width, height, bit_depth, color_type, palette):
    """Parse decompressed PNG data with proper filter handling"""
    pixels = []
    
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
    
    bytes_per_pixel = channels * max(1, bit_depth // 8)
    scanline_length = width * bytes_per_pixel
    
    pos = 0
    prev_row = [0] * scanline_length
    
    for y in range(height):
        if pos >= len(raw_data):
            break
            
        filter_type = raw_data[pos]
        pos += 1
        
        raw_scanline = list(raw_data[pos:pos + scanline_length])
        pos += scanline_length
        
        scanline = reconstruct_scanline(raw_scanline, prev_row, filter_type, bytes_per_pixel)
        prev_row = scanline
        
        row = []
        for x in range(width):
            pixel_start = x * bytes_per_pixel
            
            if color_type == 2:  # RGB
                r = scanline[pixel_start]
                g = scanline[pixel_start + 1]
                b = scanline[pixel_start + 2]
            elif color_type == 6:  # RGBA
                r = scanline[pixel_start]
                g = scanline[pixel_start + 1]
                b = scanline[pixel_start + 2]
            elif color_type == 0:  # Grayscale
                gray = scanline[pixel_start]
                r = g = b = gray
            elif color_type == 3:  # Indexed
                index = scanline[pixel_start]
                if palette and index * 3 + 2 < len(palette):
                    r = palette[index * 3]
                    g = palette[index * 3 + 1]
                    b = palette[index * 3 + 2]
                else:
                    r = g = b = 0
            else:
                r = g = b = 0
            
            row.append((r, g, b))
        
        pixels.append(row)
    
    return pixels

def reconstruct_scanline(raw, prev, filter_type, bpp):
    """Reconstruct scanline with PNG filtering"""
    result = []
    
    for i in range(len(raw)):
        raw_byte = raw[i]
        left = result[i - bpp] if i >= bpp else 0
        above = prev[i]
        upper_left = prev[i - bpp] if i >= bpp else 0
        
        if filter_type == 0:
            recon = raw_byte
        elif filter_type == 1:
            recon = (raw_byte + left) & 0xFF
        elif filter_type == 2:
            recon = (raw_byte + above) & 0xFF
        elif filter_type == 3:
            recon = (raw_byte + ((left + above) // 2)) & 0xFF
        elif filter_type == 4:
            recon = (raw_byte + paeth_predictor(left, above, upper_left)) & 0xFF
        else:
            recon = raw_byte
        
        result.append(recon)
    
    return result

def paeth_predictor(a, b, c):
    p = a + b - c
    pa = abs(p - a)
    pb = abs(p - b)
    pc = abs(p - c)
    
    if pa <= pb and pa <= pc:
        return a
    elif pb <= pc:
        return b
    else:
        return c

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

def image_to_asm(image_path, output_path, size=64):
    """Convert PNG to assembly - SMALLER SIZE"""
    
    try:
        print(f"Reading {image_path}...")
        width, height, pixels = read_png(image_path)
        
        # Resize to smaller size (64x64 instead of 256x256)
        print(f"Resizing from {width}x{height} to {size}x{size}...")
        pixels = simple_resize(pixels, width, height, size, size)
        
        print(f"Writing {output_path}...")
        with open(output_path, 'w') as f:
            f.write("# Generated image data from " + image_path + "\n")
            f.write(".data 0x00002000\n\n")
            f.write(f"image_width: .word {size}\n")
            f.write(f"image_height: .word {size}\n\n")
            f.write("image_data:\n")
            
            word_count = 0
            
            for y in range(size):
                for x in range(size):
                    r, g, b = pixels[y][x]
                    color = (r << 16) | (g << 8) | b
                    
                    if word_count % 8 == 0:
                        if word_count > 0:
                            f.write("\n")
                        f.write("    .word ")
                    else:
                        f.write(", ")
                    
                    f.write(f"0x{color:06X}")
                    word_count += 1
            
            f.write("\n")
        
        print(f"\nSuccess! Generated {output_path}")
        print(f"Image size: {size}x{size} = {word_count} pixels")
        
        return True
        
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python3 image_to_asm_small.py input.png output.asm [size]")
        print("  size: optional, default=64 (try 64, 128, or 256)")
        sys.exit(1)
    
    size = 64
    if len(sys.argv) >= 4:
        size = int(sys.argv[3])
    
    success = image_to_asm(sys.argv[1], sys.argv[2], size)
    sys.exit(0 if success else 1)