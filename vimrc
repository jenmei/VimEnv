call pathogen#runtime_append_all_bundles()

set nocompatible
set backspace=indent,eol,start 		" allow backspacing over everything in insert mode
set cindent
set incsearch						" do incremental searching
set history=50						" keep 50 lines of command line history
set nobackup
set nowrap
set ruler							" show the cursor position all the time
set scrolloff=2
set shiftwidth=4
set tabstop=4
set showcmd							" display incomplete commands
set ignorecase
set smartcase           			" case sensitive only if search contains uppercase
set guioptions+=b					" horizontal scrolling
set wildmenu 						" :e tab completion file browsing
set wildmode=longest:full 			" make file tab completion act like Bash (full or list)
set cf  							" Enable error files & error jumping.
set laststatus=2  					" Always show status line.
set listchars=tab:>-,trail:.,eol:$
let g:netrw_altv = 1    			" Vsplit right in :Explore mode

set go-=T							"keep MacVim toolbar hidden

"Highlight current line
":set cursorline

" Required for <C-{H,J,K,L}> mappings below
set winminheight=0      " Allow windows to get fully squashed
set winminwidth=0      " Allow windows to get fully squashed
 
" Windows Only
"set backupdir=c:\temp
"set directory=c:\temp
"set viminfo=c:\temp\_viminfo

" Don't use Ex mode, use Q for formatting
map Q gq

" Switch syntax highlighting on, when the terminal has colors
" Also switch on highlighting the last used search pattern.
if &t_Co > 2 || has("gui_running")
  syntax on
  set hlsearch
endif

if has("gui_running")
  set autochdir
endif

" Only do this part when compiled with support for autocommands.
if has("autocmd")
  "Always change to directory of current file
  autocmd BufEnter * lcd %:p:h 

  " Enable file type detection.
  " Use the default filetype settings, so that mail gets 'tw' set to 72,
  " 'cindent' is on in C files, etc.
  " Also load indent files, to automatically do language-dependent indenting.
  filetype plugin indent on

  " Put these in an autocmd group, so that we can delete them easily.
  augroup vimrcEx
  au!

  " For all text files set 'textwidth' to 78 characters.
  autocmd FileType text setlocal textwidth=78

  " When editing a file, always jump to the last known cursor position.
  " Don't do it when the position is invalid or when inside an event handler
  " (happens when dropping a file on gvim).
  autocmd BufReadPost *
    \ if line("'\"") > 0 && line("'\"") <= line("$") |
    \   exe "normal g`\"" |
    \ endif

  augroup END
else
  set autoindent		" always set autoindenting on
endif " has("autocmd")

colorscheme torte
"colorscheme vividchalk
"highlight Normal guibg=Black guifg=White	"Windows, use if no colorscheme


let mapleader=","

"" Switch between windows, maximizing the current window
map <C-J> <C-W>j<C-W>_
map <C-K> <C-W>k<C-W>_
map <C-H> <C-W>h<C-W>\|
map <C-L> <C-W>l<C-W>\|

" Turn hlsearch off/on with CTRL-N
map <silent> <C-N> :se invhlsearch<CR>
" Toggle display of characters for whitespace
map <silent> <leader>s :set nolist!<CR>

map \r	:! %:p<CR>
map \wr :call WriteRun()<CR>
map \jc :call JavaCompile()
map \jr :call JavaRun()
map \fsif :call FormatSQLInsertFields()

"Comment visually selected lines
map <leader># :s/^/#/g<CR>:noh<CR>j
map <leader>/ :s/^/\/\//g<CR>:noh<CR>j

"nmap <F1> :set paste<CR>:r !pbpaste<CR>:set nopaste<CR>
"imap <F1> <Esc>:set paste<CR>:r !pbpaste<CR>:set nopaste<CR>
"map <F2> "+p

" Run rspec 
"nnoremap <leader>t :call Spec()<CR>

nnoremap <leader>t :call RunAllTests('')<cr>:redraw<cr>:call JumpToError()<cr>
nnoremap <leader>T :call RunAllTests('')<cr>
 

function Spec()
	if executable("rspec")
		!rspec %
	else
		!spec %
	endif
endfunction

function WriteRun()
	w | ! %:p
endfunction

function JavaCompile()
	if executable("javac")
		!javac "%"
	else
	endif
endfunction

function JavaRun()
	!java "%:r"
endfunction

function FormatSQLInsertFields()
	g/^$/ d
	1,$-1s/$/,/
	%s/^/\t\t\t/
endfunction


function! RunTests(target, args)
    silent ! echo
    exec 'silent ! echo -e "\033[1;36mRunning tests in ' . a:target . '\033[0m"'
    silent w
    exec "make " . a:target . " " . a:args
