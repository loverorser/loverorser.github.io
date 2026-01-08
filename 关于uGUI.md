# 关于uGUI

## 关于RectMask2D

先思考 要搞一个Mask要干嘛

首先明白作用，一个Mask的组件的作用就是，让其的所有孩子都有裁剪的效果。

所以Mask存储了一个List，包含它的所有`MaskableGraphic`和`IClip`孩子，在`willRenderCanvas`阶段的`Cull`流程中，遍历所有的List，设置好其的Mask边界，注册到Rebuild中。

## 关于Mask

模板测试

Stencil

- Inspector 看到的 Material 是 baseMaterial
- Unity **不改 Image 的原材质**
- Unity 内部 clone + Cache（StencilMaterial）
- CanvasRenderer 用的不是你看到的 Material

👉 **渲染时替换，完全 runtime**

# 关于锚点

# 关于打断合批

# 关于事件触发

