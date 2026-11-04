" General mapping
noremap i k
noremap j h
noremap k j
noremap h a
noremap a i

noremap I K
noremap J H
noremap K J
noremap H A
noremap A I

" Normal Mode mapping
nnoremap I kJ

nnoremap <S-Enter> o<Esc>
nnoremap <Enter> o<Esc>
"nnoremap <BS> "_i<BS><Esc>`^
nnoremap <BS> "_h<Delete>
nnoremap <S-End> V$
nnoremap <S-Home> v^

nnoremap <C-Up> 3<C-Y>M$
nnoremap <C-Down> 3<C-E>M$
nnoremap <S-Up> <C-u>M$
nnoremap <S-Down> <C-d>M$
nnoremap <C-i> 3<C-Y>M$
nnoremap <C-k> 3<C-E>M$
nnoremap <C-j> 2B
nnoremap <C-l> 2W
nnoremap <C-u> <S-Up>M$
nnoremap <C-d> <S-Down>M$

nnoremap x "_x
nnoremap $ ^
nnoremap ^ $
nnoremap <S-Left> vB
nnoremap <S-Right> vW
nnoremap # #:set hlsearch<CR>
nnoremap <Esc> :set nohlsearch<CR><Esc>

" Visual Mode mapping
vnoremap I kJ

vnoremap <BS> "_x

vnoremap <S-Up> <C-u>
vnoremap <S-Down> <C-d>
vnoremap <C-u> <S-Up>
vnoremap <C-d> <S-Down>
vnoremap <C-i> 3<C-Y>M$
vnoremap <C-k> 3<C-E>M$
vnoremap <C-j> 2B
vnoremap <C-l> 2W
vnoremap $ ^
vnoremap ^ $
vnoremap p "_dP


" Visual Mode: Indent and restore selection
vnoremap <silent> > :<C-u>execute "normal! gv>gv"<CR>
vnoremap <silent> < :<C-u>execute "normal! gv<gv"<CR>

" Insert Mode
inoremap <S-Up> <Esc><C-u>M$
inoremap <S-Down> <Esc><C-d>M$
inoremap <C-Up> <Esc>2<C-Y>M$
inoremap <C-Down> <Esc>2<C-E>M$
