# 关于Unity的FixedUpdate

有个代码讲的很好

[这个文章](https://forum.unity.com/threads/the-truth-about-fixedupdate.231637/)

```c#
float timer = 0;
while(true)
{
     while(timer > fixedStep)
    {
         FixedUpdate();
         timer -= fixedStep;
     }
     Update();
     timer += deltaTime;

```