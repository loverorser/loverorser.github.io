# 关于TextMeshPro的mark的tag标签的问题

# [<font color=red>太长不看请翻到最后有解决办法</font>](#太长不看)







## First of all，是个坑

[一些讨论](https://forum.unity.com/threads/how-to-set-text-background-color.570751/)

[这里还有一些](https://forum.unity.com/threads/background-behind-text-lines.1095553/)

[这里也有一些](https://forum.unity.com/threads/text-background-color-on-some-letters.454491/)



## 设计师的原话是

> Just to provide more insight on this...
>
> The underline, strikethrough and mark (highlight) geometry is contained in the primary mesh and added after the characters. As such these always render on top / after the characters which is fine for underline and strikethrough but not so good for the mark tag. This is simple the result of the order in which the geometry is created.
>
> When using the <font> tag with forces the creation of a sub mesh object which is render after the parent then the mark tag ends up behind the text which is the desired result.
>
> Having said that, I plan on revising the geometry creation process to make sure the underline and mark are always rendered first / behind the characters and the strikethrough always on top.
>
> I don't have an ETA on this but that is the plan.
>
> ----by Stephan_B



但是根据我的一些测试，总结出的一个结论就是

## 用mark标签的文本的高亮在底部还是在顶部是***不确定***的

我们先new一个新项目，2022.3.4f1

在**Text**中输入

> 前面<mark=#ed9b45>高亮文本</mark>后面

正常情况下是这样的

![image-20231124113103455](C:\Users\lijiaxing_b\Documents\balabala\Photos\image-20231124113103455.png)

这时候的图集是这样的

![image-20231124113243302](C:\Users\lijiaxing_b\Documents\balabala\Photos\image-20231124113243302.png)

但是如果我调整图集大小，让他有多个图集的话

![image-20231124113358589](C:\Users\lijiaxing_b\Documents\balabala\Photos\image-20231124113358589.png)

它就会变成

![image-20231124113435466](C:\Users\lijiaxing_b\Documents\balabala\Photos\image-20231124113435466.png)

哈哈哈哈哈，想不到吧，变成了这般摸样

经过多次测试我发现，只要生成了2个及以上的图集，那么：

- 第一个图集中的字符，被mark标记，标记的颜色将显示在前面
- 第二个及以后图集中的字符，被mark标记，标记的颜色将显示在后面

# FUCK BUG

# 太长不看

有两个解决办法

- 别用mark标签，有坑

- 用mark标签，并且保证我用mark标签的时候背景颜色是在字符后面的，这时候

  - 创建两个一模一样的文本

    ![image-20231124114029491](C:\Users\lijiaxing_b\Documents\balabala\image-20231124114029491.png)

  - 前面的文本用mark标签

    > 前面<mark=#ed9b45>高亮文本</mark>后面

  - 后面的文本不用

    > 前面高亮文本后面

  - 然后就能轻松愉快地保证mark的背景颜色在字符后面啦

    ![image-20231124114107472](C:\Users\lijiaxing_b\Documents\balabala\image-20231124114107472.png)



# 关于Sprite

先新建一个TMP_SpriteAsset，绑定好材质`Material`和图集`Texture`

再生成图集，这个图集只能是一张图，所以不能用`uGUI`的，用`TexturePacker`打包好。

通过Sprite名字和Name就能找到了。

TMP有一个回调TMP_Text.OnSpriteAssetRequest注册，在这里加载图集。
