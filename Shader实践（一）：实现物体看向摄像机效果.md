# Shader实践（一）：实现物体看向摄像机效果

> 前言：shader的一些练习记录。可能有错误地方。请多多指教。

先思考一下如果按程序思路怎么实现：获取`obj`到`camera`的方向向量，然后改变物体的`Rotation`。

```c#
Vector3 dir = obj.position - camera.position;
transform.rotation = Quaternion.LookRotation(dir, Vector3.up);
```

在Shader中怎么实现呢？我们只需要在View空间，让物体按照当前位置显示就可以了。想象一下程序中是先把物体旋转到对应的角度，然后渲染出来。Shader中是更改渲染的方式。

```c
//取得物体的模型空间的中心点，转到世界空间，再转到观察空间
//想象一下现在显示物体在屏幕的左上角，是一个点。
float3 center = mul(UNITY_MATRIX_V, mul(unity_ObjectToWorld, float4(0,0,0,1))).xyz;
//在模型中心点，加上模型顶点的偏移
float3 viewPos = center + float3(v.vertex.x,v.vertex.y,0);
//转到裁剪空间
o.pos = mul(UNITY_MATRIX_P,float4(viewPos,1));
```

带Scale的版本

```c
float3 center = mul(UNITY_MATRIX_V, mul(unity_ObjectToWorld, float4(0,0,0,1))).xyz;

float scaleX = length(unity_ObjectToWorld[0].xyz);
float scaleY = length(unity_ObjectToWorld[1].xyz);

float3 viewPos = center + float3(v.vertex.x * scaleX,v.vertex.y * scaleY,0);

o.pos = mul(UNITY_MATRIX_P,float4(viewPos,1));
```



