if type -q fzf_key_bindings
    fzf_key_bindings

    function __my_fzf_file
        fzf-file-widget
        printf '\e[2F'
    end

    function __my_fzf_history
        fzf-history-widget
        printf '\e[2F'
    end

    function __my_fzf_cd
        fzf-cd-widget
        __async_prompt_fire
    end

    bind \ct __my_fzf_file
    bind \cr __my_fzf_history
    bind \ec __my_fzf_cd
end
