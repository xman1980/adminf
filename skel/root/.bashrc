# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific aliases and functions

export PS1="\[\033[01;31m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "

alias top='glances'

## place in ~/.bashrc ##
## prevent embarassingly running command on whole server ##
alias chown='chown --preserve-root'
alias chmod='chmod --preserve-root'
alias chgrp='chgrp --preserve-root'

## Interactive confirmation ##
alias mv='mv -i'
alias cp='cp -i'
alias ln='ln -i'

## set defaults for disk usage and disk free ##
alias df='df -H'
alias du='du -ch'

# pass options to free ##
alias meminfo='free -m -l -t'

## get top process eating memory
alias psmem='ps auxf | sort -nr -k 4'
alias psmem10='ps auxf | sort -nr -k 4 | head -10'

## get top process eating cpu ##
alias pscpu='ps auxf | sort -nr -k 3'
alias pscpu10='ps auxf | sort -nr -k 3 | head -10'

## Get server cpu info ##
alias cpuinfo='lscpu'

## older system use /proc/cpuinfo ##
##alias cpuinfo='less /proc/cpuinfo' ##

## Resume wget by default ##
alias wget='wget -c'

## Show open Ports ##
alias ports='netstat -tulanp'

## Create parent directories on demand ##
alias mkdir='mkdir -pv'

## Colorize the grep command output for ease of use (good for log files)##
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

## get rid of command not found ##
alias cd..='cd ..'

## a quick way to get out of current directory ##
alias ..='cd ..'
alias ...='cd ../../../'
alias ....='cd ../../../../'
alias .....='cd ../../../../'
alias .4='cd ../../../../'
alias .5='cd ../../../../..'

## Colorize the ls output ##
alias ls='ls --color=auto'
#Now to protect yourself from the rm command:


## Safe interactive shell confirmation for file deletion ##
## Place in  nano -w /root/.bash_profile ##
if [ -n "$PS1" ] ; then
  rm ()
  {
      ls -FCsd "$@"
      echo 'remove[ny]? ' | tr -d '\012' ; read
      if [ "_$REPLY" = "_y" ]; then
          /bin/rm -rf "$@"
      else
          echo '(cancelled)'
      fi
  }
fi

if [[ -n $SSH_TTY ]]
then
    # Do stuff to get the output.
    echo ""
    echo ""
    echo "#########################################################################"
    echo "# Please login as your team or personal user rather than the user root  #"
    echo "#########################################################################"
    echo ""
    echo ""
fi
