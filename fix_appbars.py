import os
import re

directory = "lib/ui"

for root, _, files in os.walk(directory):
    for file in files:
        if file.endswith(".dart"):
            path = os.path.join(root, file)
            with open(path, "r", encoding="utf-8") as f:
                content = f.read()

            # Find all AppBar( occurrences
            appbar_pattern = re.compile(r'AppBar\s*\(')
            matches = list(appbar_pattern.finditer(content))
            if not matches:
                continue

            new_content = ""
            last_idx = 0
            changed = False

            for match in matches:
                start = match.start()
                # Find the matching closing parenthesis
                open_parens = 0
                end = -1
                for i in range(match.end() - 1, len(content)):
                    if content[i] == '(':
                        open_parens += 1
                    elif content[i] == ')':
                        open_parens -= 1
                        if open_parens == 0:
                            end = i
                            break
                
                if end != -1:
                    appbar_content = content[start:end+1]
                    if 'centerTitle:' not in appbar_content:
                        # Add centerTitle: true, after AppBar(
                        new_appbar_content = appbar_content.replace('AppBar(', 'AppBar(\n            centerTitle: true,', 1)
                        new_content += content[last_idx:start] + new_appbar_content
                        last_idx = end + 1
                        changed = True
                        print(f"Added centerTitle to {path}")
                    else:
                        new_content += content[last_idx:end+1]
                        last_idx = end + 1

            new_content += content[last_idx:]

            if changed:
                with open(path, "w", encoding="utf-8") as f:
                    f.write(new_content)

print("Done")
