#  ____ _____
# |  _ \_   _|  Derek Taylor (DistroTube)
# | | | || |    http://www.youtube.com/c/DistroTube
# | |_| || |    http://www.gitlab.com/dwt1/
# |____/ |_|
#
# My fish config. Not much to see here; just some pretty standard stuff.

### EXPORT ###
set -U fish_user_paths $fish_user_paths $HOME/.local/bin/
set fish_greeting # Supresses fish's intro message
set TERM "xterm-256color" # Sets the terminal type
set EDITOR "emacsclient -t -a ''" # $EDITOR use Emacs in terminal
set VISUAL "emacsclient -c -a emacs" # $VISUAL use Emacs in GUI mode

### SET EITHER DEFAULT EMACS MODE OR VI MODE ###
function fish_user_key_bindings
    fish_default_key_bindings
end
### END OF VI MODE ###

### AUTOCOMPLETE AND HIGHLIGHT COLORS ###
set fish_color_normal brcyan
set fish_color_autosuggestion '#7d7d7d'
set fish_color_command brcyan
set fish_color_error '#ff6c6b'
set fish_color_param brcyan

### SPARK ###
set -g spark_version 1.0.0

complete -xc spark -n __fish_use_subcommand -a --help -d "Show usage help"
complete -xc spark -n __fish_use_subcommand -a --version -d "$spark_version"
complete -xc spark -n __fish_use_subcommand -a --min -d "Minimum range value"
complete -xc spark -n __fish_use_subcommand -a --max -d "Maximum range value"

function spark -d "sparkline generator"
    if isatty
        switch "$argv"
            case {,-}-v{ersion,}
                echo "spark version $spark_version"
            case {,-}-h{elp,}
                echo "usage: spark [--min=<n> --max=<n>] <numbers...>  Draw sparklines"
                echo "examples:"
                echo "       spark 1 2 3 4"
                echo "       seq 100 | sort -R | spark"
                echo "       awk \\\$0=length spark.fish | spark"
            case \*
                echo $argv | spark $argv
        end
        return
    end

    command awk -v FS="[[:space:],]*" -v argv="$argv" '
        BEGIN {
            min = match(argv, /--min=[0-9]+/) ? substr(argv, RSTART + 6, RLENGTH - 6) + 0 : ""
            max = match(argv, /--max=[0-9]+/) ? substr(argv, RSTART + 6, RLENGTH - 6) + 0 : ""
        }
        {
            for (i = j = 1; i <= NF; i++) {
                if ($i ~ /^--/) continue
                if ($i !~ /^-?[0-9]/) data[count + j++] = ""
                else {
                    v = data[count + j++] = int($i)
                    if (max == "" && min == "") max = min = v
                    if (max < v) max = v
                    if (min > v ) min = v
                }
            }
            count += j - 1
        }
        END {
            n = split(min == max && max ? "▅ ▅" : "▁ ▂ ▃ ▄ ▅ ▆ ▇ █", blocks, " ")
            scale = (scale = int(256 * (max - min) / (n - 1))) ? scale : 1
            for (i = 1; i <= count; i++)
                out = out (data[i] == "" ? " " : blocks[idx = int(256 * (data[i] - min) / scale) + 1])
            print out
        }
    '
end
### END OF SPARK ###


### FUNCTIONS ###
# Spark functions
function letters
    cat $argv | awk -vFS='' '{for(i=1;i<=NF;i++){ if($i~/[a-zA-Z]/) { w[tolower($i)]++} } }END{for(i in w) print i,w[i]}' | sort | cut -c 3- | spark | lolcat
    printf '%s\n' 'abcdefghijklmnopqrstuvwxyz' ' ' | lolcat
end

function commits
    git log --author="$argv" --format=format:%ad --date=short | uniq -c | awk '{print $1}' | spark | lolcat
end

# Functions needed for !! and !$
function __history_previous_command
    switch (commandline -t)
        case "!"
            commandline -t $history[1]
            commandline -f repaint
        case "*"
            commandline -i !
    end
end

function __history_previous_command_arguments
    switch (commandline -t)
        case "!"
            commandline -t ""
            commandline -f history-token-search-backward
        case "*"
            commandline -i '$'
    end
end
# The bindings for !! and !$
if [ $fish_key_bindings = fish_vi_key_bindings ]
    bind -Minsert ! __history_previous_command
    bind -Minsert '$' __history_previous_command_arguments
else
    bind ! __history_previous_command
    bind '$' __history_previous_command_arguments
end

# Function for creating a backup file
# ex: backup file.txt
# result: copies file as file.txt.bak
function backup --argument filename
    cp $filename $filename.bak
end

