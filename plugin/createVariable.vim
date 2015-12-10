augroup createvariable
    autocmd!
    autocmd FileType php let b:createvariable_prefix = '$'
    autocmd FileType vim let b:createvariable_prefix = 'let '
    autocmd FileType c,cpp,cs,java,javascript,php let b:createvariable_end = ';'
    autocmd FileType sh let b:createvariable_middle = '='
    autocmd FileType c,cpp,java let b:createvariable_remove_var_type = 1
augroup END

function! s:get_setting(setting, default)
    return get(b:, a:setting, get(g:, a:setting, a:default))
endfunction

function! s:literal_substitute(expr, pat, sub, flags)
    return substitute(a:expr, escape(a:pat, '\*^.~[]'), a:sub, a:flags)
endfunction

function! s:remove_var_type(remove_typep, left_assignment, lastp)
    if a:remove_typep
        return matchstr(a:left_assignment, a:lastp ? '^\S*' : '\S*$')
    else
        return a:left_assignment
    endif
endfunction

function! s:get_changed_lines(replace_multiplep, start_line, pat, sub)
    let lines_to_change = getline(a:start_line, s:get_last_line_to_change(a:replace_multiplep, a:start_line))
    return map(lines_to_change, 's:literal_substitute(v:val, a:pat, a:sub, "g")')
endfunction

function! s:get_last_line_to_change(replace_multiplep, start_line)
    if a:replace_multiplep
        let start_indent = indent(a:start_line)
        let line_num = a:start_line + 1
        while start_indent <= indent(line_num)
            let line_num += 1
        endwhile
        return line_num - 1
    else
        return a:start_line
    endif
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

    let prefix = s:get_setting("createvariable_prefix", '')
    let middle = s:get_setting("createvariable_middle", ' = ')
    let end = s:get_setting("createvariable_end", '')
    let replace_multiple = s:get_setting('createvariable_replace_multiple', 0)
    let remove_var_type = s:get_setting('createvariable_remove_var_type', 0)

    " TODO: Rather than have the user input the variable name using input(),
    " have them type the variable name directly into the buffer.
    let assignment = input("Variable Name: ")
    if assignment !=# ''
        let var_name = s:remove_var_type(remove_var_type, assignment, remove_var_type - 1)
        let indent = matchstr(getline(line('.')), '^\s*')
        call append(line('.') - 1, indent . prefix . assignment . middle . rval . end)

        let line_num = line('.')
        let new_lines = s:get_changed_lines(replace_multiple, line_num, rval, var_name)
        call setline(line_num, new_lines)
    endif
endfunction

nnoremap <silent> <Plug>Createvariable :<C-u>set operatorfunc=<SID>create_variable<CR>g@
xnoremap <silent> <Plug>Createvariable :<C-u>call <SID>create_variable(visualmode())<CR>
if !hasmapto('<Plug>Createvariable', 'n')
    if maparg('yc', 'n') ==# ''
        nmap yc <Plug>Createvariable
    endif
endif
if !hasmapto('<Plug>Createvariable', 'v')
    if maparg('C', 'x') ==# ''
        xmap C <Plug>Createvariable
    endif
endif

