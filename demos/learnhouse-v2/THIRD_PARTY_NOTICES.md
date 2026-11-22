# 来源与许可

LearnHouse： https://github.com/learnhouse/learnhouse/tree/c76cf6f64ab71ed042fe83e985d9c4ab3fa148f5 。固定社区源码版本，保留其LICENSE。交付中的真实数据库结构导出来自该版本；不含业务数据，不重新标记许可。企业组件不自动包含于社区使用范围。

education-agent： https://github.com/ylj-0132/education-agent/tree/099a875a0da7322964780a8973d4ced8c1f304ce 。本包提供调用其CLI的独立适配器，没有复制完整研究仓库或其运行数据；使用时保留该仓库自身约束和参考代码许可。

验证时使用pgvector v0.8.1： https://github.com/pgvector/pgvector/tree/v0.8.1 。本包不含其二进制、源码或系统运行时。

本次阶段3/4源码交付新增说明：压缩包包含固定版 LearnHouse 的社区跟踪文件及本轮修改；上游 LICENSE、版权说明和本说明均保留。改动集中在 apps/api/src/education、apps/web/components/education、页面入口、app.py、events.py、proxy.ts、Providers.tsx 和 next.config.js；具体清单见 SOURCE_CHANGES.json。未包含企业 Edition 实现、完整 research 仓库、第三方二进制或依赖缓存。源码仍受各文件原许可与 LearnHouse LICENSE 约束，不将开源代码重新声明为闭源自有成果。
