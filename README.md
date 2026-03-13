# newf
I've always wondered what this werid "Templates" directory
created by xdg-user-dirs is for.
After research, it turned out to be quite useless even on
full-armored desktop environment like KDE.
Then I decided to write a script to utilize this dir. So here you are ...

`newf` is a m4-based file creator. It automatically detects filetypes
based on target filenames and populates them using templates from your
`XDG_TEMPLATES_DIR`.


## Installation
Install main script, its manual page and fish completion script:
```sh
sudo make install
```

Also there are serveral editor intergration scripts in `editor/`.

## Usage
- Basic: `newf script.sh` (detects `sh` type).
- Executable: `newf +x run.py` (creates an executable Python script).
- Explicit Type: `newf -t c/header include/utils.h` (uses template at `c/header`).
- Extra Templates: `newf -d ~/my-templates notes.md` (searches this dir first).
- Extra Config: `newf -c ~/.config/newf/config.m4 report.tex` (adds m4 macros).
- Dry Run: `newf -o test.js` (outputs the generated content to stdout).

See `man newf` for full documentation.
