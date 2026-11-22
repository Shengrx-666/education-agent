# 表、API 与研究接口交叉审核

审核日期：2026-11-20。范围：`02-design/schema.sql`、`openapi.json`、`api-page-mapping.json`、`database-design.md`、研究契约和 `integration/research_adapter.py`；为确认笔记复用边界另查 LearnHouse `learner_notes.py`。本轮只读检查其他代理的文件，并把问题发送相应负责人修复；本报告不表示完整 Demo 已上线、Web 路由已实现或真实 AI 已接通。

结论：本轮发现的 8 项设计矛盾已分别通过 DDL/API 修复或明确禁用未实现能力处理；14 项静态交叉检查通过。对象范围独立授权、规则结果与研究结果分开、研究候选必须人工复核的方向一致。下面保留原问题与修复证据，同时列出仍需服务端实现的桥接，避免把设计修正当成上线验收。

## 1. 会阻止接线的发现

| 编号 | 发现、复现条件与影响 | 修复要求 / 本轮状态 |
| --- | --- | --- |
| CR01 / 高 | `GenerationRequest` 首版无 target_student_id，而适配器 Snapshot 与上游 generate 都必须绑定 student_id；同一请求还允许 requirement 8000 字符、空目标，但适配器要求每项 1–4000、非空唯一目标。`budget_limit/max_attempts` 不能表达独立的模型请求次预算。直接按公开 schema 发研究生成请求无法构造合法受信快照 | **设计已修复并复核**：研究/规则分支 oneOf；研究分支显式目标学生并重新校验课程/班级范围、目标 UUID 非空唯一、requirement 1–4000、max_calls 1–8、默认 run_mode=preview。规则模板分支不虚构学生。TaskView 增加 run_mode/output_kind，避免预览冒充候选生成 |
| CR02 / 高 | API `Idempotency-Key` 声明按 org/principal/operation 隔离，首版 `ea.task_run` 唯一键却是 `(org_id,operation,idempotency_key)`。两个不同教师使用同键将跨调用者冲突，甚至错误实现可能重放别人的任务 | **DDL 已修复并复核**：唯一键改为 `(org_id,requested_by,operation,idempotency_key)`；约束脚本已有不同 actor 同键正例及同 actor 重复拒绝。HTTP 层仍须验证同键改正文返回 409，而非只依赖数据库唯一异常 |
| CR03 / 高 | API 允许 failed task 沿原任务递增 execution_epoch 重试；适配器把 epoch 纳入不可变输入 identity，原 job 换 epoch 会 IDEMPOTENCY_CONFLICT，原失败 job 不换 epoch 只复用旧失败结果。现适配器也没有 --resume 入口 | **以明确能力门禁关闭设计矛盾**：API 研究任务 retry 一律 409 RESEARCH_RETRY_UNAVAILABLE，TaskView 增加 can_retry/retry_block_reason，取消仅承诺 prevent_result_application；普通规则任务可独立重试。真实研究恢复仍未实现，不能新建 job/key 绕过 unknown 或重置预算 |
| CR04 / 高 | 首版 API 只有笔记许可写入和 evidence 原文读取。学生仅授予 teacher_read、拒绝 profile_use 时，不能创建 consented_note 画像证据；上游 list_activity_notes/_own_note 又只查当前 user.id。因此已共享的笔记没有教师正文读取入口 | **API 已补齐并复核**：新增 `GET /notes/{note_id}/shared-content`，接收教师需当前有效 teacher_read + 本课程授权，不依赖 profile_use/evidence；本人继续上游 owner 路由。evidence 内容前置条件及 mapping 已明确“本人按所有权；教师需 teacher_read”，不要求学生给自己授予教师共享权限 |
| CR05 / 高 | 首版 `resource_version` 仅检查“当前 mode=research_generator 则 forced_review=true”。新版本若把 mode 改 teacher/rule_template 并 forced_review=false，就能洗掉前版 needs_review；API 却承诺继承且不能放宽 | **DDL 已修复并复核**：新增 `validate_resource_lineage` 继承检查。二次审核还指出 version=2/previous=NULL 可绕过；最终增加 version=1 当且仅当前驱为空的 CHECK。约束日志已有模式切换和省略前驱两项拒绝验证。人工批准仍是独立事件，不重写旧状态 |
| CR06 / 高 | `profile_version.trigger_grade_id` 首版非空，且 `(student,course,trigger_grade_id,method_version)` 唯一。笔记授权撤销触发重算时 grade 与方法没变，无法插入新版本；只有历史/笔记证据且无 grade 时也无合法触发器 | **DDL 已修复并复核**：新增 trigger_type/trigger_event_key，按来源事件+方法幂等；只有 grade_effective/grade_corrected 必须绑定 grade，其他类型不得伪造 grade。约束脚本已加入同一 method_version、无新 grade 的 consent_revoked 新画像正例。这只证明版本能落库，不证明研究原型已实现旧推断纠错 |
| CR07 / 中高 | 首版 `validate_evidence` 在第一次引用笔记时校验 profile_use，但 `validate_profile` 重用旧 evidence_event 时未重检同意；许可撤销/过期后，新画像仍可能引用旧笔记证据 | **DDL 已修复并复核**：validate_profile 遇到 consented_note 会再验当前 profile_use 未撤销且未过期；日志包含旧证据绕过撤销被拒绝。旧画像保留可追溯记录，产品 worker 仍需读取前与提交前检查 |
| CR08 / 中 | `note_permission` 未撤销唯一索引不看 expires_at。过期许可仍占槽，再次 grant 给同用途/教师会冲突 | **设计与 API 已补齐并复核**：锁同一 note/purpose/grantee，过期旧记录先写 revoked_at=expires_at，再追加更高 consent_revision；保留历史与审计。服务事务仍待实现验证；不使用含 now() 的部分索引 |

