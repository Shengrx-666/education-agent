# V2 Demo 业务接口实现说明

交付日期：2026-11-20。实现位置：`upstream/learnhouse/apps/api/src/education/business.py`、`business_routes.py`；接口前缀为 `/api/v1/education`。请求使用 `business_schema.json` 中冻结的 JSON Schema 校验。本文记录可运行纵向闭环与本轮范围，验收结果以 `../05-demo-acceptance/` 的实际 HTTP 报告为准。

## 已实现的真实业务链

| 环节 | 接口/操作 | 数据与约束 |
|---|---|---|
| 课程工作台 | GET courses、GET/PATCH courses/{id} | 读取上游课程真实 ID；当前班级和动作授权过滤。可编辑名称、说明、学习目标。 |
| 课程资料 | POST courses/{id}/resources、GET resources/{id}、POST resources/{id}/versions | 创建文本资料和不可变内容版本；编辑追加版本，保存内容哈希、来源、课程策略。 |
| 固定模板候选 | POST courses/{id}/generation-runs | `rule_template` 生成固定 Java 布尔判断题，实际写入资源和任务。所选资料只建立来源关联；不声称理解或改写资料，不调用模型。 |
| 检查与发布 | POST resource-versions/{id}/checks、publication-events | 确定性结构检查、教师确认、按班级发布/撤回；检查版本、策略和发布事件链由服务及数据库约束共同验证。 |
| 作业布置 | POST/GET courses/{id}/bindings、GET/PATCH bindings/{id} | 同事务创建上游作业骨架和不可变绑定；冻结题目、量规、策略、有效发布记录；只给当前班级学生创建接收快照。归档不可重开。 |
| 作答 | POST bindings/{id}/attempts、GET attempts/{id}、PUT attempts/{id}/draft | 只允许本人草稿；校验题号、答案类型、乐观版本、次数和有效窗口。资源撤回后不能开始新尝试；原尝试保留冻结题目。 |
| 提交 | POST attempts/{id}/submissions | 验证草稿版本与哈希后生成不可变提交回执；草稿冻结。重试不重复提交。 |
| 客观题规则评分 | 提交时自动执行 | 仅对全卷均为布尔/单选且有固定答案的练习评分；严格类型和值比较；不执行学生代码，不调用模型。 |
| 教师批阅 | GET bindings/{id}/submissions、GET submissions/{id}、POST evaluations、grade-revisions | 主观/混合题等待教师；教师先建立评分候选，再显式生效；分项覆盖全部题目、分值符合冻结量规。 |
| 复核与订正 | POST submissions/{id}/reviews、reviews/{id}/resolution、recipients/{id}/resubmission-grants | 学生申请复核；教师维持或追加成绩修订；旧成绩不改写。补交/订正有明确窗口和次数。 |
| 学情与下一步 | GET learning-state、recommendations、evidence/{id}/content | 生效成绩同事务追加证据、统计画像、课程截止时间规则推荐。掌握状态始终 `unknown`；研究能力 `not_connected/unconfigured`，绝不把统计冒充知识追踪。 |
| 教学支持记录 | POST interventions | 本轮仅支持 `record_support`；绑定学生当前画像与可访问对象并写入记录。 |
| 任务元数据 | GET tasks/{id}、POST tasks/{id}/commands | 教师需精确课程生成授权；管理员需 operations.manage，只看技术元数据。支持取消 queued/running 的结果应用；retry 明确拒绝。 |

## 事务与权限边界

- 所有值使用 SQL 参数绑定；表名和查询结构固定在源码中。
- 所有写命令要求 `Idempotency-Key`；按组织、操作者、操作、键加事务锁，校验请求路径、正文哈希和 If-Match。重复请求返回原对象引用，改变请求正文返回 409。
- 涉及可变状态的命令要求 `If-Match`；提交、改分、复核及任务取消对目标行加锁。同一旧版本的并发改分只允许一个成功。
- 幂等回执和审计只存对象编号及元数据，不复制作答、密码、提示词或正文。业务变更、回执和审计在同事务提交。
- 成绩生效与确定性证据/画像投影在一个事务内完成。本版不是异步研究队列；不会显示虚构排队进度。
- 资源版本、提交、评分候选、成绩版本、发布事件、证据、画像版本等由 `ea` 数据库不可变约束保护。
- 使用 root 提供的 `security.py` 读取真实登录身份、当前成员关系及动作授权；学生只读本人提交，管理后台不默认拥有课程正文。
- Demo 为专用实例；旧 LearnHouse 内容/作业/代码/AI 接口由统一边界关闭，避免绕过本层权限。

