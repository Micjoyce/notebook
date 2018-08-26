# ack

github地址[https://github.com/beyondgrep/ack2](https://github.com/beyondgrep/ack2)

文档地址[http://beyondgrep.com/](http://beyondgrep.com/)

## 安装

### mac

`brew install ack`

### linux 

`yum install ack`

> 其他系统可以查看[https://beyondgrep.com/install/](https://beyondgrep.com/install/)安装

## ack 命令 (ack --help)

用法: ack [OPTION]... PATTERN [FILES OR DIRECTORIES]
           参数        正则       文件/目录/描述

从当前目录下的树中的每个源文件中搜索PATTERN。如果指定了任何文件或目录，则仅检查那些文件和目录。ack也可以搜索STDIN，但前提是没有指定文件或目录参数，或者其中一个是“ - ”。

可以在ACK_OPTIONS环境变量或.ackrc文件中指定默认开关。如果您不想依赖环境，请使用--noenv将其关闭。

### 示例：ack -i select

### 搜索:

  -i, --ignore-case             忽略PATTERN中的大小写区别
  
  --[no]smart-case              忽略PATTERN中的大小写区别，
                                仅当PATTERN不包含大写。
                                如果指定了-i，则忽略

  -v, --invert-match            反向匹配：选择不匹配的行

  -w, --word-regexp             强制PATTERN仅匹配整个单词

  -Q, --literal                 引用所有元字符; PATTERN是字面意思
  
### 搜索输出:

  --lines=NUM                   仅打印每个文件的NUM个

  -l, --files-with-matches      仅打印包含匹配项的文件名

  -L, --files-without-matches   仅打印没有匹配项的文件名

  --output=expr                 输出每行的expr的求值（关闭文本高亮显示）

  -o                            仅显示与PATTERN匹配的行的部分与
                                --output ='$＆'相同

  --passthru                    打印所有行，无论是否匹配

  --match PATTERN               PATTERN显式指定PATTERN

  -m, --max-count=NUM           在NUM匹配后停止在每个文件中搜索

  -1                            在任何类型的一场比赛后停止搜索

  -H, --with-filename           打印每个匹配的文件名
                                （默认值：on，除非明确搜索单个文件）

  -h, --no-filename             禁止输出前缀文件名

  -c, --count                   显示每个文件匹配的行数

  --[no]column                  列显示第一个匹配的列号

  -A NUM, --after-context=NUM   在匹配行之后打印NUM行尾随上下文

  -B NUM, --before-context=NUM  在匹配行之前打印NUM行前导上下文

  -C [NUM], --context[=NUM]     打印输出上下文的NUM行（默认为2）

  --print0                      打印空字节作为文件名之间的分隔符
                                仅适用于-f，-g，-l，-L或-c

  -s                            禁止有关不存在或不可读文件的错误消息

### 文件显示:

  --pager=COMMAND               通过COMMAND管道所有ack输出。
                                例如， - pager =“less -R”。
                                如果重定向输出，则忽略

  --nopager                     不要通过寻呼机发送输出。
                                取消〜/ .ackrc，ACK_PAGER或ACK_PAGER_COLOR中的任何设置

  --[no]heading                 在每个文件的结果上方打印文件名
                                （默认：交互使用时打开）

  --[no]break                   在不同文件的结果之间打印中断
                                （默认：交互使用时打开）

  --group                       与--heading --break相同

  --nogroup                     与--noheading --nobreak相同

  --[no]color                   color突出显示匹配的文本
                                （默认值：on，除非重定向输出，或在Windows上）

  --[no]colour                  颜色与 - [no]颜色相同

  --color-filename=COLOR

  --color-match=COLOR

  --color-lineno=COLOR          设置文件名，匹配项和行号的颜色

  --flush                       立即刷新输出，即使非交互式使用ack（当输出到管道或文件时）

### 文件查找:

  -f                            仅打印所选文件，无需搜索。不得指定PATTERN

  -g                            与-f相同，但仅选择与PATTERN匹配的文件

  --sort-files                  在词法上对找到的文件进行排序

  --show-types                  显示每个文件的类型

  --files-from=FILE             读取要从FILE中搜索的文件列表

  -x                            读取要从STDIN搜索的文件列表

### 文件包含/排除:

  --[no]ignore-dir=name         从被忽略的目录列表中添加/删除目录

  --[no]ignore-directory=name   与 ignore-dir 相同

  --ignore-file=filter          添加忽略的过滤器files

  -r, -R, --recurse             递归查找 (默认: on)

  -n, --no-recurse              不递归查找子目录

  --[no]follow                  Follow symlinks.  Default is off.

  -k, --known-types             仅包括ack识别的类型的文件

  --type=X                      仅包含X个文件，其中X是可识别的文件类型

  --type=noX                    排除X文件。有关支持的文件类型，请参阅“ack --help-types”

### 文件类型规范:

  --type-set TYPE:FILTER:FILTERARGS
                                应用于给定FILTER的给定FILTERARGS的文件被识别为TYPE类型。这将替换类型TYPE的现有定义.

  --type-add TYPE:FILTER:FILTERARGS
                                将给定FILTERARGS应用于给定FILTER的文件识别为TYPE类型

  --type-del TYPE               删除与TYPE关联的所有过滤器

### 其他:
  --[no]env                     忽略环境变量和全局ackrc文件
                                --env合法但多余

  --ackrc=filename              指定要使用的ackrc文件

  --ignore-ack-defaults         忽略ack中包含的默认定义

  --create-ackrc                将自定义的默认ackrc输出到标准输出

  --help, -?                    帮助

  --help-types                  显示所有已知类型

  --dump                        转储从哪些RC文件加载选项的信息

  --[no]filter                  filter强制ack将标准输入视为管道（--filter
                                或tty（--nofilter）
                                
  --man                         Man 页面
  
  --version                     显示版本和版权
  
  --thpppt                      Bill the Cat
  
  --bar                         The warning admiral
  
  --cathy                       Chocolate! Chocolate! Chocolate!
  