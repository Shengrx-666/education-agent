# PostgreSQL 扩展设计（V2 设计基线）

版本：2026-11-20。上游固定提交：`c76cf6f64ab71ed042fe83e985d9c4ab3fa148f5`。输入：[产品规格](../../../product-design-v2/assets/spec-source.md)、[结构化规格](../../../product-design-v2/assets/spec-data.json)。本阶段交付 **26 张 `ea` 扩展表**、DDL、字段字典与 ER；未安装或启动应用，未修改 LearnHouse 源文件；经阶段授权，先在独立 `ea_design_validation` 库使用最小上游结构 stub 执行 DDL 和可回滚约束测试，再在 `ea_full_upstream_validation` 库验证真实上游 schema-only 副本兼容性。本文件描述目标约束，不代表功能已经实现或验收通过。

配套文件：[schema.sql](schema.sql)、[data-dictionary.json](data-dictionary.json)、[er.mmd](er.mmd)。SQL 面向 PostgreSQL 14+，采用 `public` 上游 schema；若部署使用其他 schema，需要迁移时显式修改，禁止依赖不受控 `search_path`。

## 1. 上游事实与唯一权威来源

已逐项读取固定版本 `apps/api/src/db` 模型。未指定 `__tablename__` 的 SQLModel 表按其类名小写；`learner_note` 是显式表名。下面主键全部是 PostgreSQL `INTEGER`，外部 `*_uuid` 多为字符串且不都唯一，**不能把上游整数 ID 替换为 UUID 外键**。

| 上游表 | 权威内容 | 本地源码依据 |
|---|---|---|
| `organization`、`"user"` | 组织、账号、登录凭据、用户身份 | `db/organizations.py:30`；`db/users.py:275` |
| `role`、`userorganization` | 上游组织成员和粗粒度角色；不是教学动作授权全集 | `db/roles.py:39,109`；`db/user_organizations.py:6` |
| `course`、`activity` | 课程、章节活动的业务身份与通用 LMS 编排 | `db/courses/courses.py:98`；`db/courses/activities.py:61` |
| `usergroup`、`usergroupuser`、`usergroupresource` | 班级/组身份、当前成员、组与课程的访问关联和时间窗 | `db/usergroups.py:15`；`db/usergroup_user.py:14`；`db/usergroup_resources.py:7` |
| `assignment`、`assignmenttask` | 作业/题目在 LMS 中的身份和作者编辑入口 | `db/courses/assignments.py:234,337` |
| `learner_note` | 学生私人笔记正文、所属用户、课程及活动 | `db/learner_notes.py:30` |
| `assignmentusersubmission`、`assignmenttasksubmission`、`assignmentaigrade` | 旧 LMS 的当前尝试展示；不具备不可变历史语义 | `db/courses/assignments.py:115,557`；`db/courses/assignment_ai_grades.py:27` |

上游 `roles.Rights.assignments` 把 authoring/tasks/submissions/grading 放在一个 CRUD 桶；它不能表达“仅审核、不发布”“仅本班批阅”等 P01–P22。`resourceauthor` 也仅是内容作者关系，不能等同于所有教学授权。API 必须叠加 `ea.action_grant`，管理员角色没有默认正文权限。

旧 `retry_assignment_submission` 位于 `services/courses/activities/assignments.py:3767`：删除题级提交（约 3899 行）、重置当前学生提交并递增计数（约 3925 行）、删除 AI 评分（约 3966 行）。因此 V2 不能把旧 retry/grade 接口直接用于新尝试；也不能用 `attempt_number` 反推已经丢失的历史。

V2 中题面/答案/量规/策略快照、正式提交、所有评分和生效历史，以 `ea` 为唯一权威。上游 course/activity/assignment 继续承接通用 LMS 身份和导航；如需上游完成度，只通过 outbox 投影到当前成绩/进度，不允许双向改分。投影失败单独重试，不撤销已成功提交。旧记录若导入，只能保存迁移时实际可见快照，标记 `legacy_current_snapshot` 来源；不可编造旧尝试。

## 2. 表清单与边界

