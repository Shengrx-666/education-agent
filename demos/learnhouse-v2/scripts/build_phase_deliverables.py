"""Build reviewable Word documents, an Excel handoff and a local delivery index."""
from pathlib import Path
import io
import json
import hashlib
import subprocess
import zipfile
from html import escape
from lxml import etree as E
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Alignment
from openpyxl.utils import get_column_letter

ROOT = Path(__file__).resolve().parents[1]
D = ROOT / 'deliverables'
A = D / 'assets'
A.mkdir(exist_ok=True)
DB = json.loads((D/'02-design/data-dictionary.json').read_text())
API = json.loads((D/'02-design/api-page-mapping.json').read_text())
SQLQA = json.loads((D/'02-design/validation-summary.json').read_text())
SPEC = json.loads((ROOT.parent/'product-design-v2/assets/spec-data.json').read_text())


def table(headers, rows):
    def cell(x):
        return str(x).replace('|', '/').replace('\n', '；')
    return '\n'.join(['| '+' | '.join(headers)+' |', '| '+' | '.join(['---']*len(headers))+' |'] +
                     ['| '+' | '.join(cell(c) for c in row)+' |' for row in rows])+'\n'


def diagram():
    parts = ['<svg xmlns="http://www.w3.org/2000/svg" width="960" height="960" viewBox="0 0 960 960"><defs><marker id="a" markerWidth="8" markerHeight="8" refX="7" refY="4" orient="auto"><path d="M0 0 L8 4 L0 8" fill="#41789d"/></marker></defs><rect width="960" height="960" fill="white"/><g font-family="Noto Sans CJK SC,sans-serif">']
    def text(x,y,s,size=23):
        parts.append('<text x="%s" y="%s" font-size="%s" fill="#173f60" text-anchor="middle">%s</text>'%(x,y,size,escape(s)))
    def box(x,y,w,h,lines):
        parts.append('<rect x="%s" y="%s" width="%s" height="%s" rx="12" fill="#eff5fa" stroke="#b6cbdc"/>'%(x,y,w,h))
        for i,line in enumerate(lines): text(x+w/2,y+h/2-(len(lines)-1)*16+8+i*32,line)
    def arrow(x,y,x2,y2):
        parts.append('<path d="M%s %s L%s %s" stroke="#41789d" fill="none" stroke-width="2" marker-end="url(#a)"/>'%(x,y,x2,y2))
    text(480,42,'数据主链与职责边界',30)
    text(480,78,'通用 LMS 身份复用；学习事实由 ea 扩展保存',22)
    box(40,105,880,90,['LearnHouse：组织、账号、课程、活动、班级、作业身份','public.* 是通用身份的唯一来源'])
    box(40,240,250,110,['内容与版本','resource / version','量规、检查、发布'])
    box(355,240,250,110,['一次布置','assignment_binding','接收人和规则冻结'])
    box(670,240,250,110,['尝试与提交','attempt / submission','提交后不可覆盖'])
    arrow(480,195,480,230);arrow(290,295,345,295);arrow(605,295,660,295)
    box(670,405,250,110,['评估与生效成绩','evaluation','grade_revision'])
    box(355,405,250,110,['证据事件','evidence_event','保留来源和授权'])
    box(40,405,250,110,['学习状态版本','profile_version','规则统计 / 研究画像'])
    arrow(795,350,795,395);arrow(670,460,615,460);arrow(355,460,300,460)
    box(40,570,250,110,['个性化推荐','recommendation','点击时再次鉴权'])
    box(355,570,565,110,['更正 / 撤权：新事件 → 新版本','历史保留；研究旧推断标为待重建','新成绩或撤权不改写既有模型事实'])
    arrow(165,515,165,560);arrow(637,570,637,545);arrow(637,545,480,525)
    box(40,735,880,90,['横向控制：principal / action_grant / policy_version','服务端对象鉴权；管理员没有默认教学正文权限'])
    box(40,855,880,70,['可靠性：task_run / outbox_event / audit_event'])
    parts.append('</g></svg>')
    (A/'data-flow.svg').write_text(''.join(parts))


