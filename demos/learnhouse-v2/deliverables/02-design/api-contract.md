# Education V2 接口契约（设计稿）

版本：`0.1.0-design`；日期：2026-11-20。API 前缀为 `/api/v1/education`。本稿与同目录 `openapi.json`（OpenAPI 3.1.0）、`api-page-mapping.json` 和 `schema.sql` 配套；**仅设计，尚未向 LearnHouse app 添加或运行这些接口**。上游源码基线为 `c76cf6f64ab71ed042fe83e985d9c4ab3fa148f5`；产品规格为 V2.0。数据库最终设计使用 `ea.*`，替代前期映射文件中尚未落地的 `edu_*` 建议名。

本文定义 41 个关键操作，其中 23 个写操作；覆盖 28 个页面的核心读取/命令映射，但不把明确规划项或尚未接通的研究能力包装为已实现。每个操作在 OpenAPI 的 `x-pages`、`x-permissions`、`x-tables`、`x-transaction-preconditions` 中列出页面、权限、表和事务前置。

## 1. 身份与登录：复用 LearnHouse

没有 `/education/login`、自签 V2 JWT 或客户端可选用户 ID 的登录协议。使用已核对的上游接口：

| 行为 | 现有上游协议 | 源码 |
| --- | --- | --- |
| 登录 | `POST /api/v1/auth/login`，`application/x-www-form-urlencoded`，`username`、`password`、可选 `org_slug` | `apps/api/src/routers/auth.py:622` |
| 刷新 | `GET /api/v1/auth/refresh`，使用 `LH_refresh` httpOnly cookie | 同文件 `:394` |
| 退出 | `DELETE /api/v1/auth/logout`，清理访问/刷新 cookie 并调用现有会话撤销机制 | 同文件 `:1531` |
| 当前身份 | `get_current_user`；扩展 API 通过同源 `LH_access` cookie 读取 | `apps/api/src/security/auth.py:659`，cookie 常量在 `:106` |

浏览器请求同源并带 `credentials: include`；cookie 属性和令牌轮换沿用上游，不在 localStorage 另存可伪造角色。全部 V2 写入还必须验证请求 Origin 属于配置的同源集合；CORS、按钮隐藏和 Cookie SameSite 不能代替对象权限。此处 `csrf_mode=same_origin_enforced` 是需要落实的适配要求，不声称新增路由已具备该中间件。

`get_current_user` 返回类型不是恒定的真实学生/教师。适配层先明确拒绝 `AnonymousUser`（401）、`APITokenUser`、`BackofficeAPITokenUser` 和任何未知 principal 类型（403），再要求真实 `PublicUser` 对应当前组织的有效 `ea.principal(kind=human)`。失效、撤销和 disabled 身份不可继续。既有组织 token 的 assignments 权限不能冒充 V2 教师，更不能作为自动发布服务身份。

V2 学生、教师、管理员演示账号**不得分配上游 Admin=1、Maintainer=2 或 `is_backoffice_staff`（数据库 `is_superadmin`）**。V2 管理员只获得 `access.manage`、`policy.manage`、`operations.manage`、`audit.metadata` 等明确范围，不默认获得教学正文、评分、审核、发布权。`GET /session` 返回角色视图及实际动作范围；选择“教师/管理员视图”只改变界面，不改变后端身份和授权。

受限服务 principal 使用 `ea.principal(kind=service)`，从可信内部 worker 上下文进入业务服务；本契约的浏览器 API 不给普通 API token 或客户端请求头开放服务身份。自动规则评分/发布与回调仍须绑定服务 principal、course、policy、任务 epoch 和输入哈希，没有未鉴权的通用 callback 路由。

