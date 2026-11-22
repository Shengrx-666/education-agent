# 研究模块接入契约与无模型验收边界

日期：2026-11-20。范围：研究生成、证据画像增量、正式 B 推荐；对齐产品规格 V2.0（2026-11-19）。本文件是经源码核对的设计契约，不表示产品适配器已实现或真实 AI 已接通。

## 1. 结论与来源

三个研究模块可通过现有 Python CLI / 函数接入独立 worker，但现有工作台不能直接充当产品后端。产品必须先落实身份、课程/班级范围、版本、发布与有效评分，再给研究 worker 提供经过授权的快照。研究返回候选和推断，不能取得发布、改分或身份授予权。

读取的主证据为 `research-2026-11-19/evidence/education-agent-099a875a/manifest.json`，标记提交 `099a875a0da7322964780a8973d4ced8c1f304ce`；该目录只有文件摘录，并非完整可运行源码。按任务要求补读 `/tmp/education-agent-reference-20261110`，先读取其 `AGENTS.md`。其 Git HEAD 为 `02f99cd6029fee74f43f6d98e31d1a7b5fec3495`，工作区干净。

核对 manifest 所列哈希：两个来源中的 `.env.example`、`profiling/api_client.py`、`profiling/student_profile.py`、`profiling/incremental.py`、`generation/workflow.py`、`webapp/service.py`、`recommendation/runner.py`、`submissions/workflow.py`、`profiling/prompts.py`、`docs/reference-code.md` 均相同；README 不同。因此补读 CLI、上下文、证据校验、队列和测试只归属于上述完整源码 HEAD，不假定所有未摘录文件都属于 `099a875a`。

产品依据：`product-design-v2/assets/spec-data.json` 的 T06/T07/T08、S07/S08、T10/T11、A05、P07–P20、AC03–AC13。没有读取或导出本地真实密钥，也没有调用模型或执行学生代码。

## 2. 已有接口、输入与输出

| 能力 | 已有可调用入口 | 核心输入及限制 | 真实输出与业务含义 |
| --- | --- | --- | --- |
| 研究生成 | `generate_question.py`；`generation.workflow.run_generation(store, client, req)` | 教师入口：catalog、student、scope、targets、requirement，profile/usage_history 可选。或仅使用完整正式推荐任务 `--recommendation-run`；不得另外替换学生、目标、画像、要求、历史 | `generation-result-v1`，`generation.json`、`request.json`；状态 `needs_review / needs_split / rejected / failed`。最多一个候选、一次修订，含版本及六维审核；始终 `ready_for_student=false` |
| 初始画像 | `run_profile.py`；`profiling.reliable_runner.run_profile` | 明确学生、公共 concepts、符合来源约束的原始代码作答，可附绑定的独立执行观测 | `profile.json`：student_id、model_id、stage_models、prompt_version、concepts、observations、summaries、evidence；失败或部分结果不可作为完整画像 |
| 增量画像 | `update_profile.py`；`profiling.incremental.validate_update / run_update` | `base_profile + catalog + records` 或 `base_profile + submission_run`；CLI 单批最多 5 条。学生必须相同；record_id 与 `(source.file, source.index)` 不得重复；基线完整且知识点定义一致 | `update.json`：`completed / partial`、failed_steps、revision、added_observations、profile。仅全部成功写新 `profile.json`；旧画像不覆盖；只提取新作答并重汇总受影响知识点 |
| 正式 B 推荐 | `run_recommendation.py`；`recommendation.runner.run_recommendation` | `prepare_context` 生成 `recommendation-context-v1`：catalog_version、student_id、allowed_concept_ids、goal_concept_ids、requirements、完整画像或 None、显式使用历史快照 | `recommendation-round-v1`：`recommended / insufficient_evidence / failed`，固定 `strategy=B`、`decision_kind=model_inference`。只有 `recommended` 生成 `generation-request-v1`；无推荐不创建伪交接 |
| 版本绑定接收 | `submit_answer.py`；`prepare_submission / receive_submission / load_submission_evidence` | `student-answer-v1`：submission_id、student_id、question_id、question_sha256、origin、program、submitted_at；必须匹配生成题版本，origin 为 student 或 test_fixture | `submission-receipt-v1`，接收回执、不可变 evidence、绑定哈希。只表示收到了作答；不评分、不运行 Java、不更新画像、不批准题目发布 |

