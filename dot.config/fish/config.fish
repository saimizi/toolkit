if status is-interactive
    # Commands to run in interactive sessions can go here

    set LC_ALL      "en_US.UTF-8"
    set LANG        "en_US.UTF-8"
    set LANGUAGE    "en_US:en"

    #	set PATH ~/bin/aarch64-rpi3-linux-gnu/bin $PATH
    set PATH ~/bin $PATH
    #	set PATH ~/x-tools/aarch64-rpi4-linux-gnu/bin $PATH
    set PATH ~/bin/docker-tools/bin $PATH
    set PATH ~/bin/aarch64-appsdk-linux $PATH
    #	set PATH /docker_bin/fzf/bin $PATH
    #    set PATH $HOME/.cargo/bin $PATH
    #	set PATH /opt/xtensa/xtensa-esp32-elf/bin $PATH 
    #	set PATH ~/.local/bin $PATH
    #	set PATH ~/.local/kitty.app/bin $PATH
    #	set PATH ~/.nvm/versions/node/v20.11.1/bin/ $PATH
    #	set NVM_DIR "$HOME/.nvm"

    source ~/.aliases

    #    set CSCOPE_DB   "~/cstags"
    #    set JAVA_HOME   /usr/lib/jvm/java-8-oracle/bin/
    #    set PATH        ~/bin/go/bin $PATH
    #    set GOPATH      ~/go
    #    set GOBIN       ~/bin/go
    #	set WASI_SDK_PATH /home/joukan/wasm_work/wasi-sdk-14.0

    #    set X_TOOLS         /home/joukan/x-tools
    #    set SSTATE_CACHE    /home/joukan/work/sstate-cache
    #    set DOWNLOAD        /home/joukan/work/downloads
    #    set DOCKER_WORKDIR  /env/nwork/env
    #    export DOCKER_PROPRIETARY X_TOOLS SSTATE_CACHE DOWNLOAD DOCKER_WORKDIR

    set INPUT_METHOD    ibus
    set GTK_IM_MODULE   ibus
    set XMODIFIERS      @im=ibus
    set QT_IM_MODULE    ibus

    #set QMAKE   /usr/bin/qmake

    #set XDG_DATA_DIRS $XDG_DATA_DIRS /home/joukan/.local/share/flatpak/exports/share
end

starship init fish | source

# Wasmer
#export WASMER_DIR="/home/joukan/.wasmer"
#[ -s "$WASMER_DIR/wasmer.sh" ] && source "$WASMER_DIR/wasmer.sh"

#set -gx WASMTIME_HOME "$HOME/.wasmtime"

#string match -r ".wasmtime" "$PATH" > /dev/null; or set -gx PATH "$WASMTIME_HOME/bin" $PATH

# Created by `pipx` on 2024-12-21 04:17:00
set PATH $PATH /home/joukan/.local/bin