**退出实际验收缺口：**上游 logout 对撤销存储故障会吞异常，仍清 cookie 并返回成功。原版冒烟已验证退出后客户端无会话401，但AC01仍必须保留退出前cookie主动重放，并在撤销依赖不可用时验证；不能只看 HTTP 200或清cookie后401。扩展 `revoke_sessions` 命令必须确认撤销状态写入成功，失败返回 503，并阻止把“清 cookie”报告为“旧会话已撤销”。不重新发明身份协议，但需要收紧适配与故障语义。

## 2. ID、状态和响应投影

| 名称 | 类型与来源 |
| --- | --- |
| `org_id` / `course_id` / `student_id` / `usergroup_id` | 上游 `public.organization/course/user/usergroup.id`，正整数 |
| `principal_id` | `ea.principal.id`，UUID；不能与 user ID 混用 |
| `resource_id` / `resource_version_id` / `binding_id` / `attempt_id` / `submission_id` | 对应 `ea.*.id`，UUID |
| UI 的 `assignmentId` | V2 页面映射到 **binding UUID**；响应保留 `assignment_id` 表示上游 `public.assignment.id`，二者不能混用 |
| UI 的 `generationId` | `ea.task_run.id` UUID |
| `activity_id` / `activity_uuid` | 前者为上游整数，后者是上游笔记接口使用的字符串；课程 DTO 同时提供 |
| 审计 `id` | 数据库 BIGINT，对外十进制字符串，避免 JavaScript 精度丢失 |

`org_id`、actor、student 所有者、实际模型、来源 provenance 和评分 producer 由会话与冻结对象推导；请求不能以这些字段覆盖身份。每个 UUID 都需要联查验证相同 org/course/student 关系。替换合法但属于他人或别班的编号返回 `403 SCOPE_DENIED`，不回显对方信息；不存在返回 404。服务端按允许字段构造 DTO，不直接序列化 ORM 模型。

状态沿用 `schema.sql`：

| 对象 | 数据库存储状态/版本 |
| --- | --- |
| `resource_version` | processing_state=`pending/ready/failed`；generation_mode=`upload/teacher/research_generator/rule_template`；不可变 `version` |
| `content_check` | deterministic=`pass/fail`；human_review=`approve/reject` |
| `publication_event` | `publish/withdraw`，`event_no + previous_event_id` 追加链 |
| `assignment_binding` | `assigned/paused/closed/archived`；内容、量规、策略和班级绑定版本冻结 |
| `attempt` | `draft/submitted/abandoned`；`draft_revision` 乐观锁；`attempt_no` 历史次数 |
| `evaluation` | source=`rule/ai_suggestion/teacher`；outcome=`scored/needs_review/tool_error`；非 scored 的 score 必须 null |
| `grade_revision` | `revision + supersedes_id` 单链，追加生效结果；AI 建议不能直接生效 |
| `review_request` | `open/retained/revised/withdrawn`；本核心契约覆盖申请和教师保留/修订 |
| `task_run` | `queued/running/succeeded/failed/cancelled`；`execution_epoch`、lease 和累计预算 |
| `profile_version` | method_kind=`rule_statistics/research_prototype`；capability_status=`connected/not_connected/unvalidated`；知识点为 `good/bad/unknown/conflict` |
| `recommendation_version` | 存储 state 仅 `ready/no_content`；当前 pending/failed/stale 等来自任务投影 |

API 的 `evaluation_state`、`pipeline`、`runtime_capability_status`、推荐 `strategy` 和 ETag 是显式服务 DTO 投影，不是宣称数据库具有同名列。`TaskView.capability_status=null` 表示该 parse/规则任务不依赖模型；不能把规则成功写成“模型 verified”。管理元数据 DTO 不含 prompt、题面、作答、反馈全文、模型回复、私有 object_key 或密钥。

## 3. 每个写入共同的幂等与并发协议

所有 23 个扩展写操作，包括创建、草稿保存、发布、撤回、审核、成绩、复核、取消重试和授权，均要求：

