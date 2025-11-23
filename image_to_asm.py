#!/usr/bin/env python3
import sys

def create_pattern_image(output_path):
    """Create a simple gradient pattern - NO PIL NEEDED!"""
    
    with open(output_path, 'w') as f:
        f.write("# Generated 256x256 gradient pattern\n")
        f.write(".data 0x00002000\n\n")
        f.write("image_data:\n")
        
        word_count = 0
        
        for y in range(256):
            for x in range(256):
                # Create a simple gradient
                # Red increases left to right
                # Green increases top to bottom
                # Blue is a checkerboard
                
                r = x  # 0-255
                g = y  # 0-255
                b = 128 if (x ^ y) & 16 else 0
                
                # Pack into 24-bit color
                color = (r << 16) | (g << 8) | b
                
                if word_count % 8 == 0:
                    if word_count > 0:
                        f.write("\n")
                    f.write("    .word ")
                else:
                    f.write(", ")
                
                f.write(f"0x{color:06X}")
                word_count += 1
            
            # Show progress
            if (y + 1) % 32 == 0:
                print(f"Progress: {(y+1)/256*100:.0f}%")
        
        f.write("\n")
    
    print(f"\nCreated {output_path} with {word_count} pixels!")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 create_image.py output.asm")
        sys.exit(1)
    
    create_pattern_image(sys.argv[1])