| # | `ea` 表 | 责任、关联页面 | 修改规则 |
|---|---|---|---|
| 1 | `principal` | 上游用户在组织内的安全主体或受限服务主体；C01/A03 | 只允许停用状态变更；不重复储存密码/登录会话 |
| 2 | `action_grant` | 动作＋课程/班级/学生范围、独立批准、有效期；A03 | 只允许撤销；授权变化新建记录 |
| 3 | `policy_version` | 全局允许策略及课程选择的不可变版本；A04/T03 | 只追加；课程版本引用组织全局版本 |
| 4 | `task_run` | 解析/生成/检查/评估/画像/推荐任务、预算、租约与重试；T06/A05 | 有限状态更新，输入和授权主体冻结 |
| 5 | `knowledge_point` | 课程知识点定义和版本；T05/S08 | 只追加，编码＋版本唯一 |
| 6 | `resource` | 资料/课程内容/练习的稳定身份、上游活动映射；T05/T08 | 名称和归档状态可变 |
| 7 | `resource_version` | 原文件、解析结果、题面、受限答案、生成来源及强制复核；T05–T08 | 只追加；解析/修订形成新版本 |
| 8 | `rubric_version` | 评分量规与分值尺度；T07/T09/T10 | 只追加 |
| 9 | `content_check` | 确定性检查及人工审批事实；T07 | 只追加，结论绑定版本和策略 |
| 10 | `publication_event` | 按班发布/撤回链；T08 | 只追加；保留旧发布依据 |
| 11 | `assignment_binding` | 上游作业的一次布置版本，冻结题面/量规/策略、时间与规则；T09/S05 | 仅状态及理由可变，规则变更另建版本 |
| 12 | `assignment_recipient` | 布置时具体学生与班级快照；T09/S05 | 只追加；不是当前成员权限来源 |
| 13 | `resubmission_grant` | 按学生/任务限定时间及次数的补交/订正；T10/S06 | 只允许撤销 |
| 14 | `attempt` | 冻结版本、可变私人草稿、尝试序号与补交额度槽位；S06 | 仅草稿可保存；提交后冻结 |
| 15 | `submission` | 不可变答案快照、请求摘要及回执；S06/S07 | 只追加，每尝试最多一个 |
| 16 | `evaluation` | 规则评分/AI 建议/教师判断，含异常状态；T10/S07 | 只追加，AI 建议不等于生效 |
| 17 | `grade_revision` | 唯一生效链、修订理由及旧结果；T10/S07 | 只追加，旧链节点不修改 |
| 18 | `review_request` | 对指定评分版本的复核及处理结论；S07/T10 | open 可一次结案，结案后不可改 |
| 19 | `note_permission` | 笔记画像用途与指定教师共享的独立同意；S04 | 只允许撤销；撤销后重新同意创建新版本 |
| 20 | `evidence_event` | 知识点证据、来源与判断类型；S08/T11 | 只追加；摘要不包含原始答案全文 |
| 21 | `profile_version` | 课程内学生状态、证据清单、方法及研究接通状态；S08/T11 | 只追加，失败不产出假版本 |
| 22 | `recommendation_version` | 对某画像版本运行一次推荐的结果；S08 | 只追加，可明确 no_content |
| 23 | `recommendation_item` | 有 FK 的推荐目标、知识点、证据和原因；S08 | 只追加；点击时重新鉴权 |
| 24 | `intervention_event` | 教师调整后续任务的理由与上下文；T11 | 只追加，不覆盖原建议 |
| 25 | `outbox_event` | 同事务领域事件和通用命令幂等回执 | 仅投递游标/次数可改 |
| 26 | `audit_event` | 组织范围授权、发布、改分、干预、运行元数据；A06 | 只追加，禁止正文/密钥 |

没有复制用户、学校学籍、通用课程、班级、题库商城、支付、直播、排课或聊天产品。课程问答历史不作为本次必建新表；没有接通时保留资料阅读并返回能力状态。教学分组不得改变上游入班授权。Demo 采用直接成员、手工班级；智能/嵌套组需后续专门适配，不能默认沿用其继承扩张范围。

## 3. 组织、课程和学生一致性

`org_id`、上游 `course_id/student_id/usergroup_id/assignment_id` 均为 INTEGER；新扩展主键为 UUID，审计主键为 BIGINT identity。所有时间字段采用 `timestamptz`；数据库/连接以 UTC 读写，展示层再转换时区。DDL 不依赖 `uuid-ossp`，使用 PostgreSQL 自带 `gen_random_uuid()`。个人笔记同意中的 NULL 接受者采用分开的部分唯一索引，兼容已准备的 PostgreSQL 14.24；不使用 PostgreSQL 15 的 NULLS NOT DISTINCT。