foundation = '''# 阶段一：底座验证与复用决策

日期：2026年11月20日　｜　产品基线：教育智能体 V2.0

## 1. 结论与交付范围

LearnHouse 可以作为下一阶段改造的底座继续推进。已验证其固定源码版本的依赖安装、真实 PostgreSQL 空库初始化、原版账号登录生命周期及原版前端登录页面。本结论不等同于教育智能体 V2 功能或生产部署验收通过。

本轮沿用“学生端＋教师端＋管理后台”的产品范围。教师可参与内容审核、主观题批阅和教学干预；自动处理仅在明确策略和权限范围内执行。国产算力芯片不是硬性验收条件，训练或微调方式不预设。

## 2. 固定基线与可重现环境

'''+table(['对象','本次固定值','用途'],[
['LearnHouse','c76cf6f64ab71ed042fe83e985d9c4ab3fa148f5','LMS 与前端底座；apps/api、apps/web 1.4.5'],
['education-agent','099a875a0da7322964780a8973d4ced8c1f304ce','保留研究能力及实际模型/来源语义'],
['前端','Bun 1.4.4；Node 20.19.5；Next 16.4.6','按锁文件安装；Node 启动原版前端'],
['后端','Python 3.14.7；uv 0.13.9 工具','按 uv.lock 安装，未放宽应用依赖'],
['验证数据层','PostgreSQL 14.24；pgvector 0.8.1；Redis 6.0.16','本次隔离验证版本，不是生产版本选型承诺'],
['隔离方式','项目私有运行目录与 Unix socket','不覆盖原系统、不修改系统数据库服务'],
])+'''
前端安装了 1031 个锁定依赖。上游源代码未修改；运行目录、随机凭据、数据库、依赖缓存均不纳入交付压缩包。

## 3. 已取得的运行证据

'''+table(['检查','结果','证据及边界'],[
['真实上游空库初始化','通过','106 张 public 表；Alembic 头 d8i2c3o4p5y6；非最小 stub'],
['API 登录生命周期','8/8 通过','健康、匿名拒绝、登录、HttpOnly、本人身份、外域请求拒绝、退出、退出后无会话'],
['原版前端 /login','HTTP 200','统一 localhost 监听与访问地址；浏览器结果见单独记录'],
['V2 扩展数据层','独立验证','26 张扩展表；详细结果在阶段二及 validation-summary.json'],
['研究适配器','30 项离线检查通过','四个真实 CLI 预览；执行测试使用明确标记的 fixture transport'],
])+'''
上游登录检查使用本地随机生成的验证账号，不代表 V2 学生、教师、管理员的对象权限已实现。退出后无会话检查不等同于保留旧 Cookie 后重放、撤销存储故障或多会话撤销均已验收。

## 4. 发现的问题与处理

'''+table(['发现','处理或决策','对后续工作的影响'],[
['pgvector 的可选提示与空库建表实际依赖不一致','补齐 pgvector 后初始化成功','将扩展列入完整数据库安装前置'],
['监听 127.0.0.1 时 Next 内部主机归一化引发自代理超时','统一使用 localhost，未修改业务源码','保留可复用启动脚本和失败日志'],
['上游 Admin/Maintainer/backoffice 权限过宽','V2 账号不得以这些角色代替产品授权','新增 action_grant；所有旧入口也必须管控'],
['作业 retry 覆盖/删除部分当前提交记录','不复用该写入语义','新增不可变尝试、提交及成绩修订链'],
['研究画像分析 Java 原始作答，不能直接接客观题分数','分开规则统计和研究画像','禁止把确定性统计标为 AI 研究成果'],
['研究增量不支持撤销旧推断','更正后研究状态标为待重建','有效成绩可重算；研究重建仍需专门实现'],
])+'''
## 5. 复用与改造界线

复用 LearnHouse 的账号、组织、课程、活动、班级、基础资源组织、私人笔记及界面组件。新增 ea 数据域、对象级授权、题目版本门禁、不可变作答和成绩、更正事件、研究接入以及教学成效验证。不把上游聊天功能等同于四项研究能力已完成。

LearnHouse 社区源码带 AGPL-3.0 许可；单独的企业组件不能因目录存在就视为社区授权。保留固定来源、许可文件和改动记录；本阶段仅本地验证，没有发布网站或向 GitHub 推送。正式交付和分发范围需要依据实际使用的组件核对，不能以“开源”代替许可边界检查。

## 6. 下一阶段准入

可以据本轮表结构与接口契约开始 V2 业务开发。进入完整 Demo 验收前，还必须补齐：V2 服务端权限及旧接口封锁、课程与班级装配、发布到作答再到反馈的业务闭环、真实研究任务接线、浏览器端到端测试。模型密钥和付费调用不因完成本地开发而自动获准。

相关证据位于本目录：底座源码与许可范围核查.md、database-bootstrap-evidence.json、api-smoke-results.json、frontend-browser-results.json、learnhouse-login.png。可重现启动脚本位于 scripts；依赖和私有凭据需在目标环境单独配置。
'''

