# 关于安卓SDK

## 安卓往Unity发消息

```java
UnityPlayer.UnitySendMessage("UnityReceiver", "ReceiveMessageFromAndroid", message);
```

`UnityReceiver`是场景中的一个`GameObject`的名字

`ReceiveMessageFromAndroid`是这个`GameObject`挂载的`MonoBehaviour`的一个`public`方法，方法接收`string`参数，`message`是一个字符串

> 其实就类似Unity的`SendMessage`方法

双端交互数据通过`string`传，可以自定义协议，`JSON`之类，效率也还行。



## Unity往安卓发消息

用`AndroidJavaClass`的`CallStatic`或者`Call`方法。

如果要返回值，能和java的对上。



## Android环境搭建

- 安装`AndroidStudio`，拿2024.3.2举例子

- new一个project，选`EmptyViewsActivity`，语言选`Java`，名字比如`UnityAndroidTest`，点finish。

- 左上角找到`Android`，切换成`Project`，右键new一个`Module`，选`AndroidLibrary`，名字比如叫`mylibrary`。

- 我们需要一个桥梁来为Unity和Android通信，桥梁就是classes.jar，位于Unity安装目录下。但是如果我们直接把这个jar复制到lib目录下，打包就会出错，因为Unity自己也带这个jar文件，重复。于是我们只是添加编译时依赖，并不复制。找到`build.gradle.kts`文件，在`dependencies`栏目下新增一列

- > ```
  > compileOnly(files("G:\\Program Files\\Unity\\Hub\\Editor\\6000.1.2f1\\Editor\\Data\\PlaybackEngines\\AndroidPlayer\\Variations\\il2cpp\\Development\\Classes\\classes.jar"))
  > ```

- 在`mylibrary`新建一个类，写测试代码

```java
package com.example.mylibrary;
import com.unity3d.player.UnityPlayer; // 引入 Unity 的类
public class SDKBridge {
    public static void logToUnity(String msg){
        UnityPlayer.UnitySendMessage("UnityReceiver", "ReceiveMessageFromAndroid", msg);
    }
    public static void echoMessage(String msg){
        logToUnity(msg);
    }
}

```

注意到这里import的Unity的类为什么能import呢？就是上一步dependencies加的编译时依赖。

打包aar，生成`mylibrary-debug.aar`文件。

> Build -> AssemblyBundle

## Unity环境搭建

这里以Unity6.1(6000.1.2f1)为例子，新建个项目，记得安装添加了Android依赖项。

把生成的`mylibrary-debug.aar`文件放到`Assets/Plugins/Android`目录下。

Build环境切换成Android。

> 在ProjectSettings下的Player下的Identification下的MinimumAPILevel的等级，要设为大于等于上一步骤在AndroidStudio中创建项目用的等级。

新建一个GameObject，名字就是`UnityReceiver`，挂一个`Mono`脚本。

新建个脚本，测试项

```c#
using UnityEngine;

public class Recv : MonoBehaviour
{
    public void ReceiveMessageFromAndroid(string msg)
    {
        Debug.Log(msg);
    }
    string m_Log="";
    private void OnGUI()
    {
        GUILayout.Label(m_Log);
    }
    private void Awake()
    {
        Application.logMessageReceived += (a, b, c) =>
        {
            m_Log += "\n" + a;
        };
    }
    void Start()
    {
        Debug.Log("Init!");
        AndroidJavaObject jc = new AndroidJavaObject("com.example.mylibrary.SDKBridge");
        jc.CallStatic("echoMessage", "echo");
    }
}

```

打包APK，运行，看到界面上显示`Init!`和`echo`，表示成功。

>在编辑器下用是没效果的，因为没有Android环境。

## 截屏操作

添加媒体URI变动，最新的一条是否包含截屏关键词，包含则触发事件，发回调给Unity