## 2. 必须定义的来源、身份与状态桥接

以下字段名字或枚举不同本身不是缺陷；**缺少服务端映射、直接传递或改标来源才是实现阻塞**。映射必须与输入快照一起冻结并持久保存，不能在浏览器执行。

| 产品表 / API | 研究侧 | 必要桥接 |
| --- | --- | --- |
| `public.user.id` / student_id 整数；course_id 整数；actor principal UUID | Principal / Snapshot 的字符串 student_id、course_id、actor_id | 从已授权对象生成稳定研究命名空间 ID；task.input_refs 保留与组织/课程/学生的映射。历史 `java_u...` 不自动认作某个 LearnHouse 账号；引用同一研究画像时全部证据身份必须匹配 |
| knowledge_point_id UUID + code + version + definition | catalog_version、concept_id（如 java.condition）、定义文本 | 用冻结的课程知识点映射表转换；跨课程、重复/空目标拒绝。定义迁移不能偷换旧画像。一个 UUID 并不自动等于旧研究 concept_id |
| provenance=`real`，且有真实认证/历史审计来源 | source_kind=`real_student` 或 `historical_student` | 再根据来源区分真实 live 回执与原始 train；保留 split、source.file/index/hash、原学生映射；有效成绩不自动证明来源是真实学生 |
| provenance=`demo/manual_example/simulated` | source_kind=`test_fixture` | 保留原细分类和测试标签，只能预览或离线 fixture transport；禁止为通过研究校验改成 real_student。设计示例的 synthetic_example 不是可直接执行的 Snapshot |
| judgment_source=`rule/model/teacher/self_report` | model_inference、tool_observation，以及独立规则投影 | 这是判断来源轴，不能和 provenance 混为一谈。教师成绩、规则判分、模型观察分别存证；教师确认不等于模型推断正确 |
| method_kind=`rule_statistics` | `LearningEvidenceProjection` | 保留独立类型，model_id=None、mastery_state=Unknown；不得写成研究 StudentProfile。规则统计的正确/错误次数不转成掌握概率 |
| method_kind=`research_prototype`；StateValue.state 单值 | 原画像 observation 的逐条 Good/Bad/Unknown 与无总体状态的 summaries | 不能仅改大小写后当作总体掌握，更不能多数投票。未定义并验收聚合方法前，整体 state=unknown，展示有来源的逐条观察/摘要和不确定性 |
| recommendation strategy=`research_B` | `strategy=B`、decision_kind=model_inference | 保留推荐输入与正式运行身份；course_rule 不是 B。B 选目标并不等于已有可访问资源，仍需资源映射与实时授权过滤；当前完整 B→生成运行交接尚未接线 |
| task.operation=`profile_update` 等产品生命周期名 | profile / update / generate / recommend 白名单 | input_refs 必须显式记录 worker_operation；初始画像不能误当增量。产品 evaluate/recompute/parse 不可作为任意字符串传研究 CLI |
| task.status queued/running/succeeded/failed/cancelled | previewed、needs_review、rejected、recommended、insufficient_evidence、unknown、discarded | 任务执行完成与内容可发布分开。needs_review 可以对应计算完成，但资源 forced_review=true；unknown 应映射非成功+稳定不可重试错误，不能丢掉未知状态。previewed 不标真实模型运行成功 |
| max_attempts、budget_limit、execution_epoch | max_calls、每步最多两次请求、固定检查点 | 队列领取次数、请求额度、金额预算和取消/重试代次是四种不同概念；不得互相替代。额度没有价格依据时不能显示为已核实费用 |

