# cut

```
语法: cut -b list [-n] [file ...]
       cut -c list [file ...]
       cut -f list [-s] [-d delim] [file ...]
```

#### 使用说明:

cut 命令从文件的每一行剪切字节、字符和字段并将这些字节、字符和字段写至标准输出。

如果不指定 File 参数，cut 命令将读取标准输入。必须指定 -b、-c 或 -f 标志之一。

##### 参数:

```
-b ：以[字节]为单位进行分割。这些字节位置将忽略多字节字符边界，除非也指定了 -n 标志。
-c ：以[字符]为单位进行分割。
-d ：自定义分隔符，默认为制表符。
-f ：与-d一起使用，指定显示哪个区域。
-n ：取消分割多字节字符。仅和 -b 标志一起使用。如果字符的最后一个字节落在由 -b 标志的 List 参数指示的
范围之内，该字符将被写出；否则，该字符将被排除
```

### 例子

```
$ who
michaelxu console  Aug 17 15:44
michaelxu ttys001  Aug 29 08:58
michaelxu ttys002  Aug 29 08:55
michaelxu ttys003  Aug 29 09:13
```

```
$ who | cut -b 3-5
cha
cha
cha
cha
```

### -c 与 -b 的区别

```
$ cat cut_ch.txt
星期一
星期二
星期三
星期四
```

用-c则会以字符为单位，输出正常；而-b只会傻傻的以字节（8位二进制位）来计算，输出就是乱码。

```
$ cut -b 3 cut_ch.txt
�
�
�
�
```

```
$ cut -c 3 cut_ch.txt
一
二
三
四
```

也可以使用-nb来实现中文的输入

```
$ cat cut_ch.txt |cut -nb 8,9
一
二
三
四
```

### 分隔符-d与-f（域）

cut同过-d + 分隔符来将字符串分隔开，然后通过-f 来从这些被分隔开的域中提取数据

> -b 默认是以制表符做分割

```
$ cat /etc/passwd|head -n 5
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/bin:/sbin/nologin
daemon:x:2:2:daemon:/sbin:/sbin/nologin
adm:x:3:4:adm:/var/adm:/sbin/nologin
lp:x:4:7:lp:/var/spool/lpd:/sbin/nologin
```

```
$ cat /etc/passwd|head -n 5|cut -d : -f 1
root
bin
daemon
adm
lp
```

```
$ cat /etc/passwd|head -n 5|cut -d : -f 1,3-5
root:0:0:root
bin:1:1:bin
daemon:2:2:daemon
adm:3:4:adm
lp:4:7:lp
```

```
$ cat /etc/passwd|head -n 5|cut -d : -f 1,3-5,7
root:0:0:root:/bin/bash
bin:1:1:bin:/sbin/nologin
daemon:2:2:daemon:/sbin/nologin
adm:3:4:adm:/sbin/nologin
lp:4:7:lp:/sbin/nologin
```