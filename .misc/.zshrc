# .zshrc
fpath+=$HOME/.zsh/pure
autoload -U promptinit; promptinit
prompt pure
zstyle ':prompt:pure:prompt:success' color green
# Hide username:host
prompt_pure_state[username]=
alias sudo='sudo env PATH=$PATH'