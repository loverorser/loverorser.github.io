# 关于AssetBundle

`UnityEditor.Editor.finishedDefaultHeaderGUI += OnPostHeaderGUI;`

看AB包不下N次了，常看常新，<del>常看常忘</del>，随便写写

老规矩，先走官方文档，这篇写的还可以

[高级教程](https://learn.unity.com/tutorial/assets-resources-and-assetbundles#)

[垃圾整合](http://www.manongjc.com/detail/52-fuioapmdrxstygx.html)

这里先不管`Resources`，讲烂了的东西，要么别用要么放点小东西



主要是现在Unity出了个新管线叫`Scriptable Build Pipeline`[这里](https://docs.unity3d.com/Packages/com.unity.scriptablebuildpipeline@2.0/manual/index.html)，说是建议用这个，emm，建议用

然后`YooAsset`是用的`SBP`

其实其他的都无所谓，最主要的是处理依赖，依赖主要是

# 打包时候

打包方式只有最适合的，没有【最好】的。

如果是纯的每个文件打个包，那【应该】不会有资源冗余，但是会有十几万个？AB小包，这样每次开个文件打开缓存，IO要爆炸；要么集合成AXP，后话

如果是收集某个打个打包，也OK吧？

> 感觉最好是根据使用频率来打包？
>
> 比如公共图集打一个
>
> 新手场景会用得到的一些可以打在一起？
>
> 关键是在某段时间内，打开的Bundle个数控制一下
>
> 这个strategy值得慢慢研究

# 加载时候

加载的时候顺便把所有依赖的Bundle也加载，没啥讲的

# 卸载时候

一般提供一个`ClearAll`接口，用来卸载没用的资源，*至少YooAsset是这样？*

就是看引用，某个引用<=0就可以干掉？

`AssetOperationHandle`，里面有`Provider`

`ProviderBase`，里面有对应的Asset

`BundledProvider`，里面有`BundleLoaderBase`

`BundleLoaderBase`，里面有`AssetBundle`，还有List<Provider>

`OperationHandleBase`