design = '''# 阶段二：数据库与接口设计说明书

日期：2026年11月20日　｜　状态：供开发实施的设计基线，非已上线功能说明

## 1. 顶层目标与设计决策

在 LearnHouse 通用教学底座上形成“内容生成与审核 → 发布和布置 → 学习作答 → 评估反馈 → 状态更新 → 推荐与教师干预”的可追溯闭环。学生、教师、管理员使用真实身份和服务端授权；管理权限不自动包含教学正文权限。

本轮扩展表统一使用 ea 命名空间，避免与上游同类记录形成双向权威。上游账号、课程、班级和作业的整数主键保留；扩展业务对象使用 UUID，审计 BIGINT 对前端以十进制字符串表达。所有业务时间采用 UTC timestamptz，显示时按用户时区转换。

设计交付包括 '''+str(len(DB['tables']))+' 张表、'+str(sum(len(t['columns']) for t in DB['tables']))+' 个字段、'+str(API['operation_count'])+''' 个扩展 API 操作及 28 个页面的接口映射。完整 DDL、OpenAPI、字段字典、ER 源文件和离线验证脚本随包提供。

## 2. 数据主链

![图1 数据主链与职责边界](../assets/data-flow.png){width=5.2in}

图示为主要业务关系；全部 26 张扩展表及关系见 er.mmd，字段、外键、索引和检查约束以 schema.sql 为准。

## 3. 表清单与权威来源

'''+table(['表名','职责','修改约束'],[[t['name'],t['purpose'],{'append_only':'只追加','state_columns_only':'有限状态字段','private_draft_then_immutable':'私人草稿可改；提交冻结'}.get(t['mutability'],t['mutability'])] for t in DB['tables']])+'''
组织、账号、角色、课程、活动、班级、班级当前成员、作业身份和私人笔记正文继续由 public 表承接。历史接收人快照不能代替当前成员权限。退班后保留历史事实，同时拒绝新增访问；正文、附件下载、检索引用和旧 LMS 接口必须执行相同边界。

## 4. 关键业务规则

1. **版本冻结。** 布置冻结题面、答案、量规、策略和时间规则；旧提交不随新版本题面变化。研究生成内容维持强制复核，换版本不得清除门禁。默认自动发布路径只接经过明确检查的规则模板。
2. **作答不可覆盖。** 草稿可保存，正式提交追加一次；订正新建 attempt。重复点击通过幂等回执返回已有结果，冲突输入不得覆盖旧答案。
3. **评分建议与生效结果分离。** AI 建议不是最终成绩；每次改分追加 grade_revision 并保留理由。旧成绩节点不可删除或原地修改。工具失败不直接判错。
4. **补交有范围和时限。** 授权绑定学生、布置、截止时间和次数；超时或撤销后不能开始或提交新尝试。数据约束与服务端当前权限检查同时生效。
5. **笔记用途独立。** 私人阅读、共享给指定教师、用于画像三者不能互相推定。仅共享阅读不要求进入画像；撤销画像用途产生通用更正事件，可形成新版本，不能伪造一条新成绩。
6. **证据和研究状态分离。** 真实学生证据、历史证据、演示数据、规则统计、模型推断、工具观察保留原来源。生成题和参考答案不能自动构成掌握证据；未知不等于不会。
7. **异步结果重新核验。** 任务持有预算、租约、epoch 和冻结输入；应用结果前重新鉴权并核对版本。业务事件与 outbox 同事务提交；至少一次投递由消费幂等保证，不声称 exactly once。
8. **并发控制不是文档声明。** 唯一键和触发器已做隔离库检查；真实多连接竞争、worker 租约、事务 CAS 与迟到回调仍须在 API 实现阶段测试。

## 5. 接口约定与页面对应

统一前缀为 /api/v1/education。账号登录、刷新和退出复用 LearnHouse 原协议；扩展接口不另设假登录、不接受客户端自选用户身份。所有新增操作仍处于设计状态，OpenAPI 的存在不代表服务已经可调用。

每个操作声明页面编号、动作权限、涉及表和事务前置。写操作统一处理幂等键、预期版本、当前授权、来源门禁与审计。当前核心操作如下，详细请求、响应、错误码和示例见 openapi.json 与接口工作簿。

'''+table(['编号／方法','用途','页面'],[['API%02d '%(i+1)+o['method'],o['summary'],' / '.join(o['pages'])] for i,o in enumerate(API['operations'])])+'''
GET 请求也必须裁剪参考答案、他人作答、个人笔记、模型原始提示及密钥。学生只看到本人当前有权访问的已发布内容；教师按课程、班级及动作范围读取；管理员默认只接权限、策略、任务元数据和审计元数据。仅隐藏前端按钮不能满足权限验收。

## 6. 研究能力接线与明确差异

现有研究仓库固定到 099a875a。适配器支持 generate、profile、update、recommend 四种受控入口，默认只预览；已有 30 项离线检查，其中四种真实 CLI preview 通过，真实模型没有调用。

研究生成必须明确被授权的目标学生、非空知识点集合和模型请求次数预算。产品知识点 UUID 必须映射到研究目录的 code/version；整数用户 ID 必须经过绑定映射，不能用教师 ID 或假学生凑齐研究输入。教师明确目标出题已定义；完整 B 推荐历史向生成器的原样交接仍待接线。

客观题评分与教师评语不会直接变成 Java 原始作答。课程规则统计与研究画像用不同方法标记；当前研究不支持撤销旧推断，评分更正和笔记撤权后将研究状态标为 stale/待重建。不得将旧画像改标为新结果。

现适配器不支持原任务增加 epoch 后直接重跑研究任务，也没有供应商未知响应的自动恢复能力。研究重试操作暂时拒绝并在界面禁用；后续需要保留原检查点、输入、模型、预算和任务身份后设计恢复。未知请求不得靠换幂等键反复调用。

真实执行需要服务器受信授权与私有配置。请求次数上限不是人民币费用上限。不得把配置文件存在、假 transport 测试或界面成功提示写成“模型已接通”或“研究效果已验证”。

## 7. 迁移与验收

schema.sql 是一次性事务 DDL，面向固定 LearnHouse 版本与 PostgreSQL 14+；新增上游复合唯一索引以支持跨组织、课程和学生的外键一致性。首次迁移先做备份、前置检查和空库验证，禁止对未知版本直接运行。已有真实数据时优先前向修复，不通过 DROP CASCADE 或停用约束“回滚”。

本轮已执行隔离 PostgreSQL DDL 和 '''+str(SQLQA['passed_assertions'])+''' 项正反例断言；最小上游结构 stub 测试数据最终全部回滚。另外，将真实 LearnHouse 106 张表的无数据结构副本恢复到独立空库，执行同一 DDL 成功提交，形成 public 106 表及 ea 26 表。没有复制业务数据或修改原库；此结果仍不能代表有数据升级、HTTP 权限及多连接并发已通过。详情见 validation-summary.json。

下一阶段按页面编号实施接口和前端，先完成一门课程的纵向闭环，再扩到全部页面。交付验收必须覆盖学生 A/B、教师甲/乙、管理员、过期会话、退班、撤权、跨课程 ID 替换、附件和旧接口旁路、双击提交、并发改分、迟到任务及恢复场景。

## 8. 绝对禁止事项

- 禁止在业务代码中调用 System.exit 或使用同类进程终止方式处理普通业务错误。
- 禁止拼接外部输入构造 SQL；必须参数绑定，动态标识符仅使用预先限定的安全映射。
- 禁止把密码、令牌、API Key 或私钥写死在代码、前端包、文档或日志中。
- 禁止新增已废弃 API；锁定依赖，按实际版本文档实现，不以忽略错误代替兼容修复。
- 禁止绕过 TLS 证书校验、对象鉴权、来源校验、预算门槛、强制复核或任务版本检查。
- 禁止在宿主机无人值守执行学生代码；本轮没有运行 Java 或任意学生程序。
- 禁止覆盖原始作答、改写旧评分与旧模型事实，或将演示数据伪装为真实学习证据。
- 禁止把仅页面演示、schema 检查、规则结果或模拟传输说成真实 AI 接通与研究成效。
- 禁止将管理员默认放开为全部正文读取，或仅用前端角色切换实现权限。
- 禁止无上限重试、未知请求自动重发、无限模型循环和因版本更新重置历史预算。

## 9. 配套文件

字段与索引：schema.sql、data-dictionary.json、数据库与接口交付清单.xlsx；接口：openapi.json、api-contract.md、api-page-mapping.json；关系：er.mmd；研究：research-integration-contract.md、research-adapter-status.md；检查：validation-summary.json、contract-cross-review.md。
'''