- `Idempotency-Key: <1–200字符>`：一个逻辑命令一个键；重试保留同键同请求。缺失返回 428；不是客户端防双击替代品。
- `If-Match: "<服务端强ETag>"`：不可使用 `*` 或弱 ETag。缺失 428、过期 412。部分 payload 还含 `expected_version`/`expected_event_no`/`expected_execution_epoch`，须与对应数据库版本一致，不是覆盖 header 的另一条宽松路径。
- 对象/父集合的 GET 提供 ETag。ETag 是聚合当前状态的服务器摘要，不能假设每张上游表有 `version` 列。生成摘要时纳入相应状态、版本链头和影响本命令的关联版本；写事务里加行锁或事务级 advisory lock 后重算并比较。

事务顺序固定为：认证及当前授权 → 查询幂等回执并比对规范化请求哈希 → 若为新命令锁定聚合/必要关系 → 复查版本、范围、状态、时间/次数/预算 → 写业务对象、只追加审计、幂等回执和真实业务 outbox → 提交 → 返回成功。成功回执重放前仍重验当前权限；撤权后不能靠旧回执读正文。

同键同哈希且已完成，返回相同状态码及对象 ID/回执，`Idempotency-Replayed: true`；不重新产生事件。原请求的 `If-Match` 仍是其请求身份的一部分，但回执重放不要求当前头继续等于旧头。同键不同 body/path/版本前置返回 `409 IDEMPOTENCY_CONFLICT`。正在执行且未完成可返回 `409 COMMAND_IN_PROGRESS`；不会创建第二份业务记录。

专用数据库唯一键：`attempt(recipient_id,start_key)`、`submission(org_id,student_id,idempotency_key)` 和 `task_run(org_id,requested_by,operation,idempotency_key)`。task唯一键显式含requested_by；submission键需服务端加入操作命名空间；可将命名空间和原始键 SHA-256 成定长存储键，避免超过 200 字符及跨 actor 碰撞。

其他命令使用 `ea.outbox_event(event_type='command.receipt')`，`deduplication_key=hash(org,principal,operation,client_key)`；payload **只存** `request_hash`、result refs、HTTP status 等元数据。业务变更与 receipt 同事务；command receipt 以 `published_at` 表示幂等完成，无需对外投递。真正业务事件使用不同 event_type/deduplication_key，不混为一条。回执不能存正文、token 或重复副作用。此复用方案已与数据库设计代理对齐，不是假称 schema 有通用 `idempotency_record` 表。

### 写操作的版本来源与锁定对象

| 写操作 operationId | 获取 If-Match 的读视图 / 额外版本 | 事务锁定 |
| --- | --- | --- |
| createEducationCourse | GET `/courses` 集合 ETag | 当前组织课程集合 |
| updateEducationCourse、createEducationSource、startEducationGeneration、createEducationBinding | GET `/courses/{course_id}` ETag | course 与所用策略/来源/发布/班级相关头 |
| createEducationResourceVersion、checkEducationResourceVersion、publishEducationResourceVersion | GET `/resources/{resource_id}` ETag；版本、检查或发布事件头 | resource；检查/发布还锁资源版本与组链 |
| changeEducationBindingState、startEducationAttempt | GET `/bindings/{binding_id}` ETag | binding；start 额外锁本人 recipient 和 grant |
| saveEducationDraft、submitEducationAttempt | GET `/attempts/{attempt_id}` ETag + `expected_version=draft_revision` | attempt；正式提交额外锁 recipient/grant |
| evaluateEducationSubmission、applyEducationGrade、requestEducationReview | GET `/submissions/{submission_id}` ETag；apply 含当前 revision/前驱 | submission 与评价/成绩/复核头 |
| resolveEducationReview | SubmissionView 内 ReviewView.etag + expected_grade_revision | review 和 submission 成绩链 |
| grantEducationResubmission | BindingView 内对应 RecipientView.etag | 单一 recipient 的补交授权集合 |
| createEducationIntervention | GET `/courses/{course_id}/students/{student_id}/learning-state` ETag | 学生当前 profile/recommendation 头与后续目标任务 |
| commandEducationTask | GET `/tasks/{task_id}` ETag + expected_execution_epoch | task，取消/重试递增 epoch 使旧 worker 失效 |
| changeEducationScope、commandEducationPrincipal | GET `/admin/scopes` 集合 ETag | 当前 org 范围集合、目标 principal/成员关系 |
| createEducationPolicy | GET `/admin/policies` ETag + expected_version；新family=0 | 策略 family/parent 策略 |
| changeEducationNotePermission | GET `/session` 的 own_note_permissions_etag + consent 当前头 | 本人 note 和对应用途/接收者许可头 |

