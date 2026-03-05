# newf

`newf` is a m4-based file creator. It automatically detects filetypes
based on target filenames and populates them using templates from your
`XDG_TEMPLATES_DIR`.


## Installation
Main script and its manual page:
```sh
sudo make install
```

(Optional)
+ `newf.vim`: just manual add it in your VIMPATH. 

## Usage
- Basic: `newf script.sh` (detects `sh` type).
- Executable: `newf +x run.py` (creates an executable Python script).
- Explicit Type: `newf -t c/header include/utils.h` (uses template at `c/header`).
- Dry Run: `newf -o test.js` (outputs the generated content to stdout).

See `man newf` for full documentation.
