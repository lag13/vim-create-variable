" createvariable.vim - Store selected text in a variable
" Author: Lucas Groenendaal <groenendaal92@gmail.com>

if exists("g:loaded_createvariable") || &cp || v:version < 700
  finish
endif
let g:loaded_createvariable = 1

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

function! s:get_rval(type, visual)
    let saved_unnamed_register = @@
    if a:type ==# 'v'
        normal! `<v`>y
    elseif a:type ==# 'char'
        normal! `[v`]y
    else
        let start = line("'" . (a:visual ? '<' : '['))
        let end = line("'" . (a:visual ? '>' : ']'))
        let @@ = substitute(join(getline(start, end), "\n"), '^\s*', '', '')
    endif
    let rval = @@
    let @@ = saved_unnamed_register
    return split(rval, "\n")
endfunction

" In some languages you have to specify a type when creating a variable. This
" function aims to remove the type and just return the variable name.
function! s:remove_var_type(remove_typep, left_assignment, lastp)
    if a:remove_typep
        return matchstr(a:left_assignment, a:lastp ? '^\S*' : '\S*$')
    else
        return a:left_assignment
    endif
endfunction

function! s:build_assignment(indent, prefix, left_side, middle, rval, end)
    let rval = copy(a:rval)
    let rval[0] = a:indent . a:prefix . a:left_side . a:middle . rval[0]
    let rval[len(rval)-1] .= a:end
    return rval
endfunction

function! s:find_last_line_to_change(replace_multiplep, start_line)
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

function! s:create_variable(type, ...)
    let prefix = s:get_setting("createvariable_prefix", '')
    let middle = s:get_setting("createvariable_middle", ' = ')
    let end = s:get_setting("createvariable_end", '')
    let replace_multiple = s:get_setting('createvariable_replace_multiple', 0)
    let remove_var_type = s:get_setting('createvariable_remove_var_type', 0)

    let rval = s:get_rval(a:type, a:0)
    " TODO: Rather than have the user input the variable name using input(),
    " consider letting them type the variable name directly into the buffer.
    let left_side = input("Variable Name: ")
    if left_side !=# ''
        " Create variable assignment
        let lval = s:remove_var_type(remove_var_type, left_side, remove_var_type - 1)
        let indent = matchstr(getline(line('.')), '^\s*')
        let assignment = s:build_assignment(indent, prefix, left_side, middle, rval, end)
        call append(line('.') - 1, assignment)

        " Replace rval with the variable name
        let start_line = line('.')
        let end_line = s:find_last_line_to_change(replace_multiple, start_line)
        let rval_str = substitute(escape(join(rval, "\n"), '/\'), '\n', '\\n', 'g')
        execute start_line.','.end_line.'substitute/\V'.rval_str.'/'.lval.'/g'
    endif
endfunction

nnoremap <silent> <Plug>Createvariable :<C-u>set operatorfunc=<SID>create_variable<CR>g@
xnoremap <silent> <Plug>Createvariable :<C-u>call <SID>create_variable(visualmode(), 1)<CR>
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

