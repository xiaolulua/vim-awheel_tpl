let g:tpl_author = "LuYonglei"
let g:tpl_start = "2020"
let g:tpl_limiation = "LUYONGLEI"
let g:tpl_mail = "yonglei_lu@163.com"
"下面两个全局变量用来控制头文件的更新
let g:tpl_magic_header="Awheel_magic"
"1为打开头文件更新(即当头文件名改变时,头文件中ifndef 后面的宏会跟着改变)
let g:tpl_magic_header_en = 1


let s:header_2be_replaced="_#HEADER#_H"

function! s:LoadTemplate()
	"获取文件扩展名
	let l:extension=expand("%:e")
	"查找扩展名所对应的模板文件
	let l:template=expand("~/.vim/tpl/".l:extension.".tpl")
	"判断对应模板文件是否存在
	if !filereadable(l:template)
		echohl Warningmsg | echo "No template".l:template." for '".l:extension."' !" | echohl None
		return
	endif
	"将模板文件的内容读入到缓冲区的第0行
	silent execute "0r ".l:template
	"进行模板替换
	silent execute "1,$s/#START#/".g:tpl_start."/e"
	silent execute "1,$s/#LIMITATION#/".g:tpl_limiation."/e"
	silent execute "1,$s/#AUTHOR#/".g:tpl_author."/g"
	silent execute "1,$s/#MAIL#/".g:tpl_mail."/g"
	silent execute "1,$s/#YEAR#/".strftime("%Y")."/e"
	silent execute "1,$s/#DATE#/".strftime("%Y-%m-%d %T",localtime())."/g"
	silent execute "1,$s/#FILENAME#/".expand("%:t")."/g"

	"设置C或C++中头文件的HEADER信息
	if l:extension == "h" || l:extension == "hpp"
		let l:current_index = system("basename $PWD")
		if g:tpl_magic_header_en != 1
			let l:replacement="_".toupper(l:current_index[0:strlen(l:current_index)-2]).toupper("_".expand("%:t:r"))."_H"
			silent execute "1,$s/".s:header_2be_replaced."/".l:replacement."/g"
		else
			let l:replacement="_".toupper(g:tpl_magic_header)."_".toupper(l:current_index[0:strlen(l:current_index)-2]).toupper("_".expand("%:t:r"))."_H"
			silent execute "1,$s/".s:header_2be_replaced."/".l:replacement."/g"
		endif
	endif

	"跳转到指定光标位置
	"先跳转到文件尾
	silent execute "normal G$"
	"搜索指定的光标位置,从文件尾部向文件头部搜索,光标停在第一个符合条件的串的首字母处
	silent call search("#CURSOR#","w")
	"删除光标右边8个字符
	silent execute "normal 8x"
	"开启插入模式
	startinsert
endfunction


function! s:LastModified()
	normal mt
	silent execute "1,15s/Last Modified:.*/Last Modified: ".strftime("%Y-%m-%d %T",localtime())."/e"
	
	"获取文件扩展名,判断是否是.h或者.hpp文件
	let l:extension = expand("%:e")
	if l:extension == "h" || l:extension == "hpp"
	"控制头文件的ifndef宏是否跟随头文件名变化而变化
		if g:tpl_magic_header_en == 1
			let l:current_index = system("basename $PWD")
			let l:will_be_replaced_pattern="_".toupper(g:tpl_magic_header)."_.*_H$"
			let l:replacement="_".toupper(g:tpl_magic_header)."_".toupper(l:current_index[0:strlen(l:current_index)-2]).toupper("_".expand("%:t:r"))."_H"
			silent execute "1,$s/".l:will_be_replaced_pattern."/".l:replacement."/e"
		endif
	endif

	silent execute "1,15s/FileName:.*/FileName: ".expand("%:t")."/e"
	normal `t

endfunction

"把执行权限赋予给文件,由autocmd调用
function! s:ExecuteRight()
	let l:command ="chmod +x ".expand("%:p")
	let l:temp=system(l:command)
endfunction


"当新创建和模式串匹配的文件时,会自动加载模板文件
"推荐使用文件链接将.h和.hpp链接到一起
"将.mk和Makefile链接到一起

"创建一个符合模式串的新文件时,自动加载模板文件内容
autocmd BufNewFile *.[ch],*.hpp,*.cpp,*.sh,*.py,*.mk,Makefile call s:LoadTemplate()

"开始把整个缓冲区写回到文件,开始把缓冲区部分内容写回到文件,会更新文件头部信息
autocmd BufWritePre,FileWritePre *.[ch],*.hpp,*.cpp,*.sh,*.py,*.mk,Makefile call s:LastModified()

"把整个缓冲区写回到文件后,把缓冲区部分内容写回到文件后,会把执行权限赋予符合模式串匹配的文件
autocmd BufWritePost,FileWritePost *.sh,*.py call s:ExecuteRight()


