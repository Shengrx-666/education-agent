# 教育智能体 V2：本地教学闭环 Demo

2026-11-20。承接阶段一底座验证与阶段二数据/接口设计，本轮已在真实 LearnHouse 固定源码上实现学生、教师和管理后台。使用真实 Cookie 登录和 PostgreSQL 读写，完成发布、布置、作答、评分、更正与复核链路。

**首先阅读 [本地运行说明](RUN_LOCAL.md)**。当前工作区运行 `python scripts/local_demo.py start`，访问 `http://localhost:3300/education/login`。五个角色账号的随机密码仅保存在本机 `.runtime/demo-accounts.local.json`，不会随源码包分发。

## 阶段交付

| 阶段 | 本次状态 | 交付物 |
|---|---|---|
| 1. 底座验证 | 上轮已完成，保留历史报告 | `deliverables/01-foundation` |
| 2. 数据与接口设计 | 上轮已完成，设计基线保持；本轮差异单独登记 | `deliverables/02-design` |
| 3. 本地 Demo 实现 | 本轮交付教学闭环源码和使用说明 | `upstream/learnhouse`、`scripts`、`deliverables/03-demo` |
| 4. 当前实现集成验收 | 本轮交付真实接口和浏览器记录；范围详见报告 | `deliverables/05-demo-acceptance` |
| 5. 研究模型接入及效果验证 | 尚未实施 | 下一阶段独立交付，不把规则模板包装为研究成果 |

## 工程导航

- `upstream/learnhouse/apps/web/components/education`：三端界面与同源 API 客户端。
- `upstream/learnhouse/apps/web/app/education`：Demo 页面入口。
- `upstream/learnhouse/apps/api/src/education`：身份授权、业务、策略、笔记和管理 API。
- `scripts/seed_v2_demo.py`：合成演示数据与随机账号初始化。
- `scripts/local_demo.py`：本地启动、检查、停止与账号定位。
- `integration`：上轮研究适配器，仍独立于本版 Web；尚未调用真实模型。
- `deliverables/03-demo/actual-contract-delta.md`：设计 API 与当前实现的响应扩展及范围差异。
- `THIRD_PARTY_NOTICES.md` 和上游 LICENSE：来源、许可和改动范围。

上轮阶段1–2报告是当时的历史状态，出现“尚未实现”的描述按归档理解；本次实现状态以阶段3/4最新报告与源码为准。上轮原始zip保留不覆盖。

## 边界

本版是本地业务 Demo，预置两门课程，新增课程、文件解析、正式知识图谱、RAG问答、模型生成/批阅、动态研究画像与正式推荐尚未实现或未接通。确定性成绩统计不是知识掌握概率，截止时间规则排序不是研究推荐效果。所有数据明确为演示来源。

本目录包含修改后的 LearnHouse 社区源码，未包含企业组件、node_modules、数据库、密钥和运行环境；另一台机器需按运行说明准备环境。当前Linux环境已实际验收，Windows/WSL2、macOS和Docker新机部署未验证。源码上传不等于在线网站发布。

2026-11-22 仓库整理：本目录由已验收的本地源码包整理为可跟踪的 Git 源码，保留来源与许可；原有研究实现位于仓库根目录。`integration` 仍按独立研究仓库路径设计，接入根目录研究代码属于下一阶段，不因目录合并自动启用模型。

原始交付包为 `教育智能体V2_本地Demo源码与交付包_2026-11-20.zip`，SHA256 为 `200db8634b3877f7e4a2c007d35520bfdfab562e7b45c1c8c17fa59cdbf1139c`。Git 副本省略原包中的 20 份 `.log` 安装、启动和验证日志；结构化验收结果及报告仍保留。`FILE_MANIFEST.json` 已按本目录实际跟踪的文件重新生成，包含此次 README 与忽略规则调整；`SOURCE_CHANGES.json` 继续记录固定版 LearnHouse 的源码变更。