上表涉及的内嵌 ETag 都在 OpenAPI 具体响应 schema 中定义。ETag 校验后还必须复查关联记录；对不存在行的首个版本、首个发布或首个授权集合使用稳定范围 advisory lock，不能只依赖“查到零行”的 FOR UPDATE。

## 4. 业务门禁与事务结果

**课程和资源。** 创建课程只授予新课程负责人关系，不生成全校权限；后续审核、发布、批阅仍需要明确动作。课程受控内容保持 `public=false`，班级范围由已授权关联决定。资料文本/PDF导入、解析、候选、确定性校验、人工审核、发布分别有状态或事件；解析失败/无文本 PDF 不得变成 ready。`checks` 的 deterministic 请求没有客户端 verdict 字段，服务端计算 pass/fail；人工 approve 必须引用本版本有效 pass。修改内容追加 resource_version，旧版不变；forced_review 不可被新策略关闭。

`publication_event` 对资源版本/班级形成追加链。publish 要求最新范围、有效策略、pass、必要 approve；withdraw 终止新访问/新推荐/新尝试，不删除旧正式提交证据。规则模板自动发布由受限服务 principal 在同样业务服务中执行；不是普通学生/教师请求声称 `auto=true`。演示规则固定 Java 布尔表达式判断题，不执行学生代码。

**布置与提交。** 创建 binding 冻结 resource/rubric/policy/publication/usergroup，必要时同事务创建上游 Assignment 骨架和新量规；rubric_version_id/new_rubric 恰一有效。成员由服务端当前班级成员快照形成 recipient，不接受任意跨班学生数组。已有提交后不能用 update 旧 Assignment/Task 触发静默重评。binding PATCH 只改变任务运行状态，不改冻结版本或截止规则。

学生开尝试只操作本人 recipient；到期后必须有匹配本人、binding、有效期限及有限次数的 resubmission_grant。grant_slot 原子占用；开始和正式提交都重查时间/状态/权限。正式提交只把锁定且已保存的 draft 快照入账；由唯一 attempt、幂等键和回执约束防重复。教师读取正式 submission，永远不通过“批阅权”读取未提交 draft。

**候选与有效成绩。** `/evaluations` 的 AI 分支只排队返回 202，教师分支保存候选评价返回 201。缺 AI 建议不阻止教师评分。评分必须核对冻结量规、题号与上限，tool_error/needs_review 没有有效分数。AI 建议必须经教师明确确认形成新的 source=teacher evaluation，才能由 `/grade-revisions` 生效；不得把 AI 原行改成 teacher，也不得 AI 候选直接写成绩。规则客观题自动评分由受限内部服务生成 source=rule、scored evaluation 并通过同一成绩事务门禁。

生效/修订锁当前成绩链，追加 revision 和 reason、outbox 更正事件；反馈→画像→推荐按状态依次更新，未完成不提前声称全部成功。研究画像的旧推断不具备现成纠错能力：改分先让产品确定性投影重算，研究状态标 stale/等待新基线，不重复追加作答伪装纠错。

**复核。** 当前有效 grade 每个版本最多一个 open 请求；教师处理需要 `result.review`，修订另外需要 `submission.grade`。retain 记录保留原因，不追加无意义新成绩；revise 将新 teacher evaluation、grade revision、review.status=revised 与更正事件同事务完成。任一步失败全部回滚，旧结果持续有效。复核详情在 SubmissionView 中，不以学生跨跳教师页面实现。

