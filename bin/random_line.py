#!/usr/bin/env python3

import random
import sys

def print_random_line(file_path, colour=None):
    #Read a text file and print a random line with optional colour.

    try:
        with open(file_path, 'r') as file:
            lines = file.readlines()
        
        if not lines:
            print("File is empty")
            return
        
        random_line = random.choice(lines).strip()
        
        # Colour Codes
        # Colours are essentially chosen in bash using '\033[{text_style};{intensity}{colour_choice}m' to make something that looks like '\033[0;31m'
        # The below randomly generates a selection of these codes.
        colour_int = str(random.randint(0,7))
        text_style = random.choice(["0","1","4",])
        intensity = random.choice(["3","4","9","10"])

        colour_code = '\033[%s;%s%sm' % (text_style,intensity,colour_int)
        reset_code = '\033[0m'
        
        print(f"\n\n\n{colour_code}{random_line}{reset_code}\n\n\n")
    
    except FileNotFoundError:
        print(f"Couldn't find your aphorisms!")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python random_line.py <file_path> [colour]")
        sys.exit(1)
    
    file_path = sys.argv[1]
    colour = sys.argv[2] if len(sys.argv) > 2 else None
    
    print_random_line(file_path, colour)