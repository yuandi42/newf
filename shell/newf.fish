# newf(1) fish completion

complete -c newf -e

function __newf_template_dirs
    set -l dirs
    set -l args (commandline -opc)
    if test (count $args) -eq 1
        set args (string split -- ' ' -- $args[1])
    end
    for i in (seq (count $args))
        if test $args[$i] = -d
            set -l j (math $i + 1)
            if test $j -le (count $args)
                set -l d $args[$j]
                test -d "$d"; and set dirs $dirs $d
            end
        end
    end

    if type -q xdg-user-dir
        set -l xdg (xdg-user-dir TEMPLATES 2>/dev/null)
        if test -n "$xdg"; and test -d "$xdg"
            set dirs $dirs $xdg
        end
    else if test -d "$HOME/Templates"
        set dirs $dirs "$HOME/Templates"
    end

    set -l uniq
    for d in $dirs
        if not contains -- $d $uniq
            set uniq $uniq $d
        end
    end
    printf '%s\n' $uniq
end

function __newf_list_templates --argument-names rel prefix_mode
    set -l dirs (__newf_template_dirs)
    set -l outlist
    for d in $dirs
        set -l target $d
        if test -n "$rel"
            set target "$d/$rel"
        end
        if test -d "$target"
            for entry in $target/*
                test -L "$entry"; and continue
                set -l out ""
                if test -d "$entry"
                    set out (basename "$entry")
                    set out "$out/"
                else if test -f "$entry"
                    set out (basename "$entry")
                end
                test -n "$out"; or continue
                if test -n "$rel"
                    set out "$rel/$out"
                end
                if test "$prefix_mode" = "dot"
                    set out "./$out"
                end
                if string match -q '*/' -- $out
                    set -l bare (string replace -r '/$' '' -- $out)
                    set -l idx (contains -i -- $bare $outlist)
                    if test -n "$idx"
                        set -e outlist[$idx]
                    end
                else
                    if contains -- "$out/" $outlist
                        continue
                    end
                end
                if not contains -- $out $outlist
                    set outlist $outlist $out
                end
            end
        end
    end
    printf '%s\n' $outlist
end

function __newf_complete_type
    set -l token (commandline -ct)
    set -l prefix_mode normal
    if string match -qr '^\\./' -- $token
        set prefix_mode dot
        set token (string sub -s 3 -- $token)
    end

    set -l rel (string replace -r '/[^/]*$' '' -- $token)
    if test "$rel" = "$token"
        set rel ""
    end
    set rel (string trim -r -c '/' -- $rel)

    __newf_list_templates "$rel" "$prefix_mode"
end

complete -c newf -s h -d "Show help"
complete -c newf -s v -d "Verbose mode"
complete -c newf -s f -d "Overwrite existing and create directories"
complete -c newf -s o -d "Output to stdout"
complete -c newf -s T -d "Auto-detect filetype"
complete -c newf -s t -r -f -a "(__newf_complete_type)"
complete -c newf -s d -x -a "(__fish_complete_directories)" -d "Add template directory"
complete -c newf -s c -x -a "(__fish_complete_path)" -d "Add config file"
complete -c newf -s x -d "Toggle execute bit"
complete -c newf -s X -d "Unset execute bit"
complete -c newf -f -a '+x' -d "Set execute bit"
