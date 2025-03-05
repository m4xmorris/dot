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
    # Fetch Teleport clusters
    if command -v tsh &>/dev/null; then
        tsh_clusters=$(tsh kube ls --format=json | jq -r 'map(.kube_cluster_name) | join("\n")' 2>/dev/null)
    fi

    # Fetch all contexts from kubeconfig, excluding Teleport ones
    kubecontexts=$(kubectl config get-contexts -o name | grep -vFf <(echo "$tsh_clusters"))

    # Combine both lists for fzf selection
    cluster=$(echo -e "$tsh_clusters\n$kubecontexts" | fzf --prompt="Select a cluster: " --height=10 --reverse)

    if [[ -z "$cluster" ]]; then
        echo "No cluster selected."
        return 1
    fi

    # Check if selected cluster is a Teleport cluster
    if echo "$tsh_clusters" | grep -qx "$cluster"; then
        tsh kube login "$cluster" >/dev/null
    elif kubectl config get-contexts "$cluster" &>/dev/null; then
        export KUBECONFIG="$HOME/.kube/config"
        kubectl config use-context "$cluster" > /dev/null
    else
        return 1
    fi

    # Select namespace using fzf
    namespace=$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}' 2>/dev/null | tr " " "\n" | fzf --prompt="Select a namespace: " --height=10 --reverse)
    namespace=${namespace:-default} # Fallback to 'default' if none selected

    kubectl config set-context --current --namespace="$namespace" > /dev/null
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
export GEM_HOME="$(gem env user_gemhome)"
export PATH="$PATH:$GEM_HOME/bin"
export SUDO_PROMPT="[⚡on $(cat /etc/hostname) for $USER]:"
export GTK_THEME=Adwaita-dark

# Env
export KCNF_SYMLINK=1
export PKG_CONFIG_PATH=/usr/lib/pkgconfig
export TELEPORT_PROXY="https://teleport.morrislan.net"
eval "$(tsh --completion-script-bash)"

# Aliases
alias vim=nvim
alias kubectl=kubecolor
alias k=kubectl
alias racadm="docker run -v `pwd`:/mnt xfgavin/racadm"
alias vssh=vault-ssh
alias kgp="kubecolor get pods"
alias kgn="k get nodes"
alias kgs="k get services"
alias kga="k get applications"
alias kdp="k delete pods"
alias ceph="k rook-ceph ceph"
alias dot="/usr/bin/git --git-dir=$HOME/.dot.git/ --work-tree=$HOME"
alias kill-all-mine="pkill -9 -u max"
alias l="ls -al"
