# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi

# TAB cycles completions instead of asking for more input
bind TAB:menu-complete
