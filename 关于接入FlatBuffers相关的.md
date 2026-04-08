# 关于接入FlatBuffers相关的

- 编译`flatc.exe`
- 编译C#的FlatBuffers的`Runtime`

FlatBuffers的`DataFiles`有三种

- 代码输出的raw二进制
- 由flatc --json --raw-binary theater.fbs -- theater.bin --strict-json转换成的json
- 由flatc --binary myschema.fbs mydata.json转换的二进制

二维数组`wrap`导出

## xlsx转程序可读结构

要用到第三方库用来读xlsx

## 导出CS

注意Flatc导出cs代码，会把字段首字母大写，_分割。

比如a_b_c变成了ABC

GameConfigWrapper

UIID

## 导出JSON

`xlsx`转`json`

## FlatBuffers有几类数据类型

- Scalars
  - Structs
- Non-scalars
  - Vectors一维
  - Strings 其实Strings可以认为是特殊的Vectors

## 导出FBS

- 注意二维数组导出
- 注意客户端/服务器区别导出
- 注意注释

对于fbs来说，`byte`是有符号的，`ubyte`是无符号的

对于xlsx来说，`byte`是无符号的

对于`cs`来说，`byte`是无符号的，`sbyte`是有符号的

## 注意bin文件不能进ab包