生成请求必须由 `build_generation_request` 构造，含目标、允许范围、目标来源、选择理由、证据引用、知识点上下文及关系。`coverage` 恰好覆盖本次目标；结构校验不证明内容正确。六维为 clarity、correctness、target_alignment、student_fit、explanation、combination；审核绑定题目内容哈希。代码正确性审核是静态模型判断，不等于编译/执行通过。

画像 observation 固定包含 concept_id、evidence_id、student_id、kind=`model_inference`、status=`Good|Bad|Unknown`、description 及实际 model_id。summaries 保存 evaluation、counts、evidence_ids 和 model_id；counts 是观察次数，不是正确率或掌握概率。不得把新确定性评分记录伪装成这个模型输出格式。

推荐先选择知识点或组合，再交接出题；它不直接选择产品资源库中的已发布练习，也不自动修改画像。S08 若展示“可开始的推荐资源”，还需产品资源解析、课程授权、发布状态过滤，并保留研究目标与最终资源之间的映射。B 出题交接必须保留同一历史快照和哈希，不能只拷贝 concept_ids。

## 3. 现有 HTTP 能力与产品适配层

旧工作台提供：`GET /api/bootstrap`、`GET /api/artifact?path=...`、`GET /api/jobs`、`GET /api/jobs/:id`、`POST /api/jobs`、`POST /api/submission-draft`。任务请求为 `{operation, mode, fields, confirm}`；operation 包含 profile/recommend/generate/update/submit/verify_reference/verify_student。`preview` 不执行模型；正式模型执行用 `execute`，接收保存用 `save`，非 preview 需要 confirm=true。后端把白名单字段转换为 CLI 参数。

该 HTTP 服务仅监听 127.0.0.1，依靠工作台令牌限制 POST，任务串行且任务列表仅保存在当前服务会话；它没有学生/教师/管理员登录或课程授权。不要把它公开代理成产品 API，也不要让浏览器传入研究文件路径或原样取得 `request.json`、参考答案、模型原始响应。

以下是**拟新增的产品内部语义**，不是声称已存在的研究 HTTP 路由；最终 REST 路径由产品 API 设计统一确定：

| 操作 | 产品授权与版本前置条件 | worker 动作 | 提交结果的约束 |
| --- | --- | --- | --- |
| `research.generate` | 当前教师具有课程生成权；固定目标、材料版本、模式及预算；材料解析成功 | 在私有任务目录序列化输入，用批准的 Python 解释器调用既有 CLI；默认先预览 | 校验当前授权/任务 epoch，存候选、来源与审核记录；研究结果继续 needs_review，不可自动发布 |
| `research.profile_update` | 已生效的评分/教师确认事件；同课程学生；合法真实证据；显式完整基线 | 校验后调用 update_profile；产品受试者 ID 映射为 worker 稳定 ID | 按事件 ID 与基线版本幂等；只在 completed 且基线未变化时切换当前指针；partial 保留旧画像和失败状态 |
| `research.recommend` | 当前完整画像版本或明确无画像；课程范围与目标；同学生历史快照 | prepare_context → 正式 B；只接受结构完整且可追溯的返回 | 重新过滤当前可访问且已发布资源，保留引用；不足证据不造推荐，不替换已开始作答 |
| `research.result_import` | 仅受限服务身份；绑定 job_id、epoch、input_hash、schema、expected_version | 导入不可变产物并做业务校验 | 撤权、取消、撤回、旧版本回调不得推进业务；未知请求结果不得自动重发 |

适配层统一信封至少记录 contract_version、operation、job_id、course_id、subject_id、actor/service identity、input snapshot refs/hashes、expected_version、idempotency_key、run_mode、source_kind、预算与请求额度。actor 与课程范围从认证会话和数据库派生；不要相信客户端声称自己是教师或提交来源为真实学生。研究输出独立保留 research_run_id、实现哈希、实际 model_id/stage_models、prompt_version、输入/输出哈希以及请求状态。

产品数据库是身份、授权、发布、有效成绩、当前画像指针的权威；每个研究任务的 `checkpoint.sqlite3` 是其步骤/请求状态权威，trace.json 仅导出快照。结果应用用事务和唯一键完成，例如 `(operation, effective_result_version_id)`；不得只靠页面禁用按钮。并发画像更新需锁定 `(course_id, student_id)` 或按基线版本 CAS 失败后重排；上游没有全局并发合并。