为建立复合 FK，DDL **只增加五个上游唯一索引**：course(id,org_id)、activity(id,course_id,org_id)、assignment(id,course_id,org_id)、usergroup(id,org_id)、learner_note(id,user_id,course_id,org_id)。不改上游业务字段、主键或 cascade 定义。原 PK 已唯一，索引仅补足组合 FK 引用资格。

链路为 `assignment_binding → assignment_recipient → attempt → submission → evaluation → grade_revision → evidence/profile → recommendation`。复合 FK 将 `org_id/course_id/student_id` 放入同一引用中，不能把课程甲的提交、学生乙的成绩或组织丙的画像混在一起。班级 FK 保证同 org；recipient 的组合 FK 保证它与布置班级一致；note_permission 组合 FK 保证同笔记所有人/课程/组织。推荐作业目标必须匹配本人 recipient；材料目标必须同课程。

上游 `usergroupresource.resource_uuid` 是普通字符串，不是可靠的外键。本设计不伪造“课程成员”表替代它。数据库的 `assert_recipient_access` 在布置、开始及提交时联查当前 `userorganization`、直接 `usergroupuser` 和 `usergroupresource → course.course_uuid`，验证组织、组及访问时间窗。上游非唯一 UUID 在迁移前须检查并清理冲突。一般读取、下载、检索和教师权限由 API 统一授权器每次检查；**历史 recipient 快照不授予当前权限**。

不对历史记录 FK 到可删除的 `userorganization`/`usergroupuser` 行，否则退班会被外键阻止。成员移除后保留历史而立即拒绝新访问。上游 org/course/user 删除会受到扩展 `RESTRICT` 引用阻止；应用改为停用/归档。合法数据删除、脱敏与保留期限需独立迁移流程，不能以 CASCADE 清空学习事实。

数据库可证明对象归属一致，但不能证明请求者身份、教师在授权范围内、学生仍有有效登录会话，或 JSON 中的文本符合教育业务。对应 API 校验不可省略。客户端不能选择 actor/principal/student_id 来冒充身份。

## 4. 权限与正文边界

`action_grant` 不是角色名映射表。每条记录明确主体、单个动作、org、可选 course/group/student、开始/结束时间、批准者及撤销者。`approved_by <> principal_id` 防止数据库层直接自批准；授予者是否有委派权限、批准者是否为独立有权主体，由授权服务验证并审计。Demo 用初始化配置提供独立批准主体，不允许管理员以自增角色获得学生正文。

课程创建、组织授权/策略/运维/审计元数据可为 org 级；编辑、生成、审核、发布、批阅、画像和证据动作必须有 course。group/student 限定是进一步缩小范围，不是或条件扩大权限。同一动作的有效授权可以并集，同一条授权内部 org/course/group/student 必须同时满足。画像摘要权与证据原文权分开；任何笔记读取还必须有当前有效 `teacher_read` 同意。学生对自己的操作采用当前上游授权＋对象所有权，不要求给所有学生授予教师 action_grant。

上游 admin/backoffice 标志、课程 authorship、角色切换和预览都不跳过上述授权。服务身份具有独立 `principal.kind=service`、动作和课程范围，不能冒充真人教师。自动发布仅允许固定规则模板；研究生成器版本始终 `forced_review=true`。

`resource_version.content` 存学生可公开部分，`restricted_content` 存答案/内部评分依据；API必须用白名单投影，不能直接序列化整行。学生看到参考答案要按冻结 `answer_release` 规则判断。管理员运维接口仅读 task/audit 的状态、编号、费用、错误码，不返回 content、draft、answer_snapshot、feedback、checks 原文或证据全文。对象存储 key 不是可永久公开 URL；每次下载发短期链接并重验授权。

SQL 收回 PUBLIC 对 schema/table/function 权限，**没有授予上游普通角色任何 ea 权限**。上线前应建立迁移 owner、受限应用角色和仅元数据的运维查询角色；运行账号不能拥有表、禁用触发器或改变角色。该设计尚未宣称实现完整 RLS；真实请求级授权器和正文投影未实现前，不能将 SQL 可执行等同于越权验收通过。