## 策略实际执行

新增资源、版本、生成、检查、发布和布置使用课程当前最新策略，写入时与策略管理共用事务锁，拒绝通过旧策略创建新事实。历史绑定的作答、评分、复核继续使用已经冻结的规则。幂等重放只读取原对象编号，不以旧策略新增执行。

- 生成校验 allowed_generation_modes、maximum_task_budget；本版固定同步模板只执行一次、预算为零，满足 maximum_task_attempts。资料必须 ready 且未归档。
- require_human_review 优先于 allow_rule_auto_publish；要求人工时固定模板也必须 approve。没有快速发布许可时采取保守人工审核。强制审核标记不能通过更换策略清除。本版没有无人审核的自动发布后台任务。
- schema、source_ready、scope、answer_consistency、rubric_bounds 分别执行结构、来源状态及哈希、课程知识点/引用范围、客观答案类型、正分值检查。boolean_truth_table 只针对系统已知固定 Java 模板验证两题真值，不执行输入代码。其他材料明确显示“不适用，不表示已验证题干语义”，教师内容依赖人工确认。
- 发布必须有当前策略下的通过检查；缺少必需项、来源已失效或必须人工却无审核时拒绝。
- 布置时重新检查当前策略、量规和人工审批，并把 policy_rules、deterministic_checks、checker_version 写入不可变 rules_snapshot；allow_review 不得比课程策略放宽。旧的已审核内容可在重新通过当前确定性检查后用于新作业。
- 旧格式策略不修改原文，以禁止研究执行、零预算、一次任务、强人工、禁止模板自动发布、禁止新作业开启复核的保守默认处理；已经冻结的历史作业不追溯。

## 与冻结接口说明的可见差异

这些差异用于本地 Demo 页面整合，不是另行设计数据库；响应增补字段在后续正式接口版本应纳入 OpenAPI。

| DTO | 本轮增补或调整 |
|---|---|
| CourseDetail | 增补 `knowledge_points` 供选择器使用；`bindings` 为完整可见 BindingView，含 `id` 与兼容别名 `binding_id`；`chapters` 当前为空。 |
| ResourceVersionSummary | 增补 `title`、`kind`，使工作台无需对每条资源再读取正文。 |
| ResourceView | 教师增加 `version_history`；学生不返回答案、内部检查和发布历史。 |
| BindingView | 增补 description、maximum_score、question_content、教师 recipients/answer_key；学生答案仅按 after_due/after_effective 策略释放。未开始且资料撤回时 question_content 为空并标记 content_access=withdrawn。 |
| AttemptView | 增补 question_content、draft_hash 供保存和提交；答卷仍为本人权限。 |
| SubmissionView | 增补 course_id、recipient_id、question_content；GradeView 增补 feedback（对象）；reviews 增补 created_at，etag 使用当前有效成绩版本。 |
| TaskRefs | 规则生成任务增加 resource_id、resource_version_id 供直接导航；管理员结果引用裁剪为空对象。 |
| CheckView | 对外使用 CheckItem 数组；数据库内部保留结构化检查对象。 |
| 列表 | 使用 `page: {has_more:false,next_cursor:null}`；本地小样本一次读取当前范围，尚未实现正式游标分页。 |

## 明确未接通

- Web 研究模型执行、真实模型批阅、真实 RAG 问答、正式 B 推荐、动态认知画像与多智能体模拟。
- 后台异步研究重试、模型预算实际消耗、供应商请求强制终止。取消只阻止结果应用。
- POST 新建课程、章节重排、文件/PDF 解析、任意编程语言题目生成和学生代码执行。
- 干预动作 `assign_next/adjust_next` 返回 409；布置新作业使用已经实现的课程作业接口。
- 请求 `research_generator`、`ai_suggestion` 明确返回能力未配置/未接通错误；没有模型请求，也没有假结果。

## 建议重点验收

真实登录后分别验证教师 A → A 班发布与布置 → 学生 A 草稿/提交 → 主观题教师生效/客观题自动生效 → 学生复核 → 教师修订 → 旧版本保留与统计更新。反向验证学生 B/教师 B 跨课越权、管理员正文拒绝、草稿版本冲突、重复提交、同旧版本并发改分、撤回后新开始拒绝、归档不可重开、研究能力不可用。