**画像和证据。** learning-state 只在本人或明确教师授权的当前 course/student 返回；管理员聚合管理权不能读取个体画像。摘要为安全投影；原文 `/evidence/{id}/content` 必须再次检查来源正文权限。对于笔记，本人按所有权读取本人正文；教师的 `profile_use` 不能代替 `teacher_read`；撤销许可后停止后续原文访问。已到期但未撤销许可仍可能占active唯一槽；新同意事务须先锁note/purpose/grantee，将到期旧许可revoked_at设为expires_at，再追加新consent_revision。分享指定片段可先创建仅含片段的新私人 note，再授权该 note，不将整篇笔记默认共享。独立 `GET /notes/{note_id}/shared-content` 只要求有效teacher_read及当前课程教师范围，不要求profile_use，也不要求先生成画像/evidence；因此只分享正文而拒绝画像用途的选择仍完整可用。推荐读取时再次过滤发布、权限、recipient、状态，不能替换已开始的 attempt。

**后台。** scopes 管理动作范围和入班/退班，不授予管理员业务正文。客户端不能提交 approved_by；授权批准者必须是独立、具备可委派范围的当前 principal，不等于受益者。给自己新增教学权限直接 403，需要另一个真实授权主体执行批准；Demo预置不自授权。principal disable 仅表示该组织 V2 身份停用，不虚构上游 User.is_active 列或擅自停用其他组织身份。policy 只追加版本；audit 只读追加元数据。模型密钥由安全部署配置提供，浏览器 API 不传回密钥或完整配置。


### 研究生成与现有适配器的精确桥接

`GenerationRequest` 是 `ResearchGenerationRequest | RuleGenerationRequest`，不能用一个缺学生身份的通用payload调用旧研究接口。研究模式要求 `target_student_id` 为真实存在的课程内授权学生（public.user.id整数），服务端映射稳定 worker student_id 并记录在 task_run.input_refs；禁止教师ID代替学生、构造假学生ID或接受浏览器直接指定worker身份。`knowledge_point_ids` 至少1项、去重且全部同课程，服务端映射固定catalog版本中的code；不能把UUID直接当研究概念。requirement长度为1–4000字符，映射Snapshot.requirements单元素tuple；非空targets映射target_concept_ids。

`max_calls` 必须为1–8，指实际模型请求次数（包括步骤重试）；队列 `max_attempts` 与金额/配置单位 `budget_limit` 分别限制，不可互换。研究 `run_mode` 默认preview；preview与execute不得共用job或幂等键升级。execute仅在服务端持有匹配job、actor、operation、完整input_fingerprint、max_calls、期限的受信 `PaidAuthorization` 时执行，浏览器不能提交授权对象/令牌/paid=true。该41项API不提供签发付费执行授权的接口；本轮没有真实授权，不能因为教学权限或预算字段非零自动调用模型。

preview成功只有元数据和opaque产物引用，不创建生成题目。真实研究生成成功也只创建待审候选，ready_for_student仍为false；产品按白名单解析受限产物、验哈希与范围后再写resource_version。当前适配器只接教师explicit_selection目标；B推荐完整run→原封交接→出题仍待接线，不可丢掉来源后伪称完整闭环。

provenance与研究source_kind是不同轴：真实学生/历史证据保持原real_student/historical_student语义；demo、manual_example、simulated只能做test_fixture预览/假transport，不能洗成真实研究输入。rule_statistics对应独立产品统计，research_prototype才是研究画像；course_rule不是正式B，research_B须对应研究strategy=B、decision_kind=model_inference。研究Good/Bad/Unknown是逐条观察，没有整体掌握聚合结果；未定义正式聚合方法时API state保持unknown，不能多数投票或捏造掌握百分比。

## 5. 无模型与错误契约