既有 API 把运行能力 `unconfigured/configured_unverified/verified/failed` 与画像能力 `connected/not_connected/unvalidated` 分字段，方向正确。adapter 的 not_verified_fixture 必须显示测试替身，不能映射 verified。配置存在、预览通过和收到真实模型响应也应分开。

## 3. 已一致的边界

- SQL、API 和研究契约均区分确定性校验与人工审核；研究候选不自动发布。SQL 对研究模式 forced_review、本次新增前驱门禁、发布时要求本版本 pass/必要 approve 构成不同层保护。
- `profile_use` 与 `teacher_read` 在数据结构上分离；当前发现集中在缺读取路径、有效期限再授权和撤销后新画像重用，并非要求把两项许可合并。
- AI 建议与有效教师/规则成绩分开；未生效建议不应触发正式画像。更正旧成绩须保留旧版本；独立规则投影可以重算，研究原型的追加更新仍不能被冒称为旧推断纠错。
- 研究适配器仅返回受限引用与状态，没有返回原始 prompt、密钥或学生全文；公开 API 仍需自己实现引用解析、对象授权和正文裁剪，不能把私有产物目录直接开放。

## 4. 本轮复核证据与验收限度

审核者实际执行的 14 项静态检查覆盖：研究生成学生必填、请求预算、目标非空唯一、requirement 边界、默认 preview、规则模式不要求假学生、独立共享笔记路由、研究 retry 禁用、任务 actor 幂等范围、资源前驱必填、forced_review 继承、通用画像触发、笔记同意重检，以及 API 映射记录的 schema.sql 哈希与当前文件一致。

另读取了 DB 负责人产出的 `02-design/validation-constraints.sql` 和 `.log`：日志显示 37 项断言通过并 ROLLBACK，含本轮关键回归项；这不是审核者重新运行真实产品数据库的结果。无模型 rule_statistics 测试样例也已改为 not_connected/unknown，避免示例呈现为已接通研究。API 当前为 41 项设计操作，新增项是共享笔记读取。

最终复核的 schema.sql SHA-256 为 `fad3fba28d7f7933fc05b87b57cb5a4f9f0dba4bf37f530bbc600531ce3b4616`；`api-page-mapping.json` 的 schema_sql_sha256_at_generation 与之相同。后来若改表或语义，必须重新做相应交叉检查。

本次是文档、DDL、接口与现有离线适配器的交叉审核；没有启动完整网站，没有验证真实登录后的所有跨角色页面，没有连接付费模型，也没有执行学生程序。DDL 修复验证、API schema 示例校验和研究离线测试各自只证明对应范围，不能合并宣称 AC01–AC15 或 D* 全部通过。

最终集成需要加入针对上述条件的反向检查：不同教师同幂等键、合法/非法目标学生、同任务 epoch 重试、只 teacher_read 无 profile_use、撤销后旧证据新画像、过期许可再授权、模式切换清除 forced_review、fixture 来源改标、旧成绩更正后 stale。只有真实端到端链路完成后，才能将相应验收条目标为通过。
