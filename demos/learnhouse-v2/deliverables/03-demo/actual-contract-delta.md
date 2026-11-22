# V2 Demo 与阶段二契约差异

日期：2026-11-20。冻结设计保留在 `../02-design/openapi.json`，不覆盖原审定版本。业务模块已实现 30 个冻结路由，其余登录会话、笔记与管理路由由独立模块提供。完整范围参见 [业务实现说明](business-implementation.md)，真实验收参见 `../05-demo-acceptance/http-results.json`。

## 请求契约

业务请求字段、严格附加字段限制、UUID/时间/类型均按冻结 JSON Schema 校验。新增语义检查：量规条目唯一且各题/总分一致；来源引用有当前同课访问权并匹配内容哈希；客观答案类型及单选选项有效。

## 响应差异

1. CourseDetail 增加 knowledge_points；bindings 返回 BindingView，并同时给 id/binding_id。章节重排未接通，chapters 暂为空。
2. 资源概览增加 title/kind；教师资源详情增加 version_history。详情内 checks/publication_events 是页面需要的检查/最新班级发布摘要，不等同于单独创建接口的完整 CheckView/PublicationView。
3. BindingView 增加 description、maximum_score、question_content、recipients/answer_key；学生 answer_key 受答案释放策略限制，未开始且资料已撤回时正文为空并返回 content_access=withdrawn。
4. AttemptView 增加 question_content、draft_hash；SubmissionView 增加 course_id、recipient_id、question_content；GradeView 增加 feedback 对象以及数据库身份元数据。学生不会收到 candidate_evaluations。
5. ReviewView 增加 created_at，etag 使用所属提交当前有效成绩 revision，resolution 必须同时提交 expected_grade_revision。
6. TaskRefs 增加 resource_id/resource_version_id 便于页面跳转，管理员 result_refs 固定裁剪为 {}，没有 input_refs、学生作答或候选内容。
7. 检查创建结果已使用 CheckItem 数组；发布创建结果返回发布字段与资源版本 etag。补交授权创建和支持记录创建目前返回数据库事实字段，尚未完成正式视图裁剪（如授权 used_slots/etag 聚合），前端以创建成功后重新读取 BindingView 为准。
8. 列表响应使用 page。小样本演示没有游标分页，统一 has_more=false、next_cursor=null；正式多班级上线必须补充分页与查询上限。
9. 学情证据同时提供原 summary 对象、summary_text 和按当前 evidence.read 授权计算的 content_access；前端无需推断分数含义。

## 策略执行约定

本 Demo 同一策略作用域只允许一个家族：全局作用域一个、每课程作用域各一个；后续变更在原家族追加版本，禁止另起家族造成“当前策略”歧义。新增命令使用当前课程唯一策略家族的最新版本；旧绑定作答、评分与复核沿用冻结规则。策略并非只存储：生成方式/预算/次数、标准必需检查、强制人工、模板快速发布许可及新作业复核开关均在服务端执行。require_human_review=true 不受 allow_rule_auto_publish=true 豁免。布置时保存当前实际检查与规则快照。具体检查适用范围见业务实现说明；真值检查不会把任意教师题干标成语义已验证。

## 能力收窄与错误返回

- 全局策略升级后，课程策略父版本过期时，新教学写命令返回 POLICY_PARENT_STALE，须先追加对齐当前全局规则的课程策略；历史绑定的作答/评分不受影响。
- POST courses 未实现；课程与权限由 Demo seed 配置。
- PATCH course 只支持名称、说明、学习目标，章节顺序/策略变更拒绝。
- 资料输入只支持文本。固定模板只覆盖 Java 布尔表达式示例，选择资料不代表进行语义生成。
- research_generator/AI 评分返回未接通/未配置。任务 retry 返回 RESEARCH_RETRY_UNAVAILABLE；技术取消只阻止结果应用。
- 干预仅 record_support 可用，assign_next/adjust_next 返回 INTERVENTION_ASSIGNMENT_NOT_CONNECTED；通过独立布置作业流程安排任务。
- 学情只提供有效成绩证据与统计，知识掌握状态 unknown。推荐是课程截止时间规则，研究状态明确未接通。

以上属于可验证的本地 Demo 实现范围；不是“41 个冻结接口和全部研究能力均已完整实现”的声明。