# Function for copying files and directories, even recursively.
# ex: copy DIRNAME LOCATIONS
# result: copies the directory and all of its contents.
function copy
    set count (count $argv | tr -d \n)
    if test "$count" = 2; and test -d "$argv[1]"
        set from (echo $argv[1] | trim-right /)
        set to (echo $argv[2])
        command cp -r $from $to
    else
        command cp $argv
    end
end

# Function for printing a column (splits input on whitespace)
# ex: echo 1 2 3 | coln 3
# output: 3
function coln
    while read -l input
        echo $input | awk '{print $'$argv[1]'}'
    end
end

# Function for printing a row
# ex: seq 3 | rown 3
# output: 3
function rown --argument index
    sed -n "$index p"
end

# Function for ignoring the first 'n' lines
# ex: seq 10 | skip 5
# results: prints everything but the first 5 lines
function skip --argument n
    tail +(math 1 + $n)
end

# Function for taking the first 'n' lines
# ex: seq 10 | take 5
# results: prints only the first 5 lines
function take --argument number
    head -$number
end
### END OF FUNCTIONS ###


### ALIASES and ABBR###
# root privileges
abbr doas "doas --"

abbr --add upA "sudo pacman -Syyu"
# navigation
abbr .. 'cd ..'
abbr ... 'cd ../..'
abbr .3 'cd ../../..'
abbr .4 'cd ../../../..'
abbr .5 'cd ../../../../..'

# broot
abbr br 'broot -dhp'
abbr bs 'broot --sizes'

# Changing "ls" to "exa"
alias ls='exa  --color=always --group-directories-first'
alias la='exa -a --color=always --group-directories-first' # all files and dirs
alias lA='exa -la --color=always --group-directories-first'
alias ll='exa -l --color=always --group-directories-first' # long format
alias lt='exa -aT --color=always --group-directories-first' # tree listing

# pacman and yay
abbr pacsyu 'sudo pacman -Syyu && xmonad --recompile' # update only standard pkgs
abbr yaysua 'yay -Sua --noconfirm' # update only AUR pkgs
abbr yaysyu 'yay -Syu --noconfirm' # update standard pkgs and AUR pkgs
abbr unlock 'sudo rm /var/lib/pacman/db.lck' # remove pacman lock
abbr cleanup 'sudo pacman -Rns (pacman -Qtdq)' # remove orphaned packages

# get fastest mirrors
abbr mirror "sudo reflector -f 30 -l 30 --number 10 --verbose --save /etc/pacman.d/mirrorlist"
abbr mirrord "sudo reflector --latest 50 --number 20 --sort delay --save /etc/pacman.d/mirrorlist"
abbr mirrors "sudo reflector --latest 50 --number 20 --sort score --save /etc/pacman.d/mirrorlist"
abbr mirrora "sudo reflector --latest 50 --number 20 --sort age --save /etc/pacman.d/mirrorlist"

# Colorize grep output (good for log files)
abbr grep 'grep --color=auto'
abbr egrep 'egrep --color=auto'
abbr fgrep 'fgrep --color=auto'

# add verbosity
alias cp="cp -v"
alias mv='mv -v'
alias rm='rm -v'
alias mkdir='mkdir -v'
# adding flags
abbr df 'df -h' # human-readable sizes
abbr free 'free -m' # show sizes in MB
abbr lynx 'lynx -cfg=~/.lynx/lynx.cfg -lss=~/.lynx/lynx.lss -vikeys'
abbr vifm './.config/vifm/scripts/vifmrun'
abbr funced 'funced -s'
## get top process eating memory
abbr psmem 'ps auxf | sort -nr -k 4'
abbr psmem10 'ps auxf | sort -nr -k 4 | head -10'

## get top process eating cpu ##
abbr pscpu 'ps auxf | sort -nr -k 3'
abbr pscpu10 'ps auxf | sort -nr -k 3 | head -10'

# Merge Xresources
abbr merge 'xrdb -merge ~/.Xresources'

# get error messages from journalctl
abbr jctl "journalctl -p 3 -xb"

# gpg encryption
# verify signature for isos
abbr gpg-check "gpg2 --keyserver-options auto-key-retrieve --verify"
# receive the key of a developer
abbr gpg-retrieve "gpg2 --keyserver-options auto-key-retrieve --receive-keys"

# switch between shells
abbr tobash "sudo chsh $USER -s /bin/bash && echo 'Now log out.'"
abbr tozsh "sudo chsh $USER -s /bin/zsh && echo 'Now log out.'"
abbr tofish "sudo chsh $USER -s /bin/fish && echo 'Now log out.'"

# bare git repo abbr for dotfiles
abbr config "git --git-dir=$HOME/.dotfiles --work-tree=$HOME"

# neofetch

pfetch

### SETTING THE STARSHIP PROMPT ###
starship init fish | source
