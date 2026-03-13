if !executable('newf') | finish | endif

augroup newf_templates
  autocmd!
  autocmd BufNewFile * call s:newf_load()
augroup END

function! s:newf_load() abort
  let l:file = expand('<afile>')
  if empty(l:file) || &buftype !=# '' | return | endif

  silent execute '0read !newf -o' . shellescape(l:file)

  " If newf provided content, the buffer will have more than one line
  " (the original empty line from the new buffer is pushed to the end).
  if line('$') > 1
    $delete _
    1
    setlocal nomodified
  endif
endfunction
