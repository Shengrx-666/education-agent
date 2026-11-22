# 研究适配器实现与离线验收状态

2026-11-20。交付文件：`integration/research_adapter.py`、`integration/tests/test_research_adapter.py`。本适配器是独立 Python 库，未接入 Web 后端；没有发起真实模型调用、执行 Java 或执行学生代码。

## 当前已完成

| 部分 | 实现与检查结果 |
| --- | --- |
| 固定研究底座 | `upstream/education-agent`，读取其 AGENTS 后核对 HEAD 为 `099a875a0da7322964780a8973d4ced8c1f304ce`；固定 `/usr/bin/python3.10`（3.10.12），不使用系统默认 Python 3.8.5 |
| 四个操作 | 仅 generate、profile、update、recommend，分别使用已有正式 CLI；禁止 Java 验证、任意 shell、前端 argv/文件路径/环境配置/输出路径 |
| 默认预览 | 不传 mode 即 preview；显式给上游一个未使用的配置路径，预览不读取真实密钥；真实调用了四种 CLI 的 preview 并全部通过 |
| 受信范围 | `Principal` 携带产品已授权的 actor/course/subjects/concepts/operations；`Snapshot` 是严格字段白名单的结构化数据；校验学生、目标、目录范围及完整基线 |
| 执行门槛 | execute 必须另有产品签发的 `PaidAuthorization`，绑定 job、actor、operation、完整输入摘要、请求额度及期限；必须显式 max_calls，且部署配置的 env_file 存在 |
| 付费身份边界 | 凭证文件存在仅表示可尝试执行，不代表模型接通；本次没有创建真实授权，没有验证供应商或余额；额度是请求次数，不是人民币费用上限 |
| 幂等与恢复 | 私有 SQLite 持久记录；同身份复用结果；同键改输入、改配置、改任务号或把 preview 升级 execute 均拒绝；调用超时变 unknown，同任务不重发；进程异常留下 running 时也拒绝重发 |
| 版本与撤权 | 产品 `current_context` 回调在入口、启动前、返回后重新读当前授权、epoch 和基线版本；撤权或版本变化后丢弃结果引用，不能推进业务 |
| 产物返回 | 仅状态、稳定错误码、受限产物类型/opaque ID/哈希；不返回 argv、磁盘路径、stdout/stderr、prompt、密钥或候选正文；生成始终不能直接 ready_for_student |
| 独立规则投影 | `LearningEvidenceProjection` 固定 schema 为 learning-evidence-projection-v1，model_id=None、mastery_state=Unknown；更正有效结果产生新对象并将 research_status 标为 stale，旧对象不改写 |

上游实现哈希、固定路径/解释器、执行模式、配置文件哈希、超时和 fixture 标记均纳入适配任务身份。配置文件内容与哈希不返回调用者。每个运行目录和账本设私有权限；结构化输入保留在适配器私有存储，供受限服务处理，不能放进公开静态资源目录或提交仓库。

## 运行检查

在 `development-v2-2026-11-20` 下运行：

```bash
PYTHONDONTWRITEBYTECODE=1 /usr/bin/python3.10 -B -m unittest discover -s integration/tests -p test_research_adapter.py -v
```

结果：**30 项测试通过**，耗时约 0.52 秒。测试进程禁止 socket.connect；唯一真实子进程测试显式运行四种上游 CLI 预览，均使用隔离临时 fixture 输入和未配置模型的 preview 模式，输出 status=previewed、model_connection=not_verified。其余 execute 测试完全由 `FakeTransport` 写入明确标记的离线 fixture 产物，不启动研究 CLI，结果标为 not_verified_fixture。

覆盖了默认 preview、固定命令、任意操作/路径拒绝、范围检查、缺授权/缺预算/过期授权/缺配置、fixture 不得进入真实执行、幂等重读、冲突、超时不重发、撤权/版本变化、错误输出不泄露、配置变化、needs_review 门禁、四操作产物限制及更正 stale。测试数据都是 fixture，没有把测试题或假学生作答登记为真实证据。上游工作区未修改。

