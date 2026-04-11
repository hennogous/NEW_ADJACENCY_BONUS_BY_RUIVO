import re
import sys
import os

def add_numbering(file_path):
    if not os.path.exists(file_path):
        print(f"File {file_path} not found.")
        return

    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    lines = content.split('\n')
    counters = [0] * 7 # Levels 1 to 6
    new_lines = []
    
    # We ignore the very first header as it's often the document title
    is_first_header = True
    
    for line in lines:
        match = re.match(r'^(#+)\s+(.*)', line)
        if match:
            hashes = match.group(1)
            title = match.group(2)
            level = len(hashes)
            
            # Remove any existing numbering like "1.1. Title"
            title = re.sub(r'^(\d+\.)+\s+', '', title)
            
            if is_first_header:
                # Keep the title as is without a number
                new_lines.append(f"{hashes} {title}")
                is_first_header = False
                continue
            
            # Level 1 (#) starts from 1., level 2 (##) starts from 1.1., etc.
            # But the document has its title at level 1, and the next level is level 2 (## 前言)
            # We want level 2 headers (##) to be 1, 2, 3... or 1.1, 1.2... ?
            # User said "比如1.1 1.1.1啥的"
            # If the title is level 1, then the first ## should be 1.1.
            
            counters[level] += 1
            # Reset all deeper levels
            for i in range(level + 1, 7):
                counters[i] = 0
            
            # Build prefix from level 1 to current level
            # We assume level 1 is the main title and we want prefix to be e.g. "1.1."
            # Actually, let's treat the first # as "1", but we won't show its number.
            # Let's set counters[1] = 1 at start.
            if level == 1:
                prefix = f"{counters[1]}."
            else:
                # Prefix starts from level 1
                # But counters[1] is the main title's number.
                # If counters[1] is 1, prefix for level 2 is "1.1."
                parts = []
                # We start from level 1. Since we have only one level 1 title, it's always 1.
                # If there are more level 1 titles, it will increment.
                for i in range(1, level + 1):
                    parts.append(str(max(1, counters[i])))
                prefix = '.'.join(parts) + "."
            
            new_lines.append(f"{hashes} {prefix} {title}")
        else:
            new_lines.append(line)

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(new_lines))
    print(f"Successfully added numbering to {file_path}")

if __name__ == "__main__":
    # If the title is # RUIVO..., we set it as 1. internally.
    # We want ## 前言 to be 1.1.
    # We want # 前置知识 to be 2.
    
    # Corrected logic for counters:
    def add_numbering_corrected(file_path):
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        counters = [0] * 7
        new_lines = []
        is_first_header = True
        
        for line in lines:
            line = line.rstrip('\n')
            match = re.match(r'^(#+)\s+(.*)', line)
            if match:
                hashes = match.group(1)
                title = match.group(2)
                level = len(hashes)
                
                # Remove old numbering
                title = re.sub(r'^(\d+\.)+\s+', '', title)
                
                if is_first_header:
                    new_lines.append(f"{hashes} {title}")
                    counters[level] = 1
                    is_first_header = False
                    continue
                
                # Increment current level
                counters[level] += 1
                # Reset all deeper levels
                for i in range(level + 1, 7):
                    counters[i] = 0
                
                # Build prefix from level 1 up to level
                parts = []
                for i in range(1, level + 1):
                    # If a parent level hasn't been encountered yet, default to 1
                    val = max(1, counters[i])
                    parts.append(str(val))
                prefix = '.'.join(parts) + '.'
                new_lines.append(f"{hashes} {prefix} {title}")
            else:
                new_lines.append(line)
        
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write('\n'.join(new_lines) + '\n')
            
    # Apply to both files
    files = [
        r"c:\Users\周瑞丰\Documents\My Games\Sid Meier's Civilization VI\Mods\NEW_ADJACENCY_BONUS_BY_RUIVO\!参考性文件(reference_folder)\模块化相邻加成教程-by_Ruivo.md",
        r"c:\Users\周瑞丰\Documents\My Games\Sid Meier's Civilization VI\Mods\NEW_ADJACENCY_BONUS_BY_RUIVO\!参考性文件(reference_folder)\Modular_Adjacency_Bonus_Tutorial-by_Ruivo.md"
    ]
    
    for f_path in files:
        add_numbering_corrected(f_path)
        print(f"Updated {f_path}")
