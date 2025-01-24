# .bashrc

if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

PATH="$HOME/.local/bin:$HOME/bin:$PATH"
export PATH

if [[ -n $SSH_CONNECTION ]]; then
    export EDITOR='vim'
else
    export EDITOR='nvim'
fi

# Functions
ksw() {
    if [[ -n "$1" ]]; then
        kubectl ctx "$1"
    else
        kubectl ctx
    fi
    if [[ -n "$2" ]]; then
        kubectl ns "$2"
    else
        kubectl ns
    fi
}

parse_git_branch() {
    git rev-parse --is-inside-work-tree &>/dev/null || return
    branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
    [ -n "$(git status --porcelain)" ] && state="*" || state=""
    echo "($branch$state)"
}

parse_k8s_context_namespace() {
    if command -v kubectl &>/dev/null; then
        context=$(kubectl config current-context 2>/dev/null)
        namespace=$(kubectl config view --minify -o jsonpath='{.contexts[0].context.namespace}' 2>/dev/null)
        namespace=${namespace:-default}  # Fallback to 'default' if namespace is unset
        echo "$context/$namespace"
    fi
}

export PS1="\n\[\033[38;5;84m\]\u@\h \[\033[38;5;81m\]\$(parse_k8s_context_namespace) \[\033[38;5;213m\]\w \[\033[38;5;203m\]\$(parse_git_branch)\n\[\033[38;5;222m\]→ \[\033[0m\]"

getPodsByNode() {
    kubectl get pods --all-namespaces -o wide --field-selector spec.nodeName=$1
}

# Hacks
eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
source <(kubectl completion bash)
complete -o default -F __start_kubectl k
source /usr/share/fzf/completion.bash
source /usr/share/fzf/key-bindings.bash
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
export SUDO_PROMPT="[⚡on $(cat /etc/hostname) for $USER]:"
export GTK_THEME=Adwaita-dark
# Env
export VAULT_ADDR="https://vault.morrislan.net"
export KCNF_SYMLINK=1
#export HOOP_APIURL=https://hoop.morrislan.net
#export HOOP_GRPCURL=grpcs://hoop-grpc.morrislan.net:443

# Aliases
alias vim=nvim
alias kubectl=kubecolor
alias k=kubectl
alias racadm="docker run -v `pwd`:/mnt xfgavin/racadm"
alias vssh=vault-ssh
alias kgp="k get pods"
alias kgn="k get nodes"
alias kgs="k get services"
alias kga="k get applications"
alias kdp="k delete pods"
alias ceph="k rook-ceph ceph"
alias dot="/usr/bin/git --git-dir=$HOME/.dot.git/ --work-tree=$HOME"