## 5. 资源、校验、发布和策略

resource 是稳定身份，resource_version 是快照。文本/PDF 上传先写 pending 版本，解析任务输出 ready 或 failed 的新版本并通过 previous/source_version_id 关联；解析失败版本不进入检索与生成。原件保存对象存储引用和 SHA-256，提取文本/题目及结构化来源保存在不可变版本；任何修订产生新版本，旧 content_check 不能套用新版本。前驱 forced_review=true 时新版本也必须为 true，数据库触发器拒绝通过改 generation_mode 洗掉门禁；API还须保持来源链，禁止复制成新资源时伪报来源。

来源清单至少记录输入资源版本/hash、外部引用、模板/提示版本、模型名称及可获取的版本标识、生成器代码版本、参数、结构化检查结果；供应商未返回精确模型 build 时写 unknown，不虚构版本。不保存模型隐藏思维过程。resource/rubric/policy 内容摘要由服务计算并校验，数据库仅验证 hash 格式。

policy_version 的 org 全局版冻结允许范围、强制校验、自动发布模板白名单、评分路径、答案规则、预算和重试上限；课程版引用具体全局版并只能收紧。规则 JSON 由带版本的应用 schema 验证和比较；SQL 不会自行理解任意 JSON 策略。旧任务绑定旧策略，不能“切换策略”消除既有 forced_review。

content_check 同时容纳确定性结果和人工审核，但用 check_kind 和 verdict 分开。发布事件须引用同资源版本、同策略的 pass 校验；有强制门禁须引用 approve 审核。DB 拒绝未 ready 资源、错误类型的检查和服务自动发布研究候选。API还须验证所有必需检查项齐全且通过、引用当前有效检查/审核、审批者具有人类身份及 review 权限、发布者另具 publish 权限；不能只写一个空 checks＋pass 即宣称校验通过。

发布与撤回是按 `resource_version_id + usergroup_id` 的单链事件，event_no 连续，根唯一、每节点后继唯一。发布不是覆盖资源行的布尔值。撤回阻止新开始、问答索引和新推荐；已开始尝试继续按原冻结规则提交。严重内容错误由 assignment_binding.status=paused 显式暂停，保留草稿并通知，不能判零分。发布/撤回、布置、新开始通过 resource 行锁串行化；撤回后的迟到发布还必须检查任务 epoch、取消、授权与当前版本。

## 6. 布置、草稿、补交和不可变提交

assignment_binding 是“布置版本”，不是新通用 assignment。它引用上游 assignment，并冻结资源/量规/策略/发布事件及班级、时间、最大尝试数、答案规则；只能更新 assigned/paused/closed/archived 状态、时间和理由。规则改动新建 version，不能让旧 recipient/attempt 静默指向新版。Demo 布置要求明确 due_at，默认截止后开放答案；无截止自学任务留后续扩展。

assignment_recipient 记录当时实际收件学生及成员授权快照。课程授权变化不会重写快照；读/写仍联查当前成员。新增补布置需显式新增 recipient 并审计；已移出班级的学生不会继续凭旧记录提交。

开始尝试在事务中锁 recipient 与 binding，重验开放/截止、当前成员、当前发布和规则。`start_key` 防止重复创建，`attempt_no` 连续递增，每 recipient 只有一个 draft。草稿 PATCH 使用 `draft_revision` 条件更新并递增；冲突返回 409，不能最后写入者静默覆盖。未提交私人草稿可删除；正式提交后 attempt 和答案不可修改。

补交/订正授权绑定同 recipient/student/binding，明确 starts_at/expires_at/allowed_attempts。每个新尝试分配唯一 `(grant_id,grant_slot)`，槽位不得超过 allowed_attempts；已占用槽位不会因失败回调重复消费。开始与正式提交都检查同一时间窗，截止后无有效授权则拒绝；已在授权过期前打开页面不等于提交仍有权。撤销立即禁止后续提交。额度计入已开始、保留的尝试；放弃尝试不自动返还，删除从未提交的草稿可释放其槽位。

