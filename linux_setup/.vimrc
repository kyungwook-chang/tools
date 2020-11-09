set tabstop=4
set shiftwidth=4
set smartindent
set number
set showcmd
set showmode
set backspace=indent,eol,start
set listchars=extends:>,precedes:<
set enc=utf-8
set tenc=korea
set foldmarker={{{,}}}
set foldmethod=marker
set isfname=@,48-57,/,.,-,_,#,$,%,~,=,{,}
set wrap
colorscheme elflord

syntax enable

if v:lang =~ "utf8$" || v:lang =~ "UTF-8$"
	set fileencodings=utf-8,latim1
endif

set nocompatible
set bs=2
set viminfo='20,\"50

set history=50
set ruler

"set autochdir
"autocmd BufEnter * silent! :lcd%:p:h
"autocmd BufEnter * if expand("%:p:h") !~ '^/tmp' | silent! lcd %:p:h | endif

" if has("autocmd")
" 	autocmd BufRead *.txt set tw=78
" 	autocmd BufReadPost *
" 	\ if line("'\"") > 0 && line ("'\"") <= line("$") |
" 	\ 	exe "normal! g'\"" |
" 	\ endif
" endif

if has("cscope")
	set csprg=/usr/bin/cscope
	set csto=0
	set cst
	set nocsverb
	if filereadable("cscope.out")
		cs add cscope.out
	elseif $CSCOPE_DB != ""
		cs add $CSCOPE_DB
	endif
	set csverb
endif

if &t_Co > 2 || has("gui_running")
	syntax on
	set hlsearch
endif

if &term=="xterm"
	set t_Co=8
	set t_Sb=^[[4%dm
	set t_Sf=^[[3%dm
endif

set path+=/nethome/kchang63/project/design/OpenSPARCT2/
" 
" filetype off
" set rtp+=~/.vim/bundle/Vundle.vim
" call vundle#begin()
" 
" Plugin 'VundleVim/Vundle.vim'
" Plugin 'Valloric/YouCompleteMe'
" 
" call vundle#end()
" filetype plugin indent on
" 
" let g:ycm_global_ycm_extra_conf = '~/.vim/bundle/YouCompleteMe/third_party/ycmd/cpp/ycm/.ycm_extra_conf.py'
" let g:ycm_collect_identifiers_from_tags_file = 1
" set tags+=./tags
" let g:ycm_show_diagnostics_ui = 0

" Keymaps
vmap	<F2>	:'<,'>s/^\([\t ]*\)\([a-zA-Z0-9_]*\),/\1\.\2\t\t\t(\2),/g <CR>
"set tabstop=4
"set expandtab
