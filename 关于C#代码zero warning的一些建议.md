# 关于C#代码zero warning的一些建议

一般来说，在开发的时候，如果看到了有`warning`尽量先按照提示去解决~

如果有一些是“有意而为之”的情况，可以在代码文件手动suppress掉

```c#
try { ... }
    catch (Exception e)
    {
#pragma warning disable CA2200 // Rethrow to preserve stack details
        throw e;
#pragma warning restore CA2200 // Rethrow to preserve stack details
    }
```



下面是一些常见的`warning`情况

## 1.API调用推荐类型。一般是某些API过时/效率低，这时候会推荐用另一个功能相同的API代替。

> CA1840: Use Environment.CurrentManagedThreadId instead of Thread.CurrentThread.ManagedThreadId
>
> CS0618:A class member was marked with the `Obsolete` attribute

## 2.编写类的一些规范

1. 属性的声明规范。

   - CA1044: Properties should not be write only

     ```c#
     public class BadClassWithWriteOnlyProperty
     {
         string? _someName;
         // Violates rule PropertiesShouldNotBeWriteOnly.
         public string? Name
         {
             set
             {
                 _someName = value;
             }
         }
     }
     public class GoodClassWithReadWriteProperty
     {
         public string? Name { get; set; }
     }
     ```

2. 不要直接声明public字段，最高改为用属性获取

   - CA1051: Do not declare visible instance fields

   > 但是现在项目里也有很多直接用字段的，可以考虑加到全局NoWarn里

3. 当某些字段值为默认值，不需要手动初始化

   - CA1805: Do not initialize unnecessarily

     ```c#
     class C
     {
         // Violation
         int _value1 = 0;
     
         // Fixed
         int _value1;
     }
     ```

4. 静态字段最好要么是常量要么是只读的

   - CA2211: Non-constant fields should not be visible

5. 定义结构体，最好继承IEquatable接口

   - CA1815: Override equals and operator equals on value types

6. 定义枚举，推荐用int32，而非别的，[链接](https://stackoverflow.com/questions/10216910/why-should-i-make-the-underlying-type-of-an-enum-int32-instead-of-byte)

   - CA1028: Enum storage should be Int32

7. 最好用属性，而非字段

   - CA1024: Use properties where appropriate

## 3.一些命名规范

1. 一些前缀声明，接口I开头，泛型T开头等
   - CA1715: Identifiers should have correct prefix
2. 一些后缀声明不应该包含关键字
   - CA1711: Identifiers should not have incorrect suffix
3. 标识符不应该有下划线
   - CA1707: Identifiers should not contain underscores
4. CA1716: Identifiers should not match keywords

3. 当重写了某些接口时，还应当重写相关联的接口

> CA1066: Implement IEquatable when overriding Equals

4. 像集合的`Remove`或者`Add`这种方法调用前，不需要判断`Contains`，可直接利用返回值判断操作是否成功

> CA1868: Unnecessary call to 'Contains' for sets

```c#
void Run(ISet<string> set) { 
	if (!set.Contains("Hello World")){
		set.Add("Hello World");    
	} 
}
```

5. 像有些纯粹的简单带返回值的函数，需要用到返回值才调用

> CA1806: Do not ignore method results

```
self.ShortcutSkillList.Distinct().ToList();
```

6. 如果类的某个成员保证不会访问到实例数据，可以设为静态的

> CA1822: Mark members as static

7. 用异常捕获的时候，尽量`catch`可能的异常

   - CA1031: Do not catch general exception types

   > 不过我们项目一般也都是直接catch(Exception)了，有异常直接打Error然后走失败逻辑。

8. 生命

- 一些小众的，这时候看官方修改建议就好了。如果觉得官方修改建议不合适，那就也可以手动在代码文件里disable掉。

> CA1814: Prefer jagged arrays over multidimensional
>
> CA1003: Use generic event handler instances
>
> CA1869: Cache and reuse 'JsonSerializerOptions' instances
>
> CA1002: Do not expose generic lists
>
> CA2201: Do not raise reserved exception types
>
> CA5394: Do not use insecure randomness
>
> CA1819: Properties should not return arrays
>
> CA2227: Collection properties should be read only