## 4. 必须补足的语义差异

1. **产品评分不是研究画像。** 当前研究模块分析 Java 原始题面/源码及绑定工具观测，不消费产品的 score/rubric/teacher_feedback 作为权威教学判断。客观判断题、简答文本、教师改分不能随意塞入 `program` 冒充 Java；这些题型先走产品自己的有效结果与证据摘要投影。
2. **接收不是有效评分。** 上游允许按来源声明接收，不做身份认证，也不要求题目已发布。产品必须先验证本人提交、当前任务范围、内容版本、时间/次数、发布/布置状态。待批记录不得更新正式画像。即使有效评分门槛已通过，也不能推断研究模型利用了教师分数。
3. **增量不是纠错。** `run_update` 只追加证据，明确保留旧观察；没有删除/替换旧推断、撤销证据或应用教师改分的入口。AC09 的有效成绩更正可以驱动产品确定性投影重算；研究画像需标记 stale/awaiting_rebuild，基于有效证据集进行新基线构建并另行验收，不能重复追加同一作答规避去重。
4. **没有资料问答/RAG 接口。** 现有输入 requirement/profile 不能证明已实现教学资料解析、材料检索、引用授权、答案隔离或 S04 问答；这些能力须独立实现。未接模型显示“未接通”。
5. **不是双闭环生成，也不是教学效果证明。** 当前为单候选、六维审核、至多一次修订；不把研究实验页中的固定结果当实时功能。不因代码能接入就宣称有效提升学习或完成真实学生试验。

## 5. 依赖、模型凭证及费用约束

- 研究代码使用 Python 标准库（urllib、sqlite3、http.server 等），无需模型 SDK、GraphRAG 或 Node 运行依赖。README 记载开发环境 Python 3.12；实际本机默认 python/python3 为 **3.8.5**，源码存在 dict `|`，因此不能沿用默认解释器。此次预览和 8 项定向离线检查使用 `/usr/bin/python3.10`（3.10.12）通过；这不是所有入口对所有 Python 版本的兼容性声明。worker 固定解释器并记录版本。
- 模型调用读取指定 `--env-file`，`read_env` 直接解析文件，不自动读取 shell 的同名环境变量。正式任务需要秘密管理层提供私有配置文件或适配配置读取，不能只设 shell 变量后假定 CLI 会识别。
- `ZZZ_API_KEY` 与非空模型 ID 必须提供；`ZZZ_BASE_URL` 必须是无用户名/查询参数/片段的 HTTPS 基址，客户端追加 `/chat/completions`。 `.env.example` 中的供应商地址和历史模型别名只是模板，未验证当前可用性、价格、兼容性。没有发起连接探测或付费请求。
- `ZZZ_STRONG_MODEL` 用于 extract、review_question；`ZZZ_WEAK_MODEL` 用于 summarize、recommend_direct、generate_question（包括内容修订）。`ZZZ_MODEL` 是旧配置回退。保留旧画像实际模型标记，不能统一重标为新模型。
- `ZZZ_MAX_CALLS` 与 CLI 限额取较小值；默认 profile/update 上限 12，正式 B 最多 2 次尝试，生成最多 8 次请求（4 个逻辑调用、每步最多 2 次）。生成单次默认 6000 输出 token，画像/推荐模板默认 1500，超时模板默认 60 秒。请求上限不是货币上限，实际费用未知时显示未知。
- 恢复需输入、模型、实现、配置、额度均匹配；成功步骤复用，已收到响应可本地重放，请求结果 unknown 不自动重发。产品重试不得新建任务规避旧预算。
- Java 运行另需 JDK/JBR、人工审阅源码和独立用例、绑定批准哈希；研究生成并不执行代码。当前环境未配置/验收学生代码执行，本阶段不启动 Java。旧轻量执行也不等于文件/网络沙箱。

产品能力状态应区分：`unconfigured`（无凭证）、`configured_unverified`（配置存在但未验连）、`verified`（明确受控调用通过）、`failed`。配置非空不等于已接通。页面和管理日志只展示状态及必要元数据，不回显配置值或模型/学生正文。

## 6. 无模型凭证时可验证与未验收边界