正式提交事务：按当前身份查已有幂等回执；相同 key 不同 request_hash 返回 409；锁 attempt/recipient/binding 并重验权限/时间；插入 submission（答案完整快照、来源、回执）；AFTER INSERT 自动把 attempt 标为 submitted；写 outbox `submission.accepted`；提交事务后才返回回执。`attempt_id UNIQUE` 保障任意请求 key 也不能制造第二个提交。已存在同键回执返回前仍重验访问权；数据库唯一冲突由服务取原回执，不因触发器校验失败给已成功请求伪造失败。提交失败保留草稿。

请求 hash 使用规范化业务请求字节的 SHA-256，不含一次性网络字段。答案 JSON 中的题目 ID 必须属于 attempt.resource_version，且全部题型/长度/附件版本匹配；这部分由应用 JSON schema 和冻结题目清单验证。Demo 保存代码文本，绝不执行学生代码。

## 7. 评分、复核与更正

evaluation.source 将 rule、ai_suggestion、teacher 分开；outcome 为 scored/needs_review/tool_error。只有 scored 有数值，分数不得超出对应冻结量规 maximum_score；DB触发器验证评估量规等于尝试绑定量规。AI建议即使 scored 也不能直接进入 grade_revision；教师确认时新建 teacher evaluation，可保留 AI 候选 ID 在 details 中作为来源，由服务验证其归属。人工可在 AI 缺席时独立批阅。

grade_revision 构成每 submission 唯一链：一个 revision=1 根；后继 supersedes_id 唯一且 revision 连续。没有“is_current”多行更新竞态；当前有效结果是无后继的节点。首次自动规则评分或教师确认插入新节点；改分必须新 evaluation＋新 revision＋非空理由。并发教师修改同一旧版本时，只有一个后继成功，另一请求 409；不静默覆盖。

review_request 针对确切 grade_revision。每个结果版本最多一个 open 复核；open 可结为 retained/revised/withdrawn，结案后触发器拒绝改动。retained/withdrawn 不创建成绩更正；revised 必须引用同 submission/student 的不同评分版本，API验证它是被复核结果的有效后继并属于当前处理事务。学生申请依据任务 allow_review 与本人有效结果，不能提交其他人的版本编号。

生效或修订成绩的事务同时写出站 `grade.effective`/`grade.corrected` 与审计元数据。复核期间旧结果继续生效；只有真正 revised 才重算。重评仍按原冻结量规；如题面/量规错误涉及旧作业，本 Demo 应显式创建更正任务和受影响范围，另立迁移/重评规格，不通过改 SQL 偷换旧快照。

## 8. 证据、学习状态与推荐

证据保存三种彼此独立的信息：事件来源（effective_grade/consented_note/observation）、数据来源（real/demo/manual_example/simulated）、判断来源（rule/model/teacher/self_report）。有效评分证据通过 FK 指向 grade_revision，DB禁止把 demo 提交“洗成”real。未生效 AI 建议不能成为正式掌握更新触发器。observation 可保存基础行为观察，不能伪称学习增益。

profile_version 只在成功生成可用版本后插入；处理中/失败信息来自 task_run。每学生课程只有一个连续版本链，trigger_event_key 与 method_version 去重；trigger_type 区分评分生效/更正、笔记证据、同意撤销和显式重建，只有评分触发必须有 trigger_grade_id。这样笔记撤权可在成绩和方法版本都不变时产生新画像，不伪造评分或方法升级。evidence_manifest 的 evidence_id 在 DB 中逐个检查同学生、课程、组织；states 使用知识点 UUID 作键、state=good/bad/unknown/conflict。摘要里没有值就是未知，禁止把 Good/Bad/Unknown 硬映射成未经验证的百分比。新版本提交前须锁学生课程链并重新检查当前评分头及输入证据集合，旧输入的迟到任务不能覆盖最新状态。

`method_kind=rule_statistics` 明示规则统计，research_fields 必须为空，不能称作研究画像。真正接入现有研究原型时用 `research_prototype`，记录 method_version、capability_status、证据来源；connected 仅代表接通，不代表研究有效性已经验证。每个研究字段须有 status/source/method_version，允许 unknown/not_connected/unvalidated/observed/estimated/conflict；缺少来源、未验证情绪或长期趋势不生成数值。D* 验收必须证明真实提交→已接通研究增量更新→知识点推荐；单纯规则统计只能作为明确标注的回退，不能据此宣布 D* 完成。

