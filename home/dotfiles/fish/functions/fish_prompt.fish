
function fish_prompt -d "Write the prompt"
    set last_exit $status
    set -l nix_shell_info (
        if test -n "$IN_NIX_SHELL"
            echo -n "<nix-shell>"
        end
    )

    if test $last_exit -ne 0
       set_color red
       printf "[%s] " $last_exit
       set_color --reset
    end
    printf "%s" $USER 
    set_color blue
    printf "@%s" $hostname
    set_color $fish_color_cwd
    printf " %s" (prompt_pwd)
    if test -n "$IN_NIX_SHELL"
       set_color blue
       printf " <nix-shell>"
    end
    set_color --reset
    printf " > "
end