运行能力使用 `unconfigured/configured_unverified/verified/failed`，与 profile 表的 `not_connected` 区分。无凭证时需要真实执行的研究生成、AI建议、研究画像/推荐调用返回 503 `MODEL_UNCONFIGURED`（先检查当前具体执行授权，无授权先403）；不会创建表示真实执行成功的 succeeded 行、模拟候选或虚构 model_id。研究preview不需要凭证，可完成输入预览；其run_mode=preview、output_kind=preview_metadata、capability=unconfigured/not verified，不产生候选或学生可用结论。已存在任务若执行时发现配置消失，task_run 可为 `failed/error_code=MODEL_UNCONFIGURED`，保留旧有效成绩/画像。队列请求已接收不是模型成功，configured_unverified 不是 verified。

```json
{
  "error": {
    "code": "MODEL_UNCONFIGURED",
    "message": "研究生成尚未配置模型。规则模板模式仍可按已授权策略使用。",
    "request_id": "cd7e8187-a128-44ba-81c1-d8e946e906d1",
    "retryable": false,
    "capability_status": "unconfigured"
  }
}
```

| HTTP | 典型 code | 客户端处理 |
| --- | --- | --- |
| 400 | INVALID_REQUEST | 修正格式，不丢草稿 |
| 401 | AUTH_REQUIRED / SESSION_EXPIRED | 回既有登录流程；保留允许保留的本地草稿，不在日志记录正文 |
| 403 | PRINCIPAL_TYPE_DENIED / SCOPE_DENIED / ACTION_DENIED / SELF_ESCALATION_DENIED | 禁止动作，不借管理员或另一个路径绕过 |
| 404 | OBJECT_NOT_FOUND | 资源不存在；不泄露其他人信息 |
| 409 | IDEMPOTENCY_CONFLICT / COMMAND_IN_PROGRESS / INVALID_STATE / DEADLINE_PASSED / GRANT_EXHAUSTED / STALE_RESULT | 显示明确状态；幂等重复不能再次发副作用 |
| 412 | VERSION_CONFLICT | 拉最新授权视图，保留未提交编辑并提示冲突，不静默覆盖 |
| 422 | VALIDATION_FAILED / SCORE_OUT_OF_RANGE | 指向具体合法字段错误，不直接判学生答案错误 |
| 428 | PRECONDITION_REQUIRED | 补 Idempotency-Key 与 If-Match |
| 429 | RATE_LIMITED / BUDGET_EXHAUSTED | 遵守预算/速率，不新建任务规避额度 |
| 503 | MODEL_UNCONFIGURED / DEPENDENCY_UNAVAILABLE | 显示不可用，保持旧有效记录，不伪造成功 |

统一 Error 格式只用于本扩展 API；已有 LearnHouse auth/notes 的响应保持上游协议，前端适配器可转换错误展示，不谎称现有 auth 已返回此结构。错误不得回显密钥、敏感正文、其他学生姓名或 SQL 堆栈。

## 6. 旧 API、附件、检索与异步回调必须一起受控

本扩展路由的鉴权不能独自完成 AC02。V2 管理的 Course/Activity/Assignment 必须可识别并在原 LearnHouse 服务读取、更新、批阅、下载、公开文件、RAG检索/引用、token接口中调用同一 V2 策略或拒绝绕行。特别检查：

