augroup createvariable
    autocmd!
    autocmd FileType php
                \ let b:createvariable_prefix = '$' |
                \ let b:createvariable_middle = ' = ' |
                \ let b:createvariable_end = ';'
    autocmd FileType vim
                \ let b:createvariable_prefix = 'let ' |
                \ let b:createvariable_middle = ' = ' |
augroup END

function! s:literal_substitute(expr, pat, sub, flags)
    return substitute(a:expr, escape(a:pat, '\*^.~[]'), a:sub, a:flags)
endfunction

function! s:create_variable(type)
    let saved_unnamed_register = @@
    if a:type ==# 'v'
        normal! `<v`>y
    elseif a:type ==# 'char'
        normal! `[v`]y
    else
        return
    endif
    let rval = @@
    let @@ = saved_unnamed_register
    let prefix = s:get_setting("createvariable_prefix")
    let middle = s:get_setting("createvariable_middle")
    let end = s:get_setting("createvariable_end")
    let indent = matchstr(getline(line('.')), '^\s*')
    " TODO: Rather than have the user input the variable name using input(),
    " have them type the variable name directly into the buffer.
    let var_name = input("Variable Name: ")

    " Create the variable
    call append(line('.')-1, indent . prefix . var_name . middle . rval . end)
    " Replace all occurrences of rval with the created variable where the
    " indent is greater than the current line.
    let line_no = line('.')
    let indent_no = indent('.')
    while indent_no <= indent(line_no)
        let line = getline(line_no)
        call setline(line_no, s:literal_substitute(line, rval, var_name, 'g'))
        let line_no += 1
    endwhile
endfunction

function! s:get_setting(setting)
    return get(b:, a:setting, '')
endfunction

nnoremap <silent> <Plug>Createvariable :<C-u>set operatorfunc=<SID>create_variable<CR>g@
xnoremap <silent> <Plug>Createvariable :<C-u>call <SID>create_variable(visualmode())<CR>
if !hasmapto('<Plug>Createvariable')
    if maparg('yc', 'n') ==# ''
        nmap yc <Plug>Createvariable
    endif
    if maparg('C', 'x') ==# ''
        xmap C <Plug>Createvariable
    endif
endif

