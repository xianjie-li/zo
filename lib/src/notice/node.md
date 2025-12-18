## 实现

组件通用采用 ZoOverlay 作为底层实现，但只使用一个固定顶部的 ZoOverlayEntry，所有消息
都在单独管理和渲染

通过 ZoNotice 类实现类似 ZoOverlay 的管理方式，但是它管理一组 ZoNoticeEntry 配置，这是一个继承 Object 的普通配置对象

组件内部通过 _NoticeView 对活动的 ZoNoticeEntry 进行布局，每一条消息又由一个 ZoNoticeCard
进行渲染，并提供关键的通知