- 上游 Admin/Maintainer/backoffice 旁路；普通角色/作者不能经旧路由获得未授权审核、发布或跨班批阅。
- `assignments.py` 的课程 UPDATE 批阅判断、原 retry 清空作答、改题自动重评；V2 对象拒绝这些原入口或转到版本化业务服务。
- `submission_file_access.py` 的“授课者”条件、原活动文件下载、静态路径及签名链接；旧 URL/缓存不能在撤权后继续提供正文。
- 检索先过滤当前允许材料，再在引用跳转和附件下载重验；答案受限内容不得进入学生问答上下文。
- worker 结果只带对象引用/哈希，应用时验证 input_hash、execution_epoch、lease、请求者/服务身份当前授权、取消状态和业务版本；过期结果不发布、不改分、不更新画像。请求结果 unknown 不自动重发真实模型请求。当前研究适配器不支持同任务增epoch后resume/retry，研究任务retry一律409 RESEARCH_RETRY_UNAVAILABLE，TaskView.can_retry=false；不得换新job/key绕过。普通规则/产品任务仍可在已知失败和剩余预算条件下重试。取消仅保证阻止迟到结果应用，不承诺杀死已发研究进程/模型请求或停止已发生费用。

尚未完成这些门禁前，不能因新增 API 对管理员返回403就宣布“管理员不能读正文”。必须用真实三类账号直接调用旧 API、换编号和下载链接验证。

## 7. 操作目录

下表由同一接口映射生成；请求响应的具体字段和全部错误见 `openapi.json`。

| 操作 | 方法与路径（前缀省略） | 页面 |
| --- | --- | --- |
| `educationSession` | `GET /session` | C01, C02, S01, T01, A01 |
| `listEducationCourses` | `GET /courses` | S01, S02, T01, T02, A01 |
| `createEducationCourse` | `POST /courses` | T02 |
| `getEducationCourse` | `GET /courses/{course_id}` | S03, T03, T04, T05, T08, T09, T11 |
| `updateEducationCourse` | `PATCH /courses/{course_id}` | T03 |
| `createEducationSource` | `POST /courses/{course_id}/resources` | T05 |
| `getEducationResource` | `GET /resources/{resource_id}` | S04, T05, T07, T08 |
| `createEducationResourceVersion` | `POST /resources/{resource_id}/versions` | T07 |
| `startEducationGeneration` | `POST /courses/{course_id}/generation-runs` | T06 |
| `getEducationTask` | `GET /tasks/{task_id}` | T01, T06, A05 |
| `commandEducationTask` | `POST /tasks/{task_id}/commands` | T06, A05 |
| `checkEducationResourceVersion` | `POST /resource-versions/{resource_version_id}/checks` | T07 |
| `publishEducationResourceVersion` | `POST /resource-versions/{resource_version_id}/publication-events` | T08 |
| `listEducationBindings` | `GET /courses/{course_id}/bindings` | S01, S05, T01, T09 |
| `createEducationBinding` | `POST /courses/{course_id}/bindings` | T09 |
| `getEducationBinding` | `GET /bindings/{binding_id}` | S05, T09 |
| `changeEducationBindingState` | `PATCH /bindings/{binding_id}` | T09 |
| `startEducationAttempt` | `POST /bindings/{binding_id}/attempts` | S05, S06, S07 |
| `getEducationAttempt` | `GET /attempts/{attempt_id}` | S06 |
| `saveEducationDraft` | `PUT /attempts/{attempt_id}/draft` | S06 |
| `submitEducationAttempt` | `POST /attempts/{attempt_id}/submissions` | S06, S07 |
| `listEducationSubmissions` | `GET /bindings/{binding_id}/submissions` | T01, T10 |
| `getEducationSubmission` | `GET /submissions/{submission_id}` | S07, T10 |
| `evaluateEducationSubmission` | `POST /submissions/{submission_id}/evaluations` | T10 |
| `applyEducationGrade` | `POST /submissions/{submission_id}/grade-revisions` | T10, S07 |
| `requestEducationReview` | `POST /submissions/{submission_id}/reviews` | S07, T10 |
| `resolveEducationReview` | `POST /reviews/{review_request_id}/resolution` | T10, S07 |
| `grantEducationResubmission` | `POST /recipients/{recipient_id}/resubmission-grants` | T10, S05, S07 |
| `getEducationLearningState` | `GET /courses/{course_id}/students/{student_id}/learning-state` | S08, T11 |
| `getEducationEvidenceContent` | `GET /evidence/{evidence_id}/content` | S08, T11 |
| `getEducationRecommendations` | `GET /courses/{course_id}/students/{student_id}/recommendations` | S01, S08, T11 |
| `createEducationIntervention` | `POST /courses/{course_id}/students/{student_id}/interventions` | T11, T09 |
| `listEducationScopes` | `GET /admin/scopes` | A02, A03 |
| `changeEducationScope` | `POST /admin/scopes` | A03 |
| `listEducationPolicies` | `GET /admin/policies` | A04, T03 |
| `createEducationPolicy` | `POST /admin/policies` | A04, T03 |
| `getEducationOperations` | `GET /admin/operations` | A01, A05 |
| `listEducationAudit` | `GET /admin/audit` | A06 |
| `changeEducationNotePermission` | `POST /notes/{note_id}/permissions` | S04, C02, T11 |
| `commandEducationPrincipal` | `POST /admin/principals/commands` | A02 |
| `getEducationSharedNote` | `GET /notes/{note_id}/shared-content` | S04, C02, T11 |

