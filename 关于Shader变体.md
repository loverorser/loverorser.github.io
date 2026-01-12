# 关于Shader变体

也在摸索中，简单说一下吧。

大概暴力收集，就是遍历所有收集到的资源，找到他们的材质，然后新建一个空场景，创建若干物体，材质赋给之。

然后调`EditorTools.InvokeNonPublicStaticMethod(typeof(ShaderUtil), "SaveCurrentShaderVariantCollection", savePath);`

Unity那边帮忙进`ShaderVarient`



还一个办法，分开变种收集，也是遍历材质，然后看材质对于的`Shader`是不是分开变种的`Shader`，是的话就把材质用到了的关键词加进去。

然后每个分开变种可以是一个`ShaderVarient`

然后可以加低中高三个变体，把分开变种放进去