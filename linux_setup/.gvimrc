" An example for a gvimrc file.
" The commands in this are executed when the GUI is started.
"
" Maintainer:	Bram Moolenaar <Bram@vim.org>
" Last change:	2001 Sep 02
"
" To use it, copy it to
"     for Unix and OS/2:  ~/.gvimrc
"	      for Amiga:  s:.gvimrc
"  for MS-DOS and Win32:  $VIM\_gvimrc
"	    for OpenVMS:  sys$login:.gvimrc

" Make external commands work through a pipe instead of a pseudo-tty
"set noguipty


" set the X11 font to use
" set guifont=-schumacher-clean-medium-r-normal--16-160-75-75-c-80-iso646.1991-irv
" solaris font
" set gfn=-Adobe-Courier-Medium-R-Normal--14-140-75-75-M-90-ISO8859-1
" linux font
set gfn=MiscFixed\ 11
set ts=4
set sw=4 "auto indent tab size

set ch=2		" Make command line two lines high

set mousehide		" Hide the mouse when typing text

set textwidth=0  "no limit of text width, because i use auto indent option and don't want to new line indent

" Make shift-insert work like in Xterm
map <S-Insert> <MiddleMouse>
map! <S-Insert> <MiddleMouse>

" global delete
" :g/pattern/d
" global exclusi delete
" :v/pattern/d

" toggle ignorecase
map <silent> <F8>  :if &ic == 1 <CR>:set noic <CR> :else <CR> :set ic <CR> endif <CR> <CR>

"My replace
map <silent> S ""gP:let @2=@"<CR>de:let @"=@2<CR>
"My inout
map <silent> T i.<ESC>wyw""gPi(<ESC>ea)<ESC>w
"My previous word
map <silent> W cw<C-P><ESC>jb
"toggle minibuf
map <silent> t :TMiniBufExplorer<CR>
"toggle minibuf
map <silent> WW :g/WARNING\[FAILURE\]/d<CR>:g/unexpected value/d<CR>:g/address and control information cannot be mapped to address/d<CR>
"my page down = space
"map <SPACE> <C-F>

"My edit 0
map <silent> HP :8,$s/_ci/_hp_ci/g<CR>:8,$s/_si/_hp_si/g<CR>:8,$s/_mi/_hp_mi/g<CR>:8,$s/remap/remap_hp/g<CR>:8,$s/tzprot/tzprot_hp/g<CR>

" Only do this for Vim version 5.0 and later.
if version >= 500

  " I like highlighting strings inside C comments
  let c_comment_strings=1

  " Switch on syntax highlighting if it wasn't on yet.
  if !exists("syntax_on")
    syntax on
  endif

  " Switch on search pattern highlighting.
  set hlsearch

  " For Win32 version, have "K" lookup the keyword in a help file
  "if has("win32")
  "  let winhelpfile='windows.hlp'
  "  map K :execute "!start winhlp32 -k <cword> " . winhelpfile <CR>
  "endif

  " Set nice colors
  " background for normal text is light grey
  " Text below the last line is darker grey
  " Cursor is green, Cyan when ":lmap" mappings are active
  " Constants are not underlined but have a slightly lighter background
  highlight Normal guibg=black
  highlight Cursor guibg=Green guifg=white
  highlight lCursor guibg=Cyan guifg=NONE
  highlight NonText guibg=grey80
  highlight Constant gui=NONE guibg=grey95
  highlight Special gui=NONE guibg=grey95

  " minibufexpl
  source ~/bin/gvim_plugin/minibufexpl.vim
  
  
  " color sample pack
   source ~/bin/gvim_plugin/color/wombat.vim

  " exclude , to open file in verilog logfile 
  " add { } to recognize ${proj_name}
  set isfname=@,48-57,/,.,-,_,#,$,%,~,=,{,}

  " My highlight
  " highlight mygroup guifg=lightslateblue gui=undercurl guisp=darkslateblue 
  highlight mygroup guifg=slateblue
  match mygroup /mtek\c\|mtek00\c/
  highlight verilogE guifg=Magenta
  2match verilogE /*E\|ERROR\c\|TBD/
  highlight verilogW guifg=Orange
  3match verilogW /*W\|Warning\c/

  "ignore white space in gvimdiff
  set diffopt=filler,iwhite
  
  "When no beep or flash is wanted
  set vb t_vb=

augroup systemverilog
  " Remove all gzip autocommands
  au!
  " System Verilog HDL
  au BufNewFile,BufRead *.sv,*.sva,*.svi setf verilog 

augroup END

augroup verilog
  " Remove all gzip autocommands
  au!
  " System Verilog HDL
  au BufNewFile,BufRead *.v,*.net setf verilog 

augroup END

endif