## 8. 页面覆盖和本轮明确边界

`api-page-mapping.json` 给每个 V2 页面列 operationId、上游复用入口和边界；T12 保持规划，无虚构教学质量 API。以下边界是范围说明，不代表隐藏完成：

- C01/C02 复用现有登录/刷新/退出。本人资料编辑和新账号首次密码设置继续使用经权限收窄的上游流程；此41项契约不新造认证协议。Demo账户由安全初始化生成，密码不硬编码。本轮 A02 新增接口负责 V2身份停用/恢复、撤销会话和范围元数据。
- S04 私人笔记基本 CRUD 复用 `GET/POST /api/v1/notes/activity/{activity_uuid}`、`PATCH/DELETE /api/v1/notes/{note_uuid}`；新接口仅增加共享/用途许可。上游这些写操作尚不具备本稿的统一幂等和版本协议，适配时必须补齐并单独验收，不能把现有接口直接计为通过。
- S04 资料问答不在这41项核心契约中；`course_qa=unconfigured` 时明确未接通并禁用问答提交，资料阅读仍可用。真实RAG另需问答契约、来源权限和答案隔离验收；研究生成 CLI 不是资料问答接口。
- A05 能力/预算/队列为只读元数据，技术取消/重试走 tasks 命令。密钥写入在部署安全配置，不通过浏览器回显；未知成本口径不伪造费用值。
- 研究实际执行遵守 `research-integration-contract.md` 的现有授权、凭证、预算和运行边界。本轮设计/离线结构校验不构成真实模型调用、学生代码执行或研究教学效果验收。

## 9. 本轮验证与下一步

本轮使用标准库解析 JSON、检查所有 `$ref`、41 个 operationId 唯一性、路径参数、23个写接口的幂等/版本头及页面映射；另外对21组具体请求进行定向schema约束检查，覆盖研究学生必填、概念非空去重、4000字符边界、请求额度1–8、拒绝浏览器付费授权、规则模式拒绝假学生、AI请求不能自填分数、审核不能自填校验pass及授权不能自填approved_by。21组结果均符合预期。检查样例内嵌于openapi.json的x-contract-schema-cases，全部是合成契约样例，不对应真实学生/模型调用。另列18项必须运行的权限、事务、来源和迟到回调用例于x-required-runtime-acceptance，全部明确not_run_design_only，不混入通过数。未安装 OpenAPI validator，未宣称经过独立规范验证器；未运行此API、未迁移此设计库、未调用模型。数据库和底座的实际启动/约束测试由对应代理独立记录。

下一阶段以本契约实现受限会话适配、全链路权限门禁和事务服务，再对 AC01/02/04/06/08/09/10/11/14 做真实接口用例；模型未接通仍可验证规则模板、草稿/提交、教师批阅、修订、确定性投影与规则推荐，但不得标成研究画像或正式 B 推荐已执行。