def write_sources():
    (D/'01-foundation/阶段一_底座验证报告.md').write_text(foundation)
    (D/'02-design/阶段二_数据库与接口设计说明书.md').write_text(design)


def workbook():
    wb=Workbook();wb.remove(wb.active)
    def sheet(name,headers,rows,widths):
        ws=wb.create_sheet(name);ws.append(headers)
        for r in rows: ws.append([str(x) if isinstance(x,(list,dict)) else x for x in r])
        ws.freeze_panes='A2';ws.auto_filter.ref=ws.dimensions
        for i,w in enumerate(widths,1):ws.column_dimensions[get_column_letter(i)].width=w
        for row in ws:
            for c in row:
                c.font=Font(name='等线',size=10,color='FFFFFF' if c.row==1 else '18384E',bold=c.row==1)
                c.alignment=Alignment(vertical='top',wrap_text=True)
                if c.row==1:c.fill=PatternFill('solid',fgColor='234F72')
                elif c.row%2==0:c.fill=PatternFill('solid',fgColor='EFF5FA')
            ws.row_dimensions[row[0].row].height=30 if row[0].row==1 else 48
        ws.sheet_properties.pageSetUpPr.fitToPage=True
        ws.page_setup.orientation='landscape';ws.page_setup.paperSize=ws.PAPERSIZE_A3
        ws.page_setup.fitToWidth=1;ws.page_setup.fitToHeight=0
        ws.print_title_rows='1:1'
    sheet('说明',['项目','内容'],[
        ['版本','2026-11-20 / V2 设计；不是已上线功能'],
        ['表/字段',str(len(DB['tables']))+' / '+str(sum(len(t['columns']) for t in DB['tables']))],
        ['扩展操作',API['operation_count']],['实际实施范围','完整范围与待完成边界见说明书、API契约和验收记录'],
        ['数据库依据','schema.sql SHA256: '+hashlib.sha256((D/'02-design/schema.sql').read_bytes()).hexdigest()],
        ['上游','LearnHouse '+DB['upstream_commit']],
        ['使用方式','按页面→接口→对象→字段追踪；约束和枚举以SQL/OpenAPI为准']], [22,115])
    sheet('表清单',['表','用途','修改语义','字段数'],[[t['name'],t['purpose'],t['mutability'],len(t['columns'])] for t in DB['tables']], [34,82,30,12])
    rows=[]
    for t in DB['tables']:
        for c in t['columns']:rows.append([t['name'],c['name'],c['type'],'是' if c['nullable'] else '否',c.get('default_sql'),c['description'],c['classification'],c['definition_sql']])
    sheet('字段字典',['表','字段','类型','可空','默认值','中文说明','数据分类','SQL定义'],rows,[32,28,22,9,30,70,25,100])
    rows=[]
    for t in DB['tables']:
        for k in ['constraints_sql','indexes_sql']:
            for s in t.get(k,[]):rows.append([t['name'],'约束' if k=='constraints_sql' else '索引',s])
    sheet('约束与索引',['表','类型','定义'],rows,[34,12,145])
    sheet('API清单',['编号','操作','方法','路径','用途','页面','权限','请求','响应','事务前置'],[['API%02d'%(i+1),o['operationId'],o['method'],o['path'],o['summary'],', '.join(o['pages']),o['permission'],o['request_schema'],o['response_schema'],o['preconditions']] for i,o in enumerate(API['operations'])],[12,35,12,72,48,24,48,32,32,100])
    sheet('页面接线',['页面','名称','页面路径','分期','扩展接口','复用上游接口','边界'],[[p['page_id'],p['name'],p['ui_path'],p['scope'],', '.join(p['operation_ids']),'; '.join(p['reused_upstream_operations']),'; '.join(p['explicit_boundaries'])] for p in API['pages']],[12,25,68,12,75,85,110])
    sheet('阶段验收',['阶段','交付物','验收口径','状态'],[
        ['1 底座验证','报告/固定版本/运行证据','原版登录、数据初始化；不代表V2权限','本轮完成'],
        ['2 数据与接口','26表/字段/DDL/ER/OpenAPI/页面映射','设计+隔离库检查；不代表API实现','本轮完成'],
        ['3 V2 Demo','源码/启动说明/演示数据/演示录屏或截图','教师发布→学生提交→批阅→状态反馈；显示能力实况','待实施；研究适配器已预研'],
        ['4 集成验收','权限/并发/研究结果/问题单/发布包','真实接口、真实授权范围；模型调用另按具体授权','已编制检查项，待执行']], [20,65,100,45])
    runtime=json.loads((D/'02-design/openapi.json').read_text())['x-required-runtime-acceptance']
    sheet('集成验收待执行',['用例','场景','预期','本轮状态'],[[r['case'],r['scenario'],r['expected'],'待执行；本轮仅定义'] for r in runtime],[38,95,100,30])
    output=D/'02-design/数据库与接口交付清单.xlsx';wb.save(output)


