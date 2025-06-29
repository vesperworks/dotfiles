" 📁 Markdown folding設定
" このファイルはmarkdownファイルを開く度に自動実行される

" 標準のmarkdown folding機能を有効化
if !exists('g:markdown_folding')
  let g:markdown_folding = 1
endif

" foldingメソッドをexprに設定（標準のmarkdown foldingはexprを使用）
setlocal foldmethod=expr
setlocal foldexpr=MarkdownFold()
setlocal foldtext=MarkdownFoldText()

" 見出しレベル1で開始（すべて開いた状態）
setlocal foldlevelstart=1

" 左端にfold状態表示カラムを追加
setlocal foldcolumn=1

" ネストの深さ制限
setlocal foldnestmax=6
