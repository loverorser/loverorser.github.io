# 关于C#的异步、Await、ETTask和其他

简单一句话就是：等这个操作执行，怎么执行的你别管，执行后的后续操作也别管。

A();
await B();

C();

到B之后就完全交给B的一个等待对象awaiter了。



## 从await开始

我们需要await一个东西，这个东西是一个Task，但深层次下是一个自定义的类，一个自定义的Task。这个类必须有一个方法`GetAwaiter()`，这个方法返回的也是一个类，一个自定义的Awaiter。

这个自定义的Awaiter必须满足以下条件：

- 继承一个接口`ICriticalNotifyCompletion`和`INotifyCompletion`，其有两个方法`void UnsafeOnCompleted(Action continuation)`和`void OnCompleted(Action continuation)`。
- 具有一个`get`属性`IsCompleted`
- 具有一个`GetResult()`方法

顾名思义，这个`OnCompleted`的意思是指**`状态机`第一次`MoveNext`后的*Completed***。

## 使用了await关键词的函数

函数体内只要用到了`await`关键词，该函数必须声明为`async`的，一个简单的例子

```c#
using System;
using System.Threading.Tasks;
public class C {
    Task t = null;
    public async void F() {
        Console.WriteLine("Begin");
        await t;
        Console.WriteLine("End");
    }
}
```

表面简洁的背后其实是语法糖，C#的编译器会为我们对`F()`这个函数进行一些操作：

- 根据整个`F()`里面的内容生成一个状态机类，这个状态机类继承`IAsyncStateMachine`接口，包含

  - ```
    namespace System.Runtime.CompilerServices
    {
        /// <summary>
        /// Represents state machines generated for asynchronous methods.
        /// This type is intended for compiler use only.
        /// </summary>
        public interface IAsyncStateMachine
        {
            /// <summary>Moves the state machine to its next state.</summary>
            void MoveNext();
            /// <summary>Configures the state machine with a heap-allocated replica.</summary>
            /// <param name="stateMachine">The heap-allocated replica.</param>
            void SetStateMachine(IAsyncStateMachine stateMachine);
        }
    }
    ```

- 状态机的类如下

  - ```
    [CompilerGenerated]
        private sealed class <F>d__1 : IAsyncStateMachine
        {
            public int <>1__state;
    
            public AsyncVoidMethodBuilder <>t__builder;
    
            public C <>4__this;
    
            private TaskAwaiter <>u__1;
    
            private void MoveNext()
            {
                int num = <>1__state;
                try
                {
                    TaskAwaiter awaiter;
                    if (num != 0)
                    {
                        Console.WriteLine("Begin");
                        awaiter = <>4__this.t.GetAwaiter();
                        if (!awaiter.IsCompleted)
                        {
                            num = (<>1__state = 0);
                            <>u__1 = awaiter;
                            <F>d__1 stateMachine = this;
                            <>t__builder.AwaitUnsafeOnCompleted(ref awaiter, ref stateMachine);
                            return;
                        }
                    }
                    else
                    {
                        awaiter = <>u__1;
                        <>u__1 = default(TaskAwaiter);
                        num = (<>1__state = -1);
                    }
                    awaiter.GetResult();
                    Console.WriteLine("End");
                }
                catch (Exception exception)
                {
                    <>1__state = -2;
                    <>t__builder.SetException(exception);
                    return;
                }
                <>1__state = -2;
                <>t__builder.SetResult();
            }
    
            void IAsyncStateMachine.MoveNext()
            {
                //ILSpy generated this explicit interface implementation from .override directive in MoveNext
                this.MoveNext();
            }
    
            [DebuggerHidden]
            private void SetStateMachine([Nullable(1)] IAsyncStateMachine stateMachine)
            {
            }
    
            void IAsyncStateMachine.SetStateMachine([Nullable(1)] IAsyncStateMachine stateMachine)
            {
                //ILSpy generated this explicit interface implementation from .override directive in SetStateMachine
                this.SetStateMachine(stateMachine);
            }
        }
    ```

- 生成状态机类的实例，并启动之，实际上的`F()`函数如下

  - ```c#
    [AsyncStateMachine(typeof(<F>d__1))]
        [DebuggerStepThrough]
        public void F()
        {
            <F>d__1 stateMachine = new <F>d__1();
            stateMachine.<>t__builder = AsyncVoidMethodBuilder.Create();
            stateMachine.<>4__this = this;
            stateMachine.<>1__state = -1;
            stateMachine.<>t__builder.Start(ref stateMachine);
        }
    ```

## Async能返回什么

The return type of an async method must be void, Task, Task<T>, a task-like type, IAsyncEnumerable<T>, or IAsyncEnumerator<T>

什么是 `task-like type`呢？就是我们自定义的，能返回的Task了。

## 状态机内部逻辑

### Build是什么

注意到状态机内部有一个类`AsyncVoidMethodBuilder`名字叫`<>t__builder`，为什么叫`AsyncVoidMethodBuilder`呢？是根据这个异步方法的返回值类型来决定的。

如果返回值是`void`，那么`Build`就是`AsyncVoidMethodBuilder`。

如果返回值是`Task`，那么`Build`是什么呢？每个需要`Awaiter`的`Task`想要生效，必须持有一个特性，`[System.Runtime.CompilerServices.AsyncMethodBuilder(typeof())]`，`typeof`里的类型即为生成的`Build`类型。即为`AsyncTaskMethodBuilder`

### 开始

准备就绪后，Build启动状态机。

ATask

Task

UniTask

ValueTask

Coroutine