endfunction

function! ClassToFilename(class_name)
    let understored_class_name = substitute(a:class_name, '\(.\)\(\u\)', '\1_\U\2', 'g')
    let file_name = substitute(understored_class_name, '\(\u\)', '\L\1', 'g')
    return file_name
endfunction

function! ModuleTestPath()
    let file_path = @%
    let components = split(file_path, '/')
    let path_without_extension = substitute(file_path, '\.rb$', '', '')
    let test_path = 'tests/unit/' . path_without_extension
    return test_path
endfunction

function! NameOfCurrentClass()
    let save_cursor = getpos(".")
    normal $<cr>
    "call RubyDec('class', -1)
    let line = getline('.')
    call setpos('.', save_cursor)
    let match_result = matchlist(line, ' *class \+\(\w\+\)')
    let class_name = ClassToFilename(match_result[1])
    return class_name
endfunction

function! TestFileForCurrentClass()
    let class_name = NameOfCurrentClass()
    let test_file_name = ModuleTestPath() . '/test_' . class_name . '.rb'
    return test_file_name
endfunction

function! TestModuleForCurrentFile()
    let test_path = ModuleTestPath()
    let test_module = substitute(test_path, '/', '.', 'g')
    return test_module
endfunction

function! RunTestsForFile(args)
    if @% =~ 'test_'
        call RunTests('%', a:args)
    else
        let test_file_name = TestModuleForCurrentFile()
        call RunTests(test_file_name, a:args)
    endif
endfunction

function! RunAllTests(args)
    silent ! echo
    silent ! echo -e "\033[1;36mRunning all unit tests\033[0m"
    silent w
    exec "make!" . a:args
endfunction

function! JumpToError()
    if getqflist() != []
        for error in getqflist()
            if error['valid']
                break
            endif
        endfor
        let error_message = substitute(error['text'], '^ *', '', 'g')
        silent cc!
        exec ":sbuffer " . error['bufnr']
        call RedBar()
        echo error_message
    else
        call GreenBar()
        echo "All tests passed"
    endif
endfunction

function! RedBar()
	hi RedBar ctermfg=white ctermbg=red guibg=red
	echohl RedBar
	echon repeat(" ",&columns - 1)
	echohl
endfunction

function! GreenBar()
	hi GreenBar ctermfg=white ctermbg=green guibg=green
	echohl GreenBar
	echon repeat(" ",&columns - 1)
	echohl
endfunction



" Fuzzy Finder Setting Example:
"   let g:FuzzyFinderOptions = { 'Base':{}, 'Buffer':{}, 'File':{}, 'Dir':{}, 'MruFile':{}, 'MruCmd':{}, 'FavFile':{}, 'Tag':{}, 'TaggedFile':{}}
"   let g:FuzzyFinderOptions.Base.ignore_case = 1
"   let g:FuzzyFinderOptions.Base.abbrev_map  = {
"         \   '\C^VR' : [
"         \     '$VIMRUNTIME/**',
"         \     '~/.vim/**',
"         \     '$VIM/.vim/**',
"         \     '$VIM/vimfiles/**',
"         \   ],
"         \ }
"   let g:FuzzyFinderOptions.MruFile.max_item = 200
"   let g:FuzzyFinderOptions.MruCmd.max_item = 200
"   nnoremap <silent> <C-n>      :FuzzyFinderBuffer<CR>
   nnoremap <silent> <C-m>      :FuzzyFinderFile <C-r>=expand('%:~:.')[:-1-len(expand('%:~:.:t'))]<CR><CR>
"   nnoremap <silent> <C-j>      :FuzzyFinderMruFile<CR>
"   nnoremap <silent> <C-k>      :FuzzyFinderMruCmd<CR>
"   nnoremap <silent> <C-p>      :FuzzyFinderDir <C-r>=expand('%:p:~')[:-1-len(expand('%:p:~:t'))]<CR><CR>
"   nnoremap <silent> <C-f><C-d> :FuzzyFinderDir<CR>
"   nnoremap <silent> <C-f><C-f> :FuzzyFinderFavFile<CR>
"   nnoremap <silent> <C-f><C-t> :FuzzyFinderTag!<CR>
"   nnoremap <silent> <C-f><C-g> :FuzzyFinderTaggedFile<CR>
"   noremap  <silent> g]         :FuzzyFinderTag! <C-r>=expand('<cword>')<CR><CR>
"   nnoremap <silent> <C-f>F     :FuzzyFinderAddFavFile<CR>
"   nnoremap <silent> <C-f><C-e> :FuzzyFinderEditInfo<CR>