## 产品接入方式

```python
from pathlib import Path
from integration.research_adapter import (
    CurrentContext, JobContext, Principal, ResearchAdapter, Snapshot,
)

# 这些对象由完成身份与对象级授权的服务端构造，禁止原样信任浏览器 JSON。
principal = Principal(
    actor_id="teacher-id", course_id="course-id",
    subject_ids=frozenset({"student-id"}),
    concept_ids=frozenset({"java.condition"}),
    operations=frozenset({"generate"}),
)

def current_context(principal, subject_id, operation):
    # 产品实现：读取当前授权、课程状态、任务 epoch 与当前基线版本。
    # 返回 active=False 表示撤权/取消/对象不可用；不得返回固定演示值用于生产。
    return load_authorized_current_context(principal, subject_id, operation)

adapter = ResearchAdapter(Path("/private/research-jobs"), current_context)
snapshot = Snapshot.from_mapping(server_prepared_snapshot)
job = JobContext("generation-preview-id", "preview-event-id", epoch=4, expected_version=2)
status = adapter.run("generate", principal, snapshot, job)  # 只预览
```

预览和正式执行必须用不同的任务及幂等键；正式执行前重新核验范围，冻结同一快照，再签发绑定本次 job/input_sha256/max_calls 的 `PaidAuthorization`。部署层提供 env_file；浏览器不能提供。不要使用先前授权代替新任务授权，也不要换新幂等键规避 unknown 请求或旧额度。

## 必须保留的边界和后续接线

1. **适配器不做登录或授予权限。** Principal、PaidAuthorization 和 callback 属于服务端受信对象；其类型或来源声明不是身份认证。产品须自己落实权限查询、授权签发、有效评分事件、课程/班级隔离以及数据库事务。
2. **结果返回还不等于业务应用。** 产品在应用 artifact_refs 时仍须事务内再次检查 epoch、版本和对象授权，用唯一事件键及 CAS 更新；适配器的回调不能代替数据库原子提交。重评分事件订阅者须持久化 correct_result 返回的 stale 状态。
3. **产物引用不是公开下载接口。** 后续产品只在授权读服务中解析 job 的白名单产物、核对 SHA-256 并按角色裁剪；本库没有暴露原始产物读取路由、prompt、trace 或参考答案。
4. **本版生成接教师明确目标入口。** 暂未实现完整推荐任务的 SQLite/上下文/历史快照复制和 `--recommendation-run` 交接，也未支持 usage_history、submission_run 或 verification_run。没有把 B 结果丢掉来源后伪装成完整交接；这些参数被严格白名单拒绝。正式 B 推荐本身可预览/受控调用，但“B 推荐 → 原封交接 → 出题”仍待接线和验收。
5. **初始画像入口只接最多 5 条 train 记录，增量最多 5 条 train/live 记录。** 下游仍使用研究自己的证据/来源/完整性校验；本次 fixture 只能做预览/假 transport 测试。客观题判分与简答教师评分不是 Java 源码，不得塞进 program；独立规则投影不替代 StudentProfile。
6. **unknown 不自动恢复。** 暂未开放 upstream --resume、取消正在进行的进程或未知请求调查界面；这些需要保留原检查点、预算和任务身份后另行设计。此处的拒绝重发是确定性检查，不是宣称已覆盖真实供应商故障恢复。
7. **真实模型仍未验收。** 真实 execute 路径的配置、供应商兼容性、模型语义质量、费用和网络失败均未验证。只在以后获得本次具体调用授权与安全配置后再做受控验收。研究画像旧推断纠错、Java 沙箱、真实学生教学效果也不在本次通过范围内。

部署应冻结研究源码和解释器，更新版本后创建新的适配器实例；不能在活动任务过程中替换源码或配置。配置文件存在状态不能显示为“AI 已接通”；只有受控实际响应可说明收到过模型响应，仍不表示内容正确或可自动发布。
