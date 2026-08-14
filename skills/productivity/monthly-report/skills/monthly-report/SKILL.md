---
name: monthly-report
description: Turn a month of stacked release notes (feat(vX.Y) blocks with Features / Fixes / Chores, requirement-doc links, dependency bumps) into a monthly work report that regroups everything by capability domain instead of by version. Trigger when the user pastes a pile of version changelogs and asks to summarize the month, asks for a monthly/period work summary or report, asks to follow the format of a previous month's report, or asks to refine an already-generated report (add missed items, merge sections, trim detail, strengthen the closing summary). Reads from tmp/work/i/<month>.md and writes to tmp/work/o/<month>.md by default. Skip for per-version release notes or changelogs aimed at end users — this produces the manager-facing monthly roll-up, not the changelog itself.
metadata:
  author: wudi
  version: "2026.08.13"
  source: https://github.com/WuChenDi/skills
---

# monthly-report

Turns a month of raw release notes into a monthly work report (月报). The input is version-ordered; the output is **capability-domain-ordered**. That regrouping is the entire value of this skill — a report that walks v2.2, v2.3, v2.4 in sequence is just the changelog again, and the reader learns nothing about what the month built.

Output language is **Chinese**, because that is what the report is written in. Section headings below are literal output text, not instructions.

## Step 0 — Locate input and output

Default convention:

| | Path |
| --- | --- |
| Input | `tmp/work/i/<month>.md` — e.g. `5.md` for May |
| Output | `tmp/work/o/<month>.md` |

If the user pastes the content directly, use that. If a prior month's output exists (`tmp/work/o/<month-1>.md`), **read it first** — it is the format contract. Match its heading scheme, section ordering, and level of detail rather than the template below.

Work the user mentions in chat but that is absent from the changelog (a side deliverable, another repo, a mini-program, cross-team work) still belongs in the report. It usually becomes its own late section — see `o/5.md`'s 微信媒资小程序 section, which had no counterpart in the input.

## Step 1 — Parse the version blocks

Each input unit looks like:

```
feat(v2.5): 需求迭代
- 需求文档: <飞书链接>
### Features / Fixes / Chores / 影响范围
```

Extract per block:

- **Version number** — collect all of them; the span (min → max) opens the report.
- **Feature items** — the substance.
- **Fix items** — collapse later, do not report individually.
- **Dependency bumps** — strip every version number, keep only the ecosystem names.
- **需求文档 links** — drop entirely. They do not appear in the report.
- **影响范围** — do not report as its own section; use it to decide which capability domain an item belongs to.

## Step 2 — Regroup by capability domain

Cluster every feature item into 5–9 domains. Domains recur month to month — reuse the names the previous report used so consecutive months are comparable. Recurring examples from past reports:

剧本体系 / 资产管理体系 / 分镜与创作体系 / 视频创作与 Agent 能力 / 公共组件与创作体验 / 平台运营与权限能力 / 技术优化与依赖升级

Rules:

1. **Section titles carry the version span they cover**, e.g. `## 三、视频创作与 Agent 能力增强（v2.2 ~ v2.6.1）`. One domain routinely spans several versions — that is the point.
2. **Order by weight, not by version.** The month's flagship build (a new module, a new project type) comes early, marked `（核心）` on its subsection.
3. **Two levels inside a section**: numbered themes (`### 1. 剧本创作能力升级`), then `*` bullets for concrete items. Do not go deeper than one bullet nest.
4. **技术优化与依赖升级 is always the last content section**, before the summaries.
5. A domain with one thin bullet is not a domain — fold it into a neighbour.

## Step 3 — Rewrite each item

| Raw input | Report line |
| --- | --- |
| `使用formatCurrency函数替代硬编码货币格式` | `使用统一货币格式化方案提升可维护性` |
| `新增useForbidden越权拦截hook` | `新增 useForbidden 越权拦截 Hook`（basic infra stays literal） |
| Twelve `Fixes` bullets | `### 3. 系统稳定性优化` with 3–4 merged lines |
| `next: 16.2.4 → 16.2.6`, `zustand: 5.0.12 → 5.0.13`, … | `持续升级核心依赖：` + bare list `Next.js / Zustand / TipTap / …` |
| `将"融合生图"替换为"首帧图"` | State the unified term, then use only that term everywhere else in the report |