note_permission 的唯一有效槽以 revoked_at 判断，时间到期读取立即失效；若同用途/教师需要再次授权，服务先锁相同笔记范围，把已到期旧行写 revoked_at=expires_at，再创建更高 consent_revision，并保留审计。不能用依赖 now() 的部分索引或静默复活旧同意。

note_permission 将 profile_use 与 teacher_read 分开；共享给教师不等于画像授权，画像授权也不允许教师读全文。撤销后证据摘要可以保留可追溯标记，但不得继续取笔记原文或作为新画像输入；服务触发受影响画像重算，旧版本显示来源已撤销，正文入口关闭。正式提交快照仍按正式业务记录保存。上游笔记一旦有正式引用不能直接物理删除；学生“删除”应走明确的删除/脱敏工作流，不能宣称单表 DELETE 已完成所有保留义务。

recommendation_version 绑定 profile_version 与方法版本，明确 ready/no_content；每项用 FK 连接证据、知识点和可访问材料或本人作业 recipient。推荐点击时重新判断当前画像、有效评分头、资源发布/归档、授权及任务状态；存在未完成更正重算时暂停从旧建议新建任务。重算只生成新版本，不改变正在作答尝试。无匹配资源使用 no_content＋原因，不捏造可跳转项目。推荐排序/是否跳过的界面状态不得取消教师必交任务。

intervention_event 保留教师、理由、当时画像/推荐与后续目标任务；目标只能是未开始后续安排。教学干预不能归因成模型独立效果。T12 研究质量评估不在本 26 表中虚构实验结果；学习增益验证需要独立实验与来源规范。

## 9. 异步任务、幂等与审计

task_run 在 org/requested_by/operation/idempotency_key 上唯一，输入 hash 和 refs 冻结。queued→running 领取时递增 attempt_count、execution_epoch，写 lease_until；worker 只提交匹配当前 epoch 的结果。失败重试在 max_attempts 和 budget_limit 内；取消写 cancelled_at 并提升 epoch，阻止迟到回调。取消后不能通过原 job 重新启用，需新显式任务/key；重试失败任务不改变原输入和业务版本。数据库约束预算非负且不超上限，但实际模型费用预留、退款和供应商迟到账单需要服务实现，不能把本表数值当完整账务系统。

worker 完成事务必须再次查授权、任务状态/epoch、输入版本、受影响对象当前状态，锁行后写结果＋业务事件。并发副作用使用唯一键（submission、grade 后继、profile event+method、recommendation profile+method）去重。任务状态转移、租约 CAS、服务权限和模型 key 不由此 DDL 自动实现；必须在 API/worker 集成阶段验收。

outbox 只存对象编号、版本、错误码等非正文 payload，和业务事实同事务写入。投递端 `FOR UPDATE SKIP LOCKED` 领取，有限次数，失败置 dead_letter；消费者使用事件 ID/业务唯一键实现至少一次投递下的幂等。不得宣称队列 exactly once。一般写命令的 Idempotency-Key 使用 `event_type='command.receipt'`、`deduplication_key=actorId:operation:key`，payload 保留 request_hash/HTTP status/result_refs；同事务标 published_at 表示已完成回执而无需消息投递。真正领域事件用独立 event_type/key，不能让回执替代实际 outbox。回执不含答案/模型全文，相同 key 跨 actor 隔离。

audit_event 只保存动作、actor、org/course、对象编号、前后版本、理由码、关联 request/task。改分教学理由在 grade_revision；正文复核理由在 review_request；审计不复制其全文。禁止日志记录密码、令牌、API密钥、学生完整答案或模型提示全文；密钥放安全配置系统，数据库仅可留配置标识。请求追踪不能通过 target_id 绕过业务正文授权。

## 10. 迁移前置、验证和回滚限制