| 链条 | 不需要模型可以验证 | 不能据此宣布完成 |
| --- | --- | --- |
| AC03/04 研究出题入口 | 权限、范围、CLI 预览、目标结构、预算前置检查、缺配置提示、样例候选的版本/门禁测试 | 新题生成、六维语义审核、真实 API 兼容性、内容正确率；旧 needs_review 不得被规则策略消除 |
| AC05 规则模板自动发布 | 固定 Java 布尔表达式判断题模板；受限表达式求值/真值规则（不运行学生代码）；所有确定性校验、策略版本与受限服务身份发布 | 此规则模板不属于 run_generation，不得标为 AI 生成或六维模型审核通过 |
| AC06/07 客观题闭环 | 草稿/提交/回执幂等、答案版本锁定、规则评分生效、反馈落库、事件依次投影到证据摘要与规则资源建议 | 不代表真实 `StudentProfile` 提取/汇总或正式 B 已运行；研究画像仍未知/未更新，UI 必须标明确定性来源 |
| AC08 教师批阅 | 简答/代码作为文本保存，教师按量规确认，生成有效结果事件；AI 建议 unavailable 时仍可批阅 | 不代表执行了代码、自动评估了答案或模型认可教师判断 |
| AC09 更正与重算 | 旧成绩/理由保留、有效版本替换、确定性摘要与规则建议重建、旧回调拒绝 | 不能声称旧研究推断已纠错；其失效状态和新基线任务需可见 |
| AC10/11 恢复 | 以显式 fixture/fake transport 注入超时、取消、重复/迟到结果；验证幂等与授权门禁 | 测试注入不能证明真实供应商超时/重试已验收，也不能标记模型接通 |
| AC12 来源与未知 | 真实/示例/fixture、rule/teacher/model 分别存证；无证据显示未知；不构造百分比 | 假数据演示不是真实教学试验，不得进入正式研究画像 |
| AC13 问答 | 材料权限、解析失败排除、答案可见时间边界；未配置时显示不可用 | 无模型时不能宣布有引用的真实问答或 RAG 已完成 |

确定性产品投影建议使用独立类型 `learning-evidence-projection-v1`，呈现有效结果次数、题目证据、更新时间和来源；无模型推断时 mastery_state 保持 Unknown。规则资源建议使用 `strategy=course_rule`、`decision_kind=rule_result`，写出可审计的规则理由，最终再过滤资源权限。不得创建伪 `model_id`，不得把固定内容包装成模型响应。示例/fixture 可以验证产品演示链，但不能成为真实学生研究证据。

## 7. 本次已经实际完成的离线检查

在完整参考源码上执行以下检查，禁止写入 pycache；临时测试产物由测试框架放入临时目录并清理，上游工作区未修改：

```bash
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=.:tests /usr/bin/python3.10 -B -m unittest test_current_contract test_profile_update -v
PYTHONDONTWRITEBYTECODE=1 /usr/bin/python3.10 -B generate_question.py --student preview-only --scope java.condition --targets java.condition --requirement '仅验证接口预览，不调用模型' --env-file /tmp/intentionally-missing-research-credentials.env
PYTHONDONTWRITEBYTECODE=1 /usr/bin/python3.10 -B run_recommendation.py --student preview-only --scope java.condition --env-file /tmp/intentionally-missing-research-credentials.env
```

结果：**8 项定向测试通过，两个 CLI 预览返回码均为 0**。测试覆盖无凭证增量预览、显式恢复限制、生成与 Java 审批分离、增量保留旧观察且只汇总受影响点、重复/跨学生/test 证据拒绝、输出写入中断恢复、汇总失败不发布新画像。测试增量结果来自注入的假 transport，不是 AI。生成预览输出 `ready_for_student=false`，正式 B 预览只有上下文哈希与预算，没有推荐结论。

未运行研究全套测试、真实模型、Java、真实学生试验或产品端到端验收。本次结论仅是“源码接口可复用且局部确定性契约已检查”。后续凭证可用且获得具体调用授权后，再单列真实调用验收；保留模型/输入/实现/预算指纹、实际返回结构、审核门禁与失败恢复证据。

契约示例见同目录 `research-integration-contract.examples.json`。其 `proposed=true` 和 `source_kind=synthetic_example` 明确表示设计样例，不是运行产物，也不能被导入正式画像。