- Mechanism → capability. The reader wants what the platform can now do, not which function was called.
- Keep item lines short and verb-first. No paragraphs inside bullets.
- Keep real identifiers (`IKMediaUpload`, `useForbidden`, `Seedance 2.0`, `Agent2.0`) — they are how the team names things. Wrap code identifiers in backticks.
- Never invent metrics. This report format carries no numbers beyond version numbers, 集数/字符 limits and similar facts already present in the input.
- Drop pure noise: 内部链接、`Zone.Identifier`、格式化提交、typo 修复.

## Step 4 — Assemble

```markdown
# <月份中文>工作总结

## 一、版本迭代与核心能力建设

本月完成 **v<最低版本> → v<最高版本> 多版本连续迭代**，重点围绕 **<能力域A、能力域B、能力域C、能力域D、能力域E>** 展开，<一句平台演进判断>。

## 二、<能力域A>（v_ ~ v_）

### 1. <主题>

* <条目>
* <条目>

### 2. <主题>（核心）

...

## <…重复至最后一个能力域…>

## <N>、技术优化与依赖升级

### 1. 架构与组件优化

* <条目>

### 2. 基础设施升级

持续升级核心依赖：

* Next.js
* <其余生态名，不带版本号>

## <N+1>、阶段成果总结

* 完成 **v_ → v_ 多版本持续迭代**
* <每条对应一个能力域的落地结果，7–10 条>

## <N+2>、总结

本月重点完成从「<起点能力>」到「<终点能力>」的升级，<构建/补齐了什么链路>。同时通过 <次要能力>，进一步完善 <体系>，为后续 <方向> 奠定基础。
```

Formatting conventions, held constant across months:

- Chinese numeral headings（一、二、三…）at `##`; Arabic numbered themes at `###`.
- Bold only for version spans, capability-domain phrases in the opening paragraph, and 阶段成果总结's version line.
- `（核心）` marks at most two subsections per report.
- 阶段成果总结 restates outcomes as flat bullets; 总结 is one narrative paragraph. Both are required — they are what the reader actually reads.

## Step 5 — Refine on request

The first draft is a starting point; the user iterates on it. Common follow-ups and how to handle them:

- **Add missed work** — new items go into an existing domain if one fits; a genuinely new area gets its own section placed by weight, and 阶段成果总结 + 总结 must be updated to match. Never append a stray section without touching the two summaries.
- **Trim detail** — thin out by merging bullets within a theme, not by deleting whole themes; a dropped theme reads as work not done.
- **Merge or split sections** — after any restructure, renumber the Chinese numeral headings and re-check every version span.
- **Strengthen the closing** — rewrite 总结 only. Do not inflate individual bullets with 大幅提升 / 显著优化 to compensate.
- **Change the medium** (HTML, speaking notes, slide outline) — keep the same section tree and wording; only the rendering changes.

Rewrite the output file in place each round so `tmp/work/o/<month>.md` is always the current version.

## Anti-patterns

- **One section per version.** `## 二、v2.2` `## 三、v2.3` — this is the failure mode the whole skill exists to prevent.
- **Dependency lines with version numbers.** `next: 16.2.4 → 16.2.6` belongs in the changelog, not the report. Names only.
- **Reporting fixes one by one.** Twelve bug-fix bullets crowd out the month's actual build. Merge into 3–4 stability lines.
- **Keeping requirement-doc links.** Internal wiki links are input metadata, not report content.
- **Inventing data.** No percentages, no efficiency gains, no user counts — the input never contains them.
- **A new skeleton every month.** The value of a fixed format is month-over-month comparability. Follow the previous report even when a different structure looks better.
