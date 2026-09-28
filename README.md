# Systolic Array UVM Verification

矩阵乘法脉动阵列的 UVM 验证项目，目标覆盖阵列模块和带 FIFO 的双时钟子系统。

目标运算：`A[N][M] × B[M][N] = C[N][N]`，矩阵元素为有符号数。题目只提供 PDF，不要求实现 DUT RTL。

## 当前状态

已开始把教学示例整理为正式的共用 UVM 核心。**正式核心尚未编译或进行 UVM 仿真；两个层级的完整 testbench 尚未完成。**

| 部分 | 当前状态 |
| --- | --- |
| `tb/common` | 参数化 transaction、结果对象、参考模型和 scoreboard 已整理，完成静态复查 |
| `tb/tests`、`tb/top` | 五个确定性组件自测已写，尚未运行 |
| `sim`、`scripts`、`Makefile` | 源文件清单、单文件打包、测试入口和日志检查工具已建立 |
| 普通 SystemVerilog 基线 | Icarus 实跑 8 项，结果符合预期；它们测试教学示例，不执行新 UVM 核心 |
| 两级 UVM agent / environment | 尚未正式接入 driver、monitor、sequencer |
| 连续计算、双缓冲、双时钟及随机回归 | 尚未完成 |

## 项目结构

```text
tb/common/       共用矩阵对象、参考模型、预测对象及 scoreboard
tb/tests/        共用核心的五个组件自测
tb/top/          组件自测顶层 matrix_core_tb
sim/core.f       正式核心编译顺序
scripts/         打包、运行、日志检查及工具单测
docs/            验证计划、结构说明、未定规格
lessons/         保留的逐步教学示例
build/           本地生成文件（忽略）
sim/results/     本地实际运行记录（忽略）
```

类参数 `W` 对应题目的 `DIN_WIDTH`。当前 `N`、`M` 是类型参数；尚未实现子系统运行时 `M_minus_one` 的处理。

## 检查和运行

在项目根目录执行，需要 Python 3.10 或更新版本：

```sh
make source-check  # 检查文件清单和 include，不是 SV 语法编译
make bundle        # 生成 build/core_bundle.sv
make tools-test    # Python 工具单测，不运行 UVM
make local-check   # 用已有 Icarus/VVP 运行 8 项普通 SV 基线
make core          # 有 Questa/UVM 环境时运行正式核心 smoke test
```

其他组件自测：

```sh
make core TEST=matrix_core_output_first_test
make core TEST=matrix_core_snapshot_test
make core TEST=matrix_core_wrong_result_test
make core TEST=matrix_core_missing_result_test
```

当前本机没有 `vlib`、`vlog`、`vsim`，`make core` 会明确报告 `NOT_RUN` 并返回非零。Questa 适配器尚未在真实 Questa 环境中试运行，需要已有的工具、UVM 库及许可证；可通过 `UVM_LIBRARY` 指定库。其他 UVM 仿真环境可使用打包文件，顶层为 `matrix_core_tb`，通过 `+UVM_TESTNAME=<测试名>` 选择测试。

错值和缺结果是故意注入错误的负测，UVM 应报告失败；只有指定诊断、完成标记及全部计数符合预期，运行脚本才记录 `EXPECTED_FAILURE_CAUGHT`。编译失败、超时和其他报错都不能算负测通过。

普通 SV 基线的实际命令、返回码和日志位置见本地 `sim/results/local-baseline/run.json`。Python 日志解析单测使用明确标注的合成文本，不是 UVM 仿真证据。

## 文档

- [验证计划](docs/verification-plan.md)：验证范围、两级组件复用、测试阶段及通过标准。
- [共用核心结构](docs/core-architecture.md)：对象流向、队列配对、组件自测及当前验证边界。
- [待确认规格](docs/spec-questions.md)：帧边界、输出对齐、累加位宽、FIFO 和时钟协议。
- [教学记录](lessons/README.md)：此前逐步实现与普通 SV 演示。

## 开发路线

1. 整理共用核心并保留可重复运行的本地基线（当前里程碑）。
2. 把未明确的接口协议写成可替换的实现假设，先确定一个最小配置。
3. 正式接入阵列级 driver、monitor、sequencer 和 environment，复用共用核心。
4. 验证连续矩阵计算及权重双缓冲切换。
5. 扩展子系统 FIFO 接口、参数组合、时钟关系和约束随机测试。
6. 生成仿真日志、覆盖率结果和波形说明。

## 设计原则

- 共用矩阵 transaction、数学参考模型、scoreboard 和高层测试场景。
- 阵列端口与 FIFO 接口分别实现 driver、monitor 和数据重组逻辑。
- 参考模型依据实际接收的输入生成预期结果。
- 必需的数学参考模型与可选的 DUT 行为模型保持独立。
- 没有真实 RTL 时，模型演示的通过不能代表 RTL 已验证。

当前测试只检查共用组件，输出来自独立的已知数值 fixture。后续若加入自建行为模型，将明确标注接口假设和模型限制。
