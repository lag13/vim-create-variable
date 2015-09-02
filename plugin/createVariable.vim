augroup createvariable
    autocmd!
    autocmd FileType php
                \ let b:createvariable_varprefix = '$' |
                \ let b:createvariable_middle = ' = ' |
                \ let b:createvariable_end = ';'
    autocmd FileType java,c
                \ let b:createvariable_middle = ' = ' |
                \ let b:createvariable_end = ';'
    autocmd FileType vim
                \ let b:createvariable_prefix = 'let ' |
                \ let b:createvariable_middle = ' = ' |
augroup END

function! s:createVariable(type)
    let saved_unnamed_register = @@
    if a:type ==# 'v'
        normal! `<v`>y
    elseif a:type ==# 'char'
        normal! `[v`]y
    else
        return
    endif
    " TODO: What if the user wants tabs instead of spaces? Look into it.
    let prefix = exists("b:createvariable_prefix") ? b:createvariable_prefix : ''
    let var_prefix = exists("b:createvariable_varprefix") ? b:createvariable_varprefix : ''
    let middle = exists("b:createvariable_middle") ? b:createvariable_middle : ''
    let end = exists("b:createvariable_end") ? b:createvariable_end : ''
    let indent = repeat(' ', indent('.'))
    " TODO: Rather than have the user input the variable name using input(),
    " have them type the variable name directly into the buffer.
    let var_name = var_prefix . input("Variable Name: ")

    call append(line('.')-1, indent . prefix . var_name . middle . @@ . end)
    let @@ = var_name
    " TODO: Look into whether this messes up any registers
    normal! gvp
    let @@ = saved_unnamed_register
endfunction

nnoremap cv :set operatorfunc=<SID>createVariable<CR>g@
vnoremap C :<C-U>call <SID>createVariable(visualmode())<CR>

