let s:cpo_save=&cpo
set cpo&vim
inoremap <C-W> u
inoremap <C-U> u
nnoremap  <Cmd>nohlsearch|diffupdate|normal! 
nmap  d
omap <silent> % <Plug>(MatchitOperationForward)
xmap <silent> % <Plug>(MatchitVisualForward)
nmap <silent> % <Plug>(MatchitNormalForward)
nnoremap & :&&
xnoremap <silent> <expr> @ mode() ==# 'V' ? ':normal! @'.getcharstr().'' : '@'
xnoremap <silent> <expr> Q mode() ==# 'V' ? ':normal! @=reg_recorded()' : 'Q'
nnoremap Y y$
omap <silent> [% <Plug>(MatchitOperationMultiBackward)
xmap <silent> [% <Plug>(MatchitVisualMultiBackward)
nmap <silent> [% <Plug>(MatchitNormalMultiBackward)
omap <silent> ]% <Plug>(MatchitOperationMultiForward)
xmap <silent> ]% <Plug>(MatchitVisualMultiForward)
nmap <silent> ]% <Plug>(MatchitNormalMultiForward)
xmap a% <Plug>(MatchitVisualTextObject)
omap <silent> g% <Plug>(MatchitOperationBackward)
xmap <silent> g% <Plug>(MatchitVisualBackward)
nmap <silent> g% <Plug>(MatchitNormalBackward)
xmap <silent> <Plug>(MatchitVisualTextObject) <Plug>(MatchitVisualMultiBackward)o<Plug>(MatchitVisualMultiForward)
onoremap <silent> <Plug>(MatchitOperationMultiForward) :call matchit#MultiMatch("W",  "o")
onoremap <silent> <Plug>(MatchitOperationMultiBackward) :call matchit#MultiMatch("bW", "o")
xnoremap <silent> <Plug>(MatchitVisualMultiForward) :call matchit#MultiMatch("W",  "n")m'gv``
xnoremap <silent> <Plug>(MatchitVisualMultiBackward) :call matchit#MultiMatch("bW", "n")m'gv``
nnoremap <silent> <Plug>(MatchitNormalMultiForward) :call matchit#MultiMatch("W",  "n")
nnoremap <silent> <Plug>(MatchitNormalMultiBackward) :call matchit#MultiMatch("bW", "n")
onoremap <silent> <Plug>(MatchitOperationBackward) :call matchit#Match_wrapper('',0,'o')
onoremap <silent> <Plug>(MatchitOperationForward) :call matchit#Match_wrapper('',1,'o')
xnoremap <silent> <Plug>(MatchitVisualBackward) :call matchit#Match_wrapper('',0,'v')m'gv``
xnoremap <silent> <Plug>(MatchitVisualForward) :call matchit#Match_wrapper('',1,'v'):if col("''") != col("$") | exe ":normal! m'" | endifgv``
nnoremap <silent> <Plug>(MatchitNormalBackward) :call matchit#Match_wrapper('',0,'n')
nnoremap <silent> <Plug>(MatchitNormalForward) :call matchit#Match_wrapper('',1,'n')
nmap <C-W><C-D> d
nnoremap <C-L> <Cmd>nohlsearch|diffupdate|normal! 
inoremap  u
inoremap  u
let &cpo=s:cpo_save
unlet s:cpo_save
set background=light
set grepformat=%f:%l:%c:%m
set grepprg=rg\ --vimgrep\ -uu\ 
set helplang=es
set runtimepath=~/.config/nvim,/nix/store/1nzyb902p2zn518lzw02jp42cylcmym4-stylix-kde-config/nvim,/etc/xdg/nvim,~/.nix-profile/etc/xdg/nvim,/nix/profile/etc/xdg/nvim,~/.local/state/nix/profile/etc/xdg/nvim,/etc/profiles/per-user/pau/etc/xdg/nvim,/nix/var/nix/profiles/default/etc/xdg/nvim,/run/current-system/sw/etc/xdg/nvim,~/.local/share/nvim/site,~/.local/share/nvim/site/pack/*/start/*,/nix/store/444h3sfs9fk7fi8hif6wgg11rkc24vjd-ghostty-1.3.1/share/nvim/site,/nix/store/w7z6y1f2gnm6qx8gpkxzvbnxsw3b3svl-gsettings-desktop-schemas-50.1/share/gsettings-schemas/gsettings-desktop-schemas-50.1/nvim/site,/nix/store/4j905cjgk8idkzg4szhyryzjx2q1b6br-gtk4-4.22.4/share/gsettings-schemas/gtk4-4.22.4/nvim/site,/nix/store/9h9bx189i9ndzqgw531znv8kwj1kadn7-swayfx-0.6/share/nvim/site,/nix/store/fl089m700c7zxqwgly18jyx0fs4lgbbj-gtk+3-3.24.52/share/gsettings-schemas/gtk+3-3.24.52/nvim/site,/nix/store/y6z5s95kp8v4ailqsgas65kchxdy6y9i-desktops/share/nvim/site,~/.nix-profile/share/nvim/site,/nix/profile/share/nvim/site,~/.local/state/nix/profile/share/nvim/site,/etc/profiles/per-user/pau/share/nvim/site,/nix/var/nix/profiles/default/share/nvim/site,/run/current-system/sw/share/nvim/site,/nix/store/hb1s8775166cqfcvn3z4znlzd13lrjj9-neovim-unwrapped-0.12.5/share/nvim/runtime,/nix/store/hb1s8775166cqfcvn3z4znlzd13lrjj9-neovim-unwrapped-0.12.5/share/nvim/runtime/pack/dist/opt/netrw,/nix/store/hb1s8775166cqfcvn3z4znlzd13lrjj9-neovim-unwrapped-0.12.5/share/nvim/runtime/pack/dist/opt/matchit,/nix/store/hb1s8775166cqfcvn3z4znlzd13lrjj9-neovim-unwrapped-0.12.5/lib/nvim,/run/current-system/sw/share/nvim/site/after,/nix/var/nix/profiles/default/share/nvim/site/after,/etc/profiles/per-user/pau/share/nvim/site/after,~/.local/state/nix/profile/share/nvim/site/after,/nix/profile/share/nvim/site/after,~/.nix-profile/share/nvim/site/after,/nix/store/y6z5s95kp8v4ailqsgas65kchxdy6y9i-desktops/share/nvim/site/after,/nix/store/fl089m700c7zxqwgly18jyx0fs4lgbbj-gtk+3-3.24.52/share/gsettings-schemas/gtk+3-3.24.52/nvim/site/after,/nix/store/9h9bx189i9ndzqgw531znv8kwj1kadn7-swayfx-0.6/share/nvim/site/after,/nix/store/4j905cjgk8idkzg4szhyryzjx2q1b6br-gtk4-4.22.4/share/gsettings-schemas/gtk4-4.22.4/nvim/site/after,/nix/store/w7z6y1f2gnm6qx8gpkxzvbnxsw3b3svl-gsettings-desktop-schemas-50.1/share/gsettings-schemas/gsettings-desktop-schemas-50.1/nvim/site/after,/nix/store/444h3sfs9fk7fi8hif6wgg11rkc24vjd-ghostty-1.3.1/share/nvim/site/after,~/.local/share/nvim/site/after,/run/current-system/sw/etc/xdg/nvim/after,/nix/var/nix/profiles/default/etc/xdg/nvim/after,/etc/profiles/per-user/pau/etc/xdg/nvim/after,~/.local/state/nix/profile/etc/xdg/nvim/after,/nix/profile/etc/xdg/nvim/after,~/.nix-profile/etc/xdg/nvim/after,/etc/xdg/nvim/after,/nix/store/1nzyb902p2zn518lzw02jp42cylcmym4-stylix-kde-config/nvim/after,~/.config/nvim/after
set termguicolors
set window=32
" vim: set ft=vim :