WNS='http://schemas.openxmlformats.org/wordprocessingml/2006/main'; W='{'+WNS+'}'
def child(p,n):
    x=p.find(W+n)
    if x is None:x=E.SubElement(p,W+n)
    return x
def attr(e,**kw):
    for k,v in kw.items():e.set(W+k,str(v))
def xml(e):return E.tostring(e,encoding='UTF-8',xml_declaration=True,standalone=True)
def font(p,size=21,color=None):
    attr(child(p,'rFonts'),ascii='Calibri',hAnsi='Calibri',eastAsia='Noto Sans CJK SC');attr(child(p,'sz'),val=size)
    if color:attr(child(p,'color'),val=color)


def export_doc(source,title):
    pandoc='/home/hongjian/anaconda3/bin/pandoc'
    raw=subprocess.check_output([pandoc,'--print-default-data-file','reference.docx'])
    with zipfile.ZipFile(io.BytesIO(raw)) as z:parts={n:z.read(n) for n in z.namelist()}
    styles=E.fromstring(parts['word/styles.xml'])
    for s in styles.findall(W+'style'):
        sid=s.get(W+'styleId');sz={'Title':34,'Subtitle':24,'Heading1':27,'Heading2':24,'Heading3':22}.get(sid,21)
        font(child(s,'rPr'),sz,'173F60' if sid.startswith('Heading') else None)
        pp=child(s,'pPr');attr(child(pp,'spacing'),after=100,line=280,lineRule='auto')
        if sid.startswith('Heading'):child(pp,'keepNext')
    parts['word/styles.xml']=xml(styles)
    reference=A/'reference.docx'
    with zipfile.ZipFile(reference,'w',zipfile.ZIP_DEFLATED) as z:
        for n,b in parts.items():z.writestr(n,b)
    output=source.with_suffix('.docx')
    subprocess.run([pandoc,str(source),'-o',str(output),'--reference-doc',str(reference),'--resource-path',str(source.parent),'--metadata','lang=zh-CN'],check=True)
    with zipfile.ZipFile(output) as z:parts={n:z.read(n) for n in z.namelist()}
    doc=E.fromstring(parts['word/document.xml'])
    for s in doc.iter(W+'sectPr'):
        attr(child(s,'pgSz'),w=11906,h=16838);attr(child(s,'pgMar'),top=980,bottom=980,left=980,right=980,header=400,footer=400)
        footer=child(s,'footerReference');attr(footer,type='default')
        footer.set('{http://schemas.openxmlformats.org/officeDocument/2006/relationships}id','rIdPhaseFooter')
    for tb in doc.iter(W+'tbl'):
        rows=tb.findall(W+'tr');cols=len(rows[0].findall(W+'tc'));ratios={2:[28,72],3:[29,49,22],4:[20,40,25,15]}.get(cols,[100/cols]*cols)
        widths=[int(9946*r/100) for r in ratios];widths[-1]+=9946-sum(widths)
        pr=child(tb,'tblPr');attr(child(pr,'tblW'),w=9946,type='dxa');attr(child(pr,'tblLayout'),type='fixed')
        grid=child(tb,'tblGrid')
        for c in list(grid):grid.remove(c)
        for w in widths:attr(E.SubElement(grid,W+'gridCol'),w=w)
        borders=child(pr,'tblBorders')
        for edge in ['top','bottom','left','right','insideH','insideV']:attr(child(borders,edge),val='single',sz=4,color='C7D5E1')
        for i,row in enumerate(rows):
            child(child(row,'trPr'),'cantSplit')
            if i==0:child(child(row,'trPr'),'tblHeader')
            for c,w in zip(row.findall(W+'tc'),widths):
                attr(child(child(c,'tcPr'),'tcW'),w=w,type='dxa')
                if i%2==0:attr(child(child(c,'tcPr'),'shd'),fill='E8F0F8' if i==0 else 'F4F7FA')
                for p in c.iter(W+'p'):attr(child(child(p,'pPr'),'spacing'),after=65,line=250,lineRule='auto')
                for r in c.iter(W+'r'):
                    font(child(r,'rPr'),18)
                    if i==0:child(child(r,'rPr'),'b')
    parts['word/document.xml']=xml(doc)
    footer=E.Element(W+'ftr',nsmap={'w':WNS});p=E.SubElement(footer,W+'p');attr(child(child(p,'pPr'),'jc'),val='center')
    r=E.SubElement(p,W+'r');font(child(r,'rPr'),16,'617487');E.SubElement(r,W+'t').text='教育智能体 V2 · 2026-11-20  |  '
    fld=E.SubElement(p,W+'fldSimple');attr(fld,instr='PAGE');E.SubElement(E.SubElement(fld,W+'r'),W+'t').text='1'
    parts['word/footer-phase.xml']=xml(footer)
    rels=E.fromstring(parts['word/_rels/document.xml.rels']);rn='{http://schemas.openxmlformats.org/package/2006/relationships}'
    E.SubElement(rels,rn+'Relationship',Id='rIdPhaseFooter',Type='http://schemas.openxmlformats.org/officeDocument/2006/relationships/footer',Target='footer-phase.xml')
    parts['word/_rels/document.xml.rels']=xml(rels)
    ct=E.fromstring(parts['[Content_Types].xml']);E.SubElement(ct,'{http://schemas.openxmlformats.org/package/2006/content-types}Override',PartName='/word/footer-phase.xml',ContentType='application/vnd.openxmlformats-officedocument.wordprocessingml.footer+xml')
    parts['[Content_Types].xml']=xml(ct)
    with zipfile.ZipFile(output,'w',zipfile.ZIP_DEFLATED) as z:
        for n,b in parts.items():z.writestr(n,b)
    print(output.relative_to(ROOT))


if __name__=='__main__':
    import sys
    diagram();write_sources();workbook()
    if '--documents' in sys.argv:
        for folder,name in [('01-foundation','阶段一_底座验证报告'),('02-design','阶段二_数据库与接口设计说明书')]:
            export_doc(D/folder/(name+'.md'),name)