1. 固定上游版本并运行其正式 Alembic 链，确认公共表名、PK和所有本设计用到的列真实存在。DDL preflight 仅检查 PostgreSQL版本和表存在；列类型、重复 UUID、跨 org 脏关系及不可解析旧截止时间仍需专门 preflight 查询。不要将本文件直接作为兼容未知 LearnHouse 版本的脚本。
2. 备份并记录迁移版本。先在隔离库用与固定版一致的表结构验证；最低 stub 需 organization(id)、user(id)、course(id,org_id,course_uuid)、activity(id,course_id,org_id)、assignment(id,course_id,org_id)、usergroup(id,org_id)、userorganization(user_id,org_id)、usergroupuser(org_id,usergroup_id,user_id,expires_at)、usergroupresource(org_id,usergroup_id,resource_uuid,starts_at,expires_at)、learner_note(id,user_id,course_id,org_id)。stub 只允许用于空测试库，不得替代上游迁移或复制进生产。
3. 本 DDL 是一次性事务。重复执行应失败，不能用大量 IF NOT EXISTS 掩盖已存在但定义错误的对象。五个上游索引不是 CONCURRENTLY；演示空库可直接事务内建，已有大型库需另列并发索引迁移、锁等待与回退方案。
4. 仅迁移 owner 执行；配置 runtime 权限、授权器、上游入口拦截与正文响应投影后才能暴露业务接口。ea 管理的作业必须禁用旧 retry/submit/grade 写路径；否则旁路会产生两套权威记录。
5. 新业务只读迁移后版本；历史批量导入须单独脚本、来源标记、核对数量/hash及撤回方案。初始化账号和密钥不得写入 DDL。所有试运行数据明确标 demo。

**本阶段验证状态：** 已对照固定源码检查上游实体名/PK及重试语义；完成 26 表、350 列、68 处 ea→ea FK 的静态核对。随后在本地 PostgreSQL **14.24** 的独立 `ea_design_validation` 库运行最小上游 stub＋最终 schema.sql，DDL 成功 COMMIT；执行 **37 项正反例断言，全部通过并 ROLLBACK**，测试提交、画像及上游测试数据剩余均为 0。见 [验证汇总](validation-summary.json)、[DDL日志](validation-ddl.log)、[约束日志](validation-constraints.log)、[上游stub](validation-upstream-stub.sql)、[可复验SQL](validation-constraints.sql)。

实测包括跨 org/course/student 外键、独立批准、不可变资源/提交/成绩、AI建议不能直接生效、分数边界、单复核及不分叉成绩链、强制复核不可经模式切换/省略前驱绕过、任务和命令幂等唯一性、同key不同actor隔离、截止后需补交授权、过期/撤销授权及额度、提交失败保留草稿、退班拒绝提交、演示来源不得转真、规则统计不得伪装研究字段、撤销笔记许可后旧证据不可进入新画像，以及**无新成绩/无方法升级也可成功进行撤权重算**。

另外，已从原版API成功 bootstrap 的 `learnhouse_v2_foundation` **只读导出真实结构**（106张 public 表，Alembic head `d8i2c3o4p5y6`，vector 0.8.1），使用 `pg_dump --schema-only --no-owner --no-privileges` 恢复到独立空库 `ea_full_upstream_validation`。最终 schema.sql 在该真实结构副本上成功 COMMIT，无需修改DDL；目标库为 public 106表＋ea 26表/350列，organization/user/assignment/submission 均0行。源库未修改、业务数据未复制。见 [真实结构恢复日志](validation-real-upstream-restore.log)、[真实结构DDL日志](validation-real-upstream-ddl.log)，导出及DDL的SHA-256均记录在验证汇总。

上述证据确认固定版本的**真实表结构兼容性**，以及stub中的单连接约束行为；**不等于有业务数据的历史升级迁移、HTTP对象权限、并发竞争、worker迟到回调、前端或研究效果验收**。管理员正文拒绝和同键返回原回执仍须 API 集成验证；两教师真实并发、撤权/发布竞争、任务租约 fencing 和 outbox 重试须多连接/故障注入测试。复验时先在新的同名空测试库执行 stub，再执行 schema.sql，最后执行 validation-constraints.sql；不要在含业务数据的库执行 stub，不要重复应用一次性 DDL。

回滚不能对已有真实提交的 schema 执行 DROP CASCADE。空库、无业务事实且已核对备份时，才可移除 ea schema 后再移除五个 `ea_uq_*` 上游索引。产生业务数据后采用前向修复：停新写、保留只读与回执、修复部署，必要时使用已验证备份恢复；必须说明其 RPO/RTO 和期间写入损失。触发器、不可变历史和上游 RESTRICT 不得在运行服务中临时关闭以“解决”报错。回滚代码也需继续识别 ea 托管作业，不能退回旧覆盖式 retry。
