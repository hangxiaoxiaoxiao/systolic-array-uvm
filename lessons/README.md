# 分步练习

这些文件是教学练习，不是完整的 UVM testbench，也没有连接面试方的 RTL。

| 文件 | 本步内容 | 当前运行状态 |
| --- | --- | --- |
| [01_matrix_ref_demo.sv](01_matrix_ref_demo.sv) | 计算一个 C 元素 | Icarus 13.0 已运行，结果为 -11 |
| [02_matrix_ref_loops.sv](02_matrix_ref_loops.sv) | 循环计算完整 2×2 结果 | 四个结果与手算一致 |
| [03_result_checker.sv](03_result_checker.sv) | 比较期望值和演示结果 | 正确数据通过；故意改错时按预期报错 |
| [04_reference_functions.sv](04_reference_functions.sv) | 将计算和检查封装成函数 | 两组数据通过；第二组故意改错时按预期报错 |
| [05_matrix_dimensions.sv](05_matrix_dimensions.sv) | N×M 乘 M×N | N=2/M=3 和 N=3/M=2 均通过已知答案检查 |
| [06_signed_widths.sv](06_signed_widths.sv) | 8 位有符号输入、16 位输出 | 负数及边界乘法通过；超出输出范围时按预期报错 |
| [07_uvm_matrix_item.sv](07_uvm_matrix_item.sv) | 创建保存 A/B 的 UVM 对象 | 尚未在 UVM 仿真器中编译或运行 |
| [08_uvm_random_item.sv](08_uvm_random_item.sv) | rand、constraint、randomize() | 尚未在 UVM 仿真器中编译或运行 |
| [09_uvm_item_reference.sv](09_uvm_item_reference.sv) | 把随机 transaction 交给参考函数计算期望值 | 尚未在 UVM 仿真器中编译或运行 |
| [10_uvm_sequence.sv](10_uvm_sequence.sv) | sequence 经 sequencer 向教学用 driver 提交三个 item | 尚未在 UVM 仿真器中编译或运行 |
| [11_array_interface.sv](11_array_interface.sv) | interface 集中声明并访问阵列接口信号 | Icarus 13.0 已编译运行，观察到 8/16 位元素及输入值 1、-2 |
| [12_virtual_interface.sv](12_virtual_interface.sv) | class 通过 virtual interface 访问实际信号 | Icarus 13.0 在虚接口声明处编译失败，最小例子复现；尚未仿真 |
| [13_uvm_config_db.sv](13_uvm_config_db.sv) | 顶层通过 config_db 把接口句柄传给 driver | 尚未在 UVM 仿真器中编译或运行 |
| [14_uvm_monitor.sv](14_uvm_monitor.sv) | monitor 与 driver 并行运行，通过同一个接口观察输入信号 | 尚未在 UVM 仿真器中编译或运行 |
| [15_uvm_sample_item.sv](15_uvm_sample_item.sv) | monitor 把当拍观察值封装成一个新的 signal_sample 对象 | 尚未在 UVM 仿真器中编译或运行 |
| [16_uvm_analysis_port.sv](16_uvm_analysis_port.sv) | monitor 经 analysis_port 把快照交给 receiver 的 write() | 尚未在 UVM 仿真器中编译或运行 |
| [17_uvm_scoreboard.sv](17_uvm_scoreboard.sv) | scoreboard 将两个固定输入快照与已知期望比较 | 正常与故意错误用例均尚未在 UVM 仿真器中编译或运行 |
| [18_uvm_matrix_scoreboard.sv](18_uvm_matrix_scoreboard.sv) | scoreboard 用 A/B 计算参考结果，与手工提供的 C_actual 逐元素比较 | 正常与故意错误用例均尚未在 UVM 仿真器中编译或运行 |
| [19_uvm_expected_queue.sv](19_uvm_expected_queue.sv) | 保存两组期望矩阵，按输入顺序与后续完整输出配对 | 正常与故意错误用例均尚未在 UVM 仿真器中编译或运行 |
| [20_uvm_two_analysis_inputs.sv](20_uvm_two_analysis_inputs.sv) | 用两条 analysis 连接分别接收输入 A/B 和输出 C | 正常与故意错误用例均尚未在 UVM 仿真器中编译或运行 |
| [21_uvm_env.sv](21_uvm_env.sv) | env 创建示例数据源和 scoreboard，并连接两条 analysis 通道 | 正常与故意错误用例均尚未在 UVM 仿真器中编译或运行 |
| [22_uvm_agent.sv](22_uvm_agent.sv) | agent 管理 sequencer、driver、monitor，env 连接采样 scoreboard | 正常与故意错误用例均尚未在 UVM 仿真器中编译或运行 |
| [23_uvm_active_passive.sv](23_uvm_active_passive.sv) | agent 按模式创建组件：主动送数或被动观察 | 主动、被动及两种故意错误组合均未在 UVM 仿真器中编译或运行 |
| [24_uvm_agent_config.sv](24_uvm_agent_config.sv) | 用配置对象集中传递 agent 模式与虚接口 | 主动、被动及两种故意错误组合均未在 UVM 仿真器中编译或运行 |
| [25_uvm_topology.sv](25_uvm_topology.sv) | 在 end_of_elaboration_phase 打印 UVM 组件层级 | 主动、被动及两种故意错误组合均未在 UVM 仿真器中编译或运行 |
| [26_uvm_end_checks.sv](26_uvm_end_checks.sv) | 用 check_phase 检查完整性，report_phase 汇总教学结果 | 主动、被动及两种故意错误组合均未在 UVM 仿真器中编译或运行 |
| [27_uvm_watchdog.sv](27_uvm_watchdog.sv) | 并行 watchdog 为运行等待设置仿真时间上限 | 正常、被动、错值及两种保持复位的超时用例均未在 UVM 仿真器中编译或运行 |
| [28_uvm_functional_coverage.sv](28_uvm_functional_coverage.sv) | 用三个 bin 统计教学输入快照 a0 的符号类别 | 六种用例均未在支持 UVM/covergroup 的仿真器中编译或运行 |
| [29_uvm_directed_coverage.sv](29_uvm_directed_coverage.sv) | 加入定向负数样例，补 a0 符号覆盖缺口 | 六种用例均未在支持 UVM/covergroup 的仿真器中编译或运行 |
| [30_uvm_cross_coverage.sv](30_uvm_cross_coverage.sv) | 对同一快照的 A/B 符号做交叉覆盖 | 六种用例均未在支持 UVM/covergroup 的仿真器中编译或运行 |
| [31_uvm_sign_combinations.sv](31_uvm_sign_combinations.sv) | 用两层 foreach 遍历九种符号代表值组合 | 六种用例均未在支持 UVM/covergroup 的仿真器中编译或运行 |
| [32_uvm_boundary_coverage.sv](32_uvm_boundary_coverage.sv) | 给 A/B 各增加最小值、最大值 bin，并追加两组边界激励 | 六种用例均未在支持 UVM/covergroup 的仿真器中编译或运行 |
| [33_uvm_boundary_random.sv](33_uvm_boundary_random.sv) | 关闭入门范围约束，用内联约束随机生成边界值矩阵 | 尚未在 UVM 仿真器中编译或运行 |
| [34_uvm_weighted_random.sv](34_uvm_weighted_random.sv) | 用 dist 为边界值增加权重，同时允许完整 8 位有符号范围 | 尚未在 UVM 仿真器中编译或运行 |
| [35_uvm_random_seed.sv](35_uvm_random_seed.sv) | 设置并记录每个随机对象的 seed，便于重现输入 | 尚未在 UVM 仿真器中编译或运行 |
| [36_reference_width.sv](36_reference_width.sv) | 用 17 位保存完整参考结果，独立标记是否可由 16 位输出表示 | Icarus 已运行：12 个结果及标志通过；注入 X 时按预期报错 |
| [37_uvm_random_reference.sv](37_uvm_random_reference.sv) | 将带种子的随机 A/B 交给完整位宽参考函数 | 尚未在 UVM 仿真器中编译或运行 |
| [38_uvm_prediction_queue.sv](38_uvm_prediction_queue.sv) | 每组参考结果保存为独立对象，并按生成顺序入队 | 尚未在 UVM 仿真器中编译或运行 |
| [39_uvm_result_matching.sv](39_uvm_result_matching.sv) | 手填输出按顺序匹配队首预测，符号扩展后比较完整结果 | 正常与故意错误用例均尚未在 UVM 仿真器中编译或运行 |
| [40_uvm_full_width_scoreboard.sv](40_uvm_full_width_scoreboard.sv) | 将完整位宽预测、队列和比较封装到 UVM scoreboard | 正常与故意错误用例均尚未在 UVM 仿真器中编译或运行 |
| [41_uvm_scoreboard_ports.sv](41_uvm_scoreboard_ports.sv) | 输入和输出通过两条 analysis 连接分别调用 scoreboard 回调 | 正常与故意错误用例均尚未在 UVM 仿真器中编译或运行 |
| [42_uvm_missing_result.sv](42_uvm_missing_result.sv) | 故意遗漏第二份输出，检查数量与待比较队列能否发现缺失 | 正常、错值、缺输出及组合用例均未在 UVM 仿真器中编译或运行 |
| [43_uvm_matrix_env.sv](43_uvm_matrix_env.sv) | env 创建并连接人工数据源与完整位宽 scoreboard，test 选择场景 | 正常、错值、缺输出及组合用例均未在 UVM 仿真器中编译或运行 |
| [44_uvm_env_config.sv](44_uvm_env_config.sv) | 配置对象通过 config_db 从 test 经 env 传给人工数据源 | 正常、错值、缺输出及组合用例均未在 UVM 仿真器中编译或运行 |
| [45_uvm_test_cases.sv](45_uvm_test_cases.sv) | 从共同 base test 派生四个场景，用 UVM_TESTNAME 选择 | 四个命名测试均未在 UVM 仿真器中编译或运行 |
| [46_parameterized_reference.sv](46_parameterized_reference.sv) | 按 DIN_WIDTH、N、M 参数计算完整结果及输出范围标志 | Icarus 已编译运行：7 组参数、108 个结果及标志通过；注入 X 按预期失败 |
| [47_uvm_parameterized_item.sv](47_uvm_parameterized_item.sv) | 同一个参数化事务类保存不同位宽及尺寸的完整 A/B | 尚未在 UVM 仿真器中编译或运行 |
| [48_uvm_parameterized_reference.sv](48_uvm_parameterized_reference.sv) | 参数化输入对象交给同参数参考函数，返回完整 C 与范围标志 | 尚未在 UVM 仿真器中编译或运行 |
| [49_uvm_parameterized_predictions.sv](49_uvm_parameterized_predictions.sv) | 每组参数化参考结果保存为独立 prediction 对象并进入同类型队列 | 尚未在 UVM 仿真器中编译或运行 |
| [50_uvm_parameterized_matching.sv](50_uvm_parameterized_matching.sv) | 参数化人工输出符号扩展后，与队首完整预测逐元素比较 | 正常与注错用例均未在 UVM 仿真器中编译或运行 |
| [51_uvm_parameterized_scoreboard.sv](51_uvm_parameterized_scoreboard.sv) | 参数化 scoreboard 封装预测、比较与结束检查，两组 typed analysis 连接提交人工样例 | 正常与注错用例均未在 UVM 仿真器中编译或运行 |
| [52_subsystem_input_packing.sv](52_subsystem_input_packing.sv) | 将 A 的一列和 B 的一行按明确的教学位序打包为一个子系统输入字 | Icarus 已运行：3 个输入字、12 个带符号元素通过；翻转一位时按预期失败 |
| [53_fifo_write_acceptance.sv](53_fifo_write_acceptance.sv) | 在深度 1 的教学 FIFO 前等待空位，只在接受写入后前进 | Icarus 已运行：3 次接受、3 次消费、6 个等待采样沿；错误跳过待发送字被检出 |
| [54_input_reconstruction.sv](54_input_reconstruction.sv) | monitor 仅从接受的输入字重组一份完整 A/B | Icarus 已运行：1 帧、12 个带符号元素核对通过；故意交换 A 的两条 lane 被检出 |
| [55_observed_reference.sv](55_observed_reference.sv) | 将 monitor 收齐的 A/B 交给完整位宽参考函数，生成期望 C | Icarus 已运行：12 个输入元素、4 个预测结果及范围标志通过；预测值改错被检出 |
| [56_observed_result_comparison.sv](56_observed_result_comparison.sv) | 将独立手填输出与已接受输入产生的预测逐元素比较 | Icarus 已运行：1 份手填结果、4 个元素匹配；改错一个负数后检出 1 次不匹配 |
| [57_observed_completion.sv](57_observed_completion.sv) | 人工源结束后检查结果数量、待处理预测、元素数量和错值 | Icarus 已运行四种组合：正常通过；错值、缺结果及组合均按预期失败 |
| [58_output_reconstruction.sv](58_output_reconstruction.sv) | 输出 monitor 按教学 FIFO 接受的读事件收集两行 C，再与期望比较 | Icarus 已运行四种组合：正常四项匹配；错值、缺行及组合均按预期失败 |

第 01–06 份使用基础 SystemVerilog，在本机 Icarus 中运行。故意注入错误的运行以非零退出码结束，这是检查器发现错误的预期结果。

第 36、46 份也使用基础 SystemVerilog，在本机 Icarus 中运行，不需要 UVM 库。其结果只验证数学参考计算和范围标志。

第 52 份同样使用普通 SystemVerilog，已在本机 Icarus 中运行，只验证选定教学位序下的数据打包和解包，不涉及 FIFO 传输。

第 53 份使用普通 SystemVerilog 和自建单时钟、深度 1 的教学 FIFO，在本机 Icarus 中检查接受事件及数据顺序。其握手假设尚未由 PDF 确认，不代表真实子系统或跨时钟 FIFO 已验证。

第 54 份继续使用上述普通 SystemVerilog 教学环境，在本机 Icarus 中运行输入重组检查；其中 monitor 是过程块实现的采样逻辑，尚非 UVM 组件。

第 55 份在同一普通 SystemVerilog 教学环境中连接输入重组与数学参考函数，已在 Icarus 中运行；结果仅证明这一组输入的重组和期望计算，没有 DUT 实际输出参与比较。

第 56 份同样使用普通 SystemVerilog，已在 Icarus 中运行输入采集、期望计算与手填结果比较；手填结果不构成真实 DUT 输出。

第 57 份继续使用普通 SystemVerilog，在本机 Icarus 中运行有限人工源的完成检查；它没有规定真实 DUT 的输出期限。

第 58 份使用普通 SystemVerilog 和一次预装的教学输出 FIFO，在本机 Icarus 中运行输出采样、重组和比较；数据源仍是独立常量，没有硬件矩阵运算或真实 DUT。

第 07–10、13–35、37–45、47–51 份需要支持 UVM 的仿真环境。每次单独加载一份文件并开启 UVM 库；第 07 份顶层为 `matrix_item_demo`，第 08 份顶层为 `random_item_demo`，第 09 份顶层为 `item_reference_demo`，第 10 份顶层为 `sequence_demo`，第 13 份顶层为 `config_db_demo`，第 14 份顶层为 `monitor_demo`，第 15 份顶层为 `sample_item_demo`，第 16 份顶层为 `analysis_port_demo`，第 17 份顶层为 `scoreboard_demo`，第 18 份顶层为 `matrix_scoreboard_demo`，第 19 份顶层为 `expected_queue_demo`，第 20 份顶层为 `two_analysis_demo`，第 21 份顶层为 `env_demo`，第 22 份顶层为 `agent_demo`，第 23 份顶层为 `active_passive_demo`，第 24 份顶层为 `agent_config_demo`，第 25 份顶层为 `topology_demo`，第 26 份顶层为 `end_checks_demo`，第 27 份顶层为 `watchdog_demo`，第 28 份顶层为 `functional_coverage_demo`，第 29 份顶层为 `directed_coverage_demo`，第 30 份顶层为 `cross_coverage_demo`，第 31 份顶层为 `sign_combinations_demo`，第 32 份顶层为 `boundary_coverage_demo`，第 33 份顶层为 `boundary_random_demo`，第 34 份顶层为 `weighted_random_demo`，第 35 份顶层为 `random_seed_demo`，第 37 份顶层为 `random_reference_demo`，第 38 份顶层为 `prediction_queue_demo`，第 39 份顶层为 `result_matching_demo`，第 40 份顶层为 `full_width_scoreboard_demo`，第 41 份顶层为 `scoreboard_ports_demo`，第 42 份顶层为 `missing_result_demo`，第 43 份顶层为 `matrix_env_demo`，第 44 份顶层为 `matrix_config_demo`，第 45 份顶层为 `matrix_test_cases_demo`，第 47 份顶层为 `parameterized_item_demo`，第 48 份顶层为 `parameterized_reference_object_demo`，第 49 份顶层为 `parameterized_predictions_demo`，第 50 份顶层为 `parameterized_matching_demo`，第 51 份顶层为 `parameterized_scoreboard_demo`。这些练习尚未在 UVM 仿真器中编译或运行；上次检查时 EDA Playground 页面停留在登录页。可以在登录后选择支持 UVM 的 Riviera Pro；参见 [EDA Playground 官方 FAQ](https://eda-playground.readthedocs.io/en/latest/faq.html)。

第 07–09 份练习创建/随机化 transaction，以及用 transaction 计算期望值。尚未启动 UVM phases，也未把数据驱动到 DUT。随机化成功说明生成的数据满足约束，不代表 DUT 的计算已经通过验证；参考函数产生的 `C_expected` 也不等于 DUT 的实际输出。

第 10 份包含一个最小 UVM test，通过 `run_test()` 启动教学环境。教学用 driver 只接收、打印和确认 item，没有连接 DUT，也不产生矩阵运算结果。`finish_item()` 等待的是 driver 对 item 的确认，不能据此判定 DUT 的输出结果已就绪。这个练习演示事务传递，不验证实际接口的周期时序或连续矩阵运算吞吐率。

第 11 份是可在本机运行的普通 SystemVerilog interface 示例，顶层为 `interface_demo`，不依赖 UVM。示例在时钟负沿修改输入、随后在正沿观察；没有连接 DUT，`c_dout` 和 `out_valid` 未被驱动。示例不是完整的矩阵输入协议，也未加入 virtual interface、clocking block 或 modport。保留了 PDF 中 `c_dout[N-1:0]` 的数组方向，但实际结果的时序顺序仍须按协议单独处理。

第 12 份继续使用普通 SystemVerilog，顶层为 `virtual_interface_demo`。`writer.vif = bus` 把现有 interface 实例交给 class 引用，没有复制信号。当前 Icarus 13.0 无法编译该虚接口字段；隔离检查中，普通 class 与 interface 定义可以编译，将 class 字段换成不带参数的 `virtual probe_if vif` 后出现同样错误。此练习需留待支持虚接口的 SystemVerilog 仿真器验证，不能把它标记为已运行通过。UVM 中通过 `uvm_config_db` 传递虚接口的方式见第 13 份练习。

第 13 份使用 interface 的默认参数 `DIN_WIDTH=8`、`N=2`，`set()` 和 `get()` 使用同一个虚接口类型。顶层在 `run_test()` 前将 `bus` 以键名 `"vif"` 配置给 `uvm_test_top.demo_driver`；driver 在自己的 `build_phase` 中取回句柄。driver 每次只驱动两个演示信号 `a_din[0]`、`b_din[0]` 并确认 item，没有实现完整矩阵加载或计算协议，不能据此判断矩阵运算正确性。

第 14 份增加被动的 `matrix_demo_monitor`，经 `config_db` 获取与 driver 相同的接口实例。复位释放后，每个正沿读取并打印 `a_din[0]`、`b_din[0]`；driver 在负沿更新这两个演示输入。监测包含尚未送数时的初始零值，采样次数不等于 transaction 数量，也不表示有效矩阵数据。test 在 sequence 返回后等待下一个负沿再结束，让最后正沿的观察完成。示例没有 DUT、输出采集、analysis port 或 scoreboard，也没有实现完整输入协议；真实输出采样时机仍需根据协议和 DUT 更新时序设计。

第 15 份让 monitor 在每个采样正沿创建新的 `signal_sample` 对象，把当拍的两个输入值及采样编号存入字段，再显式打印这些字段。字段没有 `rand`，四态有符号类型保留负数及 X/Z。这里复制的是当时的信号值，接口后续变化不会自动改变已经存入对象的值；每拍重新创建对象，避免覆盖旧对象内容。这个例子只封装并打印当前快照，没有保存历史队列，也没有向 scoreboard 发送数据。采样编号不是矩阵编号，快照不表示完整矩阵或计算结果。

第 16 份在 monitor 中创建 `uvm_analysis_port #(signal_sample)`，在 receiver 中创建 `uvm_analysis_imp #(signal_sample, sample_receiver)`，并在 test 的 `connect_phase` 中连接两者。monitor 调用 `ap.write(sample)` 时，会同步调用 receiver 的 `function void write(signal_sample sample)`；不推进仿真时间，也不会自动排队或复制对象。receiver 只读并打印，monitor 每拍创建新对象且发送后不修改。示例含采样次数与接收次数的检查，仅检查本例调用数量匹配，不验证矩阵算法或真实 DUT；本课没有 scoreboard 或历史队列。接口定义参考 [Accellera UVM analysis port 源码](https://github.com/accellera-official/uvm-core/blob/main/src/tlm1/uvm_analysis_port.svh)。

第 17 份将接收端改为 `sample_scoreboard extends uvm_scoreboard`，通过 `analysis_imp` 接收当拍输入快照，并在 `write()` 内使用 `!==` 逐字段比较独立指定的期望值。sequence 本次仅发送一项固定数据，不调用 `randomize()`。按本例时钟安排，20 ns 释放复位，25 ns 采到初始 `0/0`，30 ns 驱动 `3/-2`，35 ns 采第二项，40 ns 结束。这两个期望及采样编号只适用于本例固定安排，不是 PDF 规定的矩阵输入协议；不能靠数值是否为零判断有效性。结束前还会检查接收数量，避免没有收到数据却误报通过。

第 17 份包含可选的仿真参数 `+INJECT_ERROR`：driver 将第二项的 `b_din[0]` 故意改成 `+2`，scoreboard 的期望仍是 `-2`，意图触发 `B_MISMATCH` 并以 `SAMPLE_CHECK_FAILED` 结束。正常路径和此故意错误路径都尚未进行 UVM 编译或仿真；没有运行日志或通过证据。本课验证对象仅为教学信号采集和比较链路，不涉及 `c_dout` 或 DUT 矩阵运算。`uvm_scoreboard` 基类本身不提供矩阵参考模型或自动比较算法，参见 [Accellera UVM scoreboard 定义](https://github.com/accellera-official/uvm-core/blob/main/src/comps/uvm_scoreboard.svh)。

第 18 份单独练习完整矩阵的 scoreboard，不包含 interface、driver 或 monitor。test 通过 analysis port 发送一个 `matrix_check_item`，其中包含已经配对的 A、B 和手工填写的 `C_actual`。采用第 03 份的固定矩阵：A=`[[1,-2],[3,4]]`，B=`[[-1,2],[5,-3]]`，手填 C=`[[-11,8],[17,-6]]`。scoreboard 的 `write()` 调用由第 09 份改写的 `calculate_expected()`，仅从 A/B 计算 `C_expected`，再用 `!==` 检查 C 的四个元素。参考函数先拒绝 A/B 中的 X/Z，并在输出超过 16 位有符号范围时终止；未自行规定溢出截断或饱和策略。

第 18 份的 `+INJECT_ERROR` 将手填 `C_actual[1][0]` 改成 18，意图产生期望 17、实际 18 的错误并终止。本课正常和故意错误路径均未进行 UVM 编译或仿真。`C_actual` 不由参考函数产生，也不是 DUT 实际输出；此例只演示数学参考计算和 UVM 比较链路，不能据此宣称验证了 DUT。后续接入真实 monitor 时，还需把输出矩阵与对应的输入 A/B 正确配对，不能只采集 `c_dout` 就认为这个组合对象已完整。

第 19 份把输入 A/B 与完整输出 C 分成两个对象类型。test 直接调用 scoreboard 的 `add_expected()`，为每组输入创建独立的 `matrix_expected_item`，计算结果后用 `push_back()` 放到队尾；实际结果仍由 test 手工填写，经 analysis port 送入。scoreboard 收到完整输出时，先检查队列非空，再用 `pop_front()` 取出最早尚未匹配的期望，逐元素比较。队列存的是对象句柄，入队后不修改它；局部 `case_id` 只用于日志，不是 DUT 返回的标识。

第 19 份先登记两组输入，再依次送出两份手填结果：第一组沿用第 18 份，第二组 A=`[[-2,1],[0,3]]`、B 为单位矩阵，C 手填为 A。结束时检查总输入/输出数量、未匹配的队列项和比较错误。`+INJECT_ERROR` 仍只改第一份 actual 的一个元素。所有调用在仿真时间 0 同步执行；本课不测延迟、吞吐率、复位或实际接口时序，正常及故意错误路径都未编译仿真。

第 19 份明确假设每个输入先登记期望，完整输出按输入顺序到达。乱序输出需要额外匹配标识；真实并行 monitor 在同一时刻提交输入/输出时，还需处理回调的先后次序。本例输入端暂用直接函数调用，后续再引入输入 analysis 连接。按序比较与暂存数据的思路也可参考 [Accellera UVM in-order comparator](https://github.com/accellera-official/uvm-core/blob/main/src/comps/uvm_in_order_comparator.svh)，该现成组件使用双方 FIFO，本课只手写期望侧队列。

第 20 份把第 19 份的输入登记也接到 analysis port。package 内分别声明一次 `uvm_analysis_imp_decl(_input)`、`uvm_analysis_imp_decl(_output)`，生成带后缀的两个 imp 类型，分别调用 scoreboard 的 `write_input()`、`write_output()`。前者从完整 A/B 计算并入队期望，后者取队首与完整 C 比较。普通 imp 都调用所属组件的 `write()`；这里用不同后缀区分两种数据类型和处理逻辑，并不是 UVM 禁止多个 imp。宏定义可参考 [Accellera UVM TLM 宏源码](https://github.com/accellera-official/uvm-core/blob/main/src/macros/uvm_tlm_defines.svh)。

第 20 份仍由 test 模拟两个数据来源，先用 `input_ap.write()` 发送两组固定输入，再用 `result_ap.write()` 发送两份手填结果。两个入口的连接都在 `connect_phase` 完成；数学参考模型、FIFO 配对假设及结束检查沿用第 19 份。没有真实 monitor 或 DUT，也没有解决并行回调次序、逐拍协议和输出重组。本课正常和 `+INJECT_ERROR` 路径均未编译仿真。

第 21 份将组件的创建和连接集中在 `matrix_env extends uvm_env` 中。env 在 `build_phase` 创建 `source` 和 `scoreboard`，在 `connect_phase` 连接两条 analysis 通道。`matrix_fixture_source` 从前一课的 test 中接过手填样例及发送端口，通过 `send_cases()` 发送；它是示例数据源，不采样硬件信号，也不是 monitor。test 只创建 env、持有 objection、调用 `env.source.send_cases()` 并检查最终数量、队列和错误数，数据源本身不引用 scoreboard。`uvm_env` 是用于组织组件层级和复用环境的基类，参见 [Accellera UVM env 定义](https://github.com/accellera-official/uvm-core/blob/main/src/comps/uvm_env.svh)。

第 21 份沿用两组固定矩阵、独立手填 actual、错误注入及数学参考逻辑。发送操作仍同步发生在时间 0；没有 DUT、接口或时序验证，正常及故意错误路径均未编译仿真。当前层级为 `uvm_test_top.env.source`、`uvm_test_top.env.scoreboard`；本课没有 virtual interface，前面练习中的 config_db 路径不能直接套用到未来的新层级。

第 22 份以第 17 份的接口采样例子为基础，新增 `matrix_agent extends uvm_agent`。agent 创建 sequencer、driver、monitor，并连接 driver 与 sequencer；`matrix_agent_env` 创建 agent 与 `sample_scoreboard`，连接 monitor 的 analysis port 到 scoreboard。test 创建 env，在 `env.agent.sequencer` 上启动 sequence，并检查一个驱动对象和两次输入采样。这是组件层级练习，未把第 21 份的完整矩阵 scoreboard 与真实阵列协议接起来。agent 的常见组成可参考 [Accellera UVM agent 定义](https://github.com/accellera-official/uvm-core/blob/main/src/comps/uvm_agent.svh)。

第 22 份仅实现 active 模式；如果配置为 passive，会明确终止，未实现被动模式。顶层仍在 `run_test()` 前用 config_db 设置接口，两个目标路径更新为 `uvm_test_top.env.agent.demo_driver` 和 `uvm_test_top.env.agent.demo_monitor`。时钟、复位、固定 `0/0` 与 `3/-2` 采样安排及错误注入沿用第 17 份。只访问两个输入元素，没有 DUT 或完整矩阵加载/结果采集；正常和故意错误路径均未编译仿真。

第 23 份让同一个 agent 支持 active/passive。默认主动模式创建 sequencer、driver、monitor；仿真参数 `+PASSIVE` 选择被动模式，仅创建 monitor。agent 的 `build_phase` 调用父类后根据 `get_is_active()` 创建组件，`connect_phase` 仅在主动模式连接 driver/sequencer。env 到 monitor 的 analysis 连接以及输入采样 scoreboard 在两种模式下均保留。顶层在 `run_test()` 前通过 `uvm_config_db#(uvm_bitstream_t)` 设置 `is_active`，这是 `uvm_config_int` 别名对应的类型，参见 [Accellera config_db 定义](https://github.com/accellera-official/uvm-core/blob/main/src/base/uvm_config_db.svh)。

第 23 份中，被动模式的 `3/-2` 由顶层演示进程在 30 ns 驱动，不是被动 agent 送数，也不是 DUT 计算结果；主动模式不执行这次顶层更新，改由 driver 送入。test 使用自己的 virtual interface 等待采样完成，避免被动模式访问不存在的 driver，并检查模式选择、组件存在性、两次采样和比较结果。沿用固定复位与采样时序，两种模式均在 40 ns 检查。`+INJECT_ERROR` 可与默认主动模式或 `+PASSIVE` 组合，意图令实际 b 从 -2 变为 +2、触发失败。四种组合均未编译或仿真，不能视为已经验证的运行结果；本课仍无 DUT 或完整矩阵协议。

第 24 份新增 `matrix_agent_config extends uvm_object`，集中保存 `is_active` 与 `virtual systolic_array_if vif`，它是环境配置，不包含 A/B 激励数据。顶层先创建对象、填好模式和接口，通过 `uvm_config_db#(matrix_agent_config)` 以键名 `"cfg"` 传给 test；test 在 `build_phase` 取回并检查非空，再向相对路径 `"env.agent"` 转发同一个句柄。agent 取得配置后设置继承的 `is_active`，再为 monitor 和主动模式下的 driver 配置接口。driver/monitor 保留原来的 `get("vif")` 方式；顶层只需知道 test 路径，test 只需知道 agent 路径，内部子组件的路径由 agent 管理。配置作用域可参考 [Accellera config_db 定义](https://github.com/accellera-official/uvm-core/blob/main/src/base/uvm_config_db.svh)。

第 24 份以 cfg 作为模式的唯一来源，不再单独设置 `is_active` 的 config_db 项。agent 在 `super.build_phase()` 后执行 `this.is_active = cfg.is_active`，使 `get_is_active()` 与组件创建模式保持一致。config_db 传递对象句柄，不自动深拷贝；本例要求构建前填写配置，后续只读，不支持运行时修改模式来重建组件。配置中的 `vif` 使用固定的默认接口类型（DIN_WIDTH=8、N=2），没有增加运行时修改硬件参数的能力。主动、被动两种源仍由 `+PASSIVE` 互斥选择，`MODE_CONFIG` 检查保留，采样时序和 `+INJECT_ERROR` 行为沿用第 23 份。四种组合均未编译或仿真，本课仍只检查两个教学输入快照，没有 DUT 或完整矩阵协议。

第 25 份在 test 的 `end_of_elaboration_phase()` 中调用父类方法，然后执行一次 `uvm_top.print_topology()`。此时 build 和 connect 阶段已经完成，尚未进入 run 阶段；适合查看实际创建的 UVM 组件及实例名。`uvm_top` 是 UVM 根对象的句柄，test 的实例名是 `uvm_test_top`，与其类名 `matrix_topology_test` 不同。以下仅为按代码推导的主动模式结构简图，省略内部节点，不是仿真日志：

```text
uvm_test_top
└── env
    ├── agent
    │   ├── demo_driver
    │   ├── demo_monitor
    │   └── sequencer
    └── scoreboard
```

使用 `+PASSIVE` 时，agent 内只保留 `demo_monitor`。cfg、sequence 和 item 都不是组件子节点；HDL 顶层 module 和 interface 也不属于这棵 UVM 组件树。实际打印可能包含端口及 sequencer 内部节点，格式取决于 UVM 版本和 printer。此功能有助于核对组件创建结果及 config_db 的目标路径，不验证数据或连接的实际功能。接口配置、固定两次输入采样、主动/被动送数和故意错误路径均沿用第 24 份，四种组合都未编译仿真。定义参见 [Accellera UVM root](https://github.com/accellera-official/uvm-core/blob/main/src/base/uvm_root.svh) 与 [UVM common phases](https://github.com/accellera-official/uvm-core/blob/main/src/base/uvm_common_phases.svh)。

第 26 份保持 scoreboard 的 `write()` 即时比较，将原 test 的结束检查移到 `check_phase()`，包括一个主动驱动对象、被动模式不创建 driver/sequencer、monitor 与 scoreboard 各收到两个样本，以及 mismatch 计数为零。这里的两个样本仍是 `0/0` 与 `3/-2`，不是两个矩阵结果。`run_phase()` 在 40 ns 等待固定样例的最后观察完成后再 drop objection；check 阶段只检查已有状态，不负责继续等待数据。UVM 会在 run/extract 后调用 check，再调用 report；check/report 都是 function，不能使用延时或时钟等待。阶段定义参见 [Accellera UVM common phases](https://github.com/accellera-official/uvm-core/blob/main/src/base/uvm_common_phases.svh)。

第 26 份把可恢复的结束检查改为 `uvm_error`，便于继续收集错误并进入 `report_phase()`。report 读取 `uvm_report_server` 累计的 `UVM_ERROR`/`UVM_FATAL` 数量，用 info 消息输出 `LESSON_PASS` 或 `LESSON_FAIL`；不会清除已有错误，也不会在汇总时再增加 error。逐项错误和结束汇总可能分别产生 error，因此 UVM 错误消息数不等于错值数量。接口缺失、配置错误等 fatal 仍会提前终止，不能保证所有失败都进入 report。在默认 UVM 报告设置下，`+INJECT_ERROR` 意图产生 mismatch、结束检查错误和 `LESSON_FAIL`，须按 UVM 日志和 error summary 判断失败，不保证操作系统退出码非零。此处的 PASS 只指本课输入采集与检查链路，不是 DUT 运算通过；四种组合仍未编译仿真。报告计数接口参见 [Accellera UVM report server](https://github.com/accellera-official/uvm-core/blob/main/src/base/uvm_report_server.svh)。

第 27 份将原来的有限发送和观察过程提取为 `run_fixture()`。test 的 `run_phase()` 先 raise objection，再用 `fork...join_any` 并行启动该过程和一个 `#100ns` 的 watchdog。正常过程按原时序在 40 ns 完成，`join_any` 返回后通过 `disable fork` 取消剩余的计时线程，再 drop objection，进入后续 check/report。watchdog 到期时报告 `RUN_TIMEOUT` fatal。100 ns 是从该 watchdog 启动起计算的仿真时间，本例启动于 0 ns；它是教学设置，不是实际墙钟等待时间或 PDF 对 DUT 的延迟要求。fork/join_any 与 watchdog 用法可参考 [DVCon：Synchronicity](https://dvcon-proceedings.org/wp-content/uploads/synchronicity-bringing-order-to-systemveriloguvm-synchronizing-chaos.pdf)。

`disable fork` 会终止当前进程的活动子孙进程，不只针对代码中最近的 fork。本例 run_phase 只启动上述两条分支，因此正常结束时仅需取消计时分支；driver/monitor 的 run 线程由 UVM 独立启动，随后在 UVM run 阶段结束时被终止。未来若增加其他后台子线程，必须重新检查取消作用域。正常完成的 40 ns 与截止的 100 ns 分开，避免同一仿真时刻完成和超时的竞争。时间型 watchdog 需要仿真时间能前进，不能解决不让时间前进的零延时死循环。

第 27 份新增 `+HOLD_RESET`，让顶层始终保持 `rst_n=0`。主动模式中 sequence 等待 driver 继续，被动模式中 test 等待复位；monitor 与顶层被动演示源也都等待复位，不采集样本。按代码设计，两种模式都会在 100 ns 触发 `RUN_TIMEOUT`。默认 fatal 报告行为会直接结束，不保证执行后面的 drop/check/report，不能要求超时路径也打印 `LESSON_FAIL`；应检查 fatal 标识及日志。默认主动、`+PASSIVE`、`+INJECT_ERROR`、`+PASSIVE +INJECT_ERROR`、`+HOLD_RESET`、`+PASSIVE +HOLD_RESET` 六种用例均未编译或仿真。正常值/错值的采样与结束检查沿用第 26 份，仍无 DUT 或完整矩阵协议。

第 28 份新增 `input_coverage extends uvm_component`，通过熟悉的 `analysis_imp` 接收 `signal_sample`。env 将同一个 monitor 的 analysis port 分别连接到 scoreboard 和 coverage，两者只读共享的观察对象。coverage 在构造器中创建内嵌 covergroup；`write()` 先排除空句柄，对 a0 中的 X/Z 记录跳过数量，其余样本复制到本地四态有符号 `sampled_a0` 后调用 `a_sign_cg.sample()`。固定 8 位范围按三个单独 bin 分类：negative=`[-128:-1]`、zero=`0`、positive=`[1:127]`。这里未使用 bin 数组；出现一个负数即可命中整个 negative 类，不表示 128 个负值都已经尝试。covergroup、bins 和采样 API 的说明可参考 [Verilab：Functional Coverage in SystemVerilog](https://assets-global.website-files.com/63f4bb21bd5303fe472ad00e/64958ef9bf647fbf4f5e52b9_svug_2007_fall_func_cov_in_sv.pdf)。

按固定样例推导，a0 的两个快照为 0 和 3，应命中 zero、positive，negative 尚未命中，三类的预期覆盖率约为 66.67%。这不是实测结果。0 来自初始化后的空闲快照，因此本课只能说明快照分类，不能把它算成“零元素矩阵运算已覆盖”；实际项目应对按接口协议确认有效的矩阵事务采样，不能仅凭每拍值或数值是否为零判断有效性。本课也不统计 B、C、矩阵形状、完整数值范围或协议场景，不代表整个项目的覆盖率。

coverage 在 `report_phase()` 中报告成功采样数、跳过的未知值数量和当前实例的符号覆盖百分比；本课不设置覆盖率通过阈值。scoreboard 的正确性判断保持独立：`+INJECT_ERROR` 只修改 B，A 的符号覆盖应保持不变，但数据检查应失败。`+HOLD_RESET` 的 fatal 超时不保证进入覆盖率报告阶段。沿用第 27 份六种用例，全部未编译或仿真；执行时需要支持 covergroup 的 UVM 仿真器，并根据该仿真器的设置启用功能覆盖率收集。

第 29 份根据第 28 份的负数覆盖缺口补充定向激励。sequence 每次新建并完整初始化一个 item，先令 `A[0][0]=3`，再令 `A[0][0]=-3`，两项均令 `B[0][0]=-2`，其余 A/B 元素为零；本课不调用 randomize。现有 driver 循环依次处理两项，仍只驱动 a0/b0 两个示例输入。被动模式的顶层演示源送相同的两项数据。scoreboard 独立列出三组快照期望 `(0,0)`、`(3,-2)`、`(-3,-2)`，结束检查更新为主动 driver 收到两项、monitor/scoreboard 收到三个样本。

按代码推导的正常时序为：20 ns 释放复位，25 ns 采初始化零值，30 ns 驱动正数，35 ns 采正数，40 ns 驱动负数，45 ns 采负数，50 ns 结束。被动模式等待三次正沿，主动模式等待两项 sequence 完成，两者都在最后一次采样后的负沿结束，并取消 100 ns watchdog。三个符号 bin 应全部命中，预期该小模型覆盖率为 100%，但这不是实际仿真结果，也不是整个项目覆盖率。零值依然来自空闲快照，完整矩阵事务覆盖仍待实现；三个分类命中也不表示所有8位取值或运算场景已验证。

第 29 份的 `+INJECT_ERROR` 会把两项实际 B 都改为 +2，预期产生两处 B mismatch；A 的三类覆盖仍应全部命中，因此 coverage 百分比不能代替 scoreboard 的正确性检查。本课没有增加覆盖率通过阈值。`+HOLD_RESET` 仍应在 100 ns 触发 fatal。沿用前课默认主动、被动、两种错值及两种保持复位组合，六种用例全部未编译或仿真，无 DUT 或完整矩阵输入输出协议。

第 30 份把 A 的单点符号覆盖扩展为 A/B 符号交叉覆盖。`sign_pair_cg` 中 `cp_a_sign` 与 `cp_b_sign` 各有 negative、zero、positive 三个 bin，`a_b_sign: cross cp_a_sign, cp_b_sign;` 自动形成九种组合。coverage 的 `write()` 同时从一个 `signal_sample` 复制 a0/b0，再调用一次 sample，避免把不同观察时刻的值拼成一对。若任一值包含 X/Z，跳过整个 pair 并计数；因此两个单点及交叉覆盖使用相同的“双方都已知”采样条件。相关基础定义参见 [Verilab：Functional Coverage in SystemVerilog](https://assets-global.website-files.com/63f4bb21bd5303fe472ad00e/64958ef9bf647fbf4f5e52b9_svug_2007_fall_func_cov_in_sv.pdf)。

按当前三个固定快照 `(0,0)`、`(3,-2)`、`(-3,-2)` 推导，A 单点应命中3/3、B 单点2/3，cross应命中 `(zero,zero)`、`(positive,negative)`、`(negative,negative)` 共3/9，交叉覆盖预期约为33.33%。这些是静态预期，不是实际仿真数据。report 分别调用两个 coverpoint 和 cross 的 get_inst_coverage，不把整个 covergroup 的综合百分比误标成交叉覆盖。初始 `(0,0)` 仍是空闲快照；模型只演示观察值的符号组合，不能充当完整矩阵事务、运算或协议覆盖。

第 30 份不改变激励、scoreboard、50 ns 正常结束或100 ns watchdog。`+INJECT_ERROR` 后快照应为 `(0,0)`、`(3,2)`、`(-3,2)`，cross仍命中3/9，但命中的组合换成 `(zero,zero)`、`(positive,positive)`、`(negative,positive)`，同时scoreboard应报错；相同百分比不保证测过相同场景，也不保证结果正确。无覆盖率通过阈值。沿用前课六种用例，全部未编译或仿真；超时 fatal 不保证进入覆盖报告阶段。

第 31 份用两个显式 signed `[0:2]` 数组列出代表值：A为 `[-3,0,3]`，B为 `[-2,0,2]`。sequence 外层 foreach 遍历 A，内层遍历 B，每次创建新的 matrix_item、清零完整 A/B 数组，再设置 A[0][0]、B[0][0] 并交给 driver。九项按 `(-3,-2),(-3,0),(-3,2),(0,-2),(0,0),(0,2),(3,-2),(3,0),(3,2)` 的顺序送入。被动模式的顶层示例源采用同样次序，scoreboard 则独立显式列出初始化及九项激励的期望常量，没有从激励数组读取答案。

九项激励按代码应在30～110 ns的连续负沿送出；monitor在25～115 ns共采十次，包含最初的空闲 `(0,0)`。因此主动 driver 数量检查为9，monitor/scoreboard数量检查为10；被动test等待十个正沿，两种模式都在120 ns结束。原来的100 ns期限已不足以完成这一组测试，watchdog调整为200 ns。初始零值与第五项 `(0,0)` 命中同一组合，所以十个快照对应九个不同cross bin；按静态推导A、B单点和交叉覆盖均应100%。这只表示符号组合模型的九类，应由支持coverage的仿真验证，不能当成所有8位数值或完整矩阵功能的覆盖。

第 31 份对每项数据应用 `+INJECT_ERROR` 时，实际B都被置为+2，其中期望B为-2或0的六项应发生mismatch，UVM错误消息总数还包括结束汇总。此时cross预期命中三种 `(A类别,positive)` 及最初的 `(zero,zero)`，共4/9；scoreboard应判失败。`+HOLD_RESET` 两种模式均应在200 ns超时。默认主动、被动、两种错值、两种保持复位用例均未编译或仿真；所有时间和覆盖百分比均为代码推导，无DUT或完整矩阵协议。

第 08–10、13–16 份的 `[-4:4]` 是入门练习的激励范围，不是 PDF 对输入值的限制。完整验证后续还需覆盖全部合法数据范围、参数组合、时序、连续运算及子系统协议。

第 32 份保留九种符号组合，追加 `(-128,127)`、`(127,-128)` 两组输入。8 位有符号最小值用 `8'sh80` 表示，最大值用 `8'sd127`；每项仍创建新的 item 并清零其余矩阵元素。sequence 直接赋值，不调用 `randomize()`，因此 item 中保留的 `small_values` 约束不会限制本课赋值。若后续恢复随机化，需要重新设计约束以允许目标边界值。被动源同步增加两项，scoreboard 用独立常量增加第 11/12 个快照的期望。

覆盖模型新增 `cp_a_boundary`、`cp_b_boundary`，每个只定义 `min_value={-128}` 与 `max_value={127}` 两个 bin。其余已知数值不会命中这两个 bin，也不会因此成为非法数据；bins 用于记录覆盖目标，不是激励约束。两个 coverpoint 各自调用 `get_inst_coverage()` 报告百分比。按正常激励推导，两者都应命中 2/2；原符号 cross 仍为 9/9。这个 100% 只表示各输入都出现过两个端点，没有统计边界值之间的所有配对，也未验证矩阵运算。显式 bin 定义可参考前述 [Verilab 功能覆盖介绍](https://assets-global.website-files.com/63f4bb21bd5303fe472ad00e/64958ef9bf647fbf4f5e52b9_svug_2007_fall_func_cov_in_sv.pdf)。

第 32 份预期共驱动 11 项，monitor/scoreboard 收到包含初始零值的 12 个快照。新增两项在 120/130 ns 驱动、125/135 ns 采样，两种模式均在 140 ns 结束，watchdog 保持 200 ns。`+INJECT_ERROR` 仍把每项实际 B 改为 +2，预期共 8 处 B mismatch，A 边界覆盖 2/2、B 边界覆盖 0/2；scoreboard 应判失败。六种用例均未编译或仿真，所有计数、时序和百分比只是静态推导。本课仍只观察 a0/b0 教学输入，没有 DUT 或完整矩阵协议。单独编译时顶层为 `boundary_coverage_demo`。

第 33 份回到第 08 份的短小对象练习，单独说明随机边界场景的约束配置，没有改动第 32 份的定时环境或固定期望 scoreboard。每轮新建一个 matrix_item，调用 `item.small_values.constraint_mode(0)` 关闭该对象的非 static 入门范围约束，然后用 `randomize() with` 要求 A/B 每个元素属于 `{-128,127}`。内联约束与其他启用的约束共同求解，并不会覆盖原约束；如果仍保留 `[-4:4]`，两种要求没有交集，随机化将失败。代码检查返回值，仅在成功后打印矩阵。基础语义参见 [Accellera SystemVerilog 3.1a LRM 第 12.6、12.8 节](https://ece.uah.edu/~gaede/cpe526/SystemVerilog_3.1a.pdf)。

`constraint_mode(0)` 改变约束是否参与求解，A/B 的 rand 状态保持启用；不要与关闭变量随机化的 `rand_mode(0)` 混淆。small_values 在当前对象上保持关闭，randomize 返回不会自动恢复。若复用同一对象生成小数值，需要显式调用 `item.small_values.constraint_mode(1)` 再进行下一次随机化；重新启用约束本身不会修改已存入的数值。本例每轮都创建新对象，其非 static 约束默认启用，然后只为这一轮关闭。

第 33 份生成四组边界矩阵，结果允许重复，不能保证每个位置出现过两个端点或覆盖了全部端点组合。本例只生成对象，不启动 UVM phases，没有 driver、monitor、covergroup 或 DUT，不计算 C，也没有采用任何累加溢出策略。未编译、未仿真；顶层为 `boundary_random_demo`，需要支持 SystemVerilog 约束随机和 UVM 的仿真器。

第 34 份把内联端点集合改为 `dist { -128 := 25, [-127:126] :/ 50, 127 := 25 }`，分别应用于 A/B 的每个元素。两端和中间范围互不重叠，合起来允许全部 256 个 signed 8 位数值。`:=` 给单个值分配权重；若用于范围，则给范围内每个值分配该权重。`:/` 给整个范围分配总权重，范围内的值均分。这里没有其他 A/B 限制时，三个类别的理论概率为 25%、50%、25%；这些数字是相对权重，换成 1、2、1 也表达相同比例。语义参见 [Accellera SystemVerilog 3.1a LRM 第 12.4.4 节](https://ece.uah.edu/~gaede/cpe526/SystemVerilog_3.1a.pdf)。

第 34 份仍先关闭当前对象的 small_values。若保留该约束，本例两种约束在 `[-4:4]` 上仍有交集，随机化可以成功，但端点和其他范围外的值会被排除；不能照搬第 33 份的“必然无解”。dist 只在本次 randomize 调用中生效，其他启用约束仍共同参与求解。四组新对象仅演示生成方式，不按精确次数检查概率，不保证任意类别或组合必然出现，也不统计 coverage。默认全范围均匀选择时，单个端点概率为 1/256；本课用较高权重增加端点出现的机会，具体随机序列须由实际仿真观察。

本课未连接第 32 份的定时采样环境，也未计算 C 或选择溢出策略。只在成功随机化后打印 A/B；未编译、未仿真，顶层为 `weighted_random_demo`。

第 35 份保留第 34 份的 dist 规则，增加对象 seed。默认 base_seed 为 2026，可通过仿真运行参数 `+ITEM_SEED=1234` 改为 1234。四轮仍各自创建新 item，第 trial 轮使用 `base_seed + trial`；默认对应 trial 0～3 的 seed 为 2026、2027、2028、2029。seed 用 32 位无符号数保存，相加超出范围时按 32 位回绕。每项在工厂创建完成后、randomize 前调用 `item.srandom(trial_seed)`，设置该对象的随机数生成器；此参数是本例自定义的对象种子参数，不是仿真器的全局 seed 选项。基础语义参见 [Accellera SystemVerilog 3.1a LRM 第 12.12.3、12.13、12.14 节](https://ece.uah.edu/~gaede/cpe526/SystemVerilog_3.1a.pdf)。

代码先打印 base_seed，并在每次随机化前打印 trial 和实际 item seed，随机化失败的 fatal 也包含 seed。复现本例的整批输入，应使用相同的 base_seed，并保持仿真器及版本、代码、约束、相关状态和随机调用顺序一致；seed 不是保存完整输入的文件，也不能单独保证重现真实 DUT 的时序或并发问题。不能要求不同仿真器或版本产生相同矩阵；不同 seed 也不保证矩阵不同。这里每轮新建对象并分别设种子；若对同一对象每次随机化前都重复设置相同种子，会重新开始它的随机序列。

本课只演示设置和记录种子，没有实际运行重放比较；未编译、未仿真，没有覆盖率或 DUT 通过结论。单独编译的顶层为 `random_seed_demo`。

第 36 份为后续完整范围随机激励的参考计算补充位宽处理，先用三个确定的例子单独验证。固定 DIN_WIDTH=8、N=M=2，每个乘积用 signed 16 位保存，显式扩展符号到 signed 17 位后累加；每个 C 元素开始计算时清零 sum。完整结果保存在 17 位 C_full 中，fits_output 单独标记该元素是否在 signed 16 位范围 −32768～32767 内。这里不先缩窄结果，也不把超范围自动视为 DUT 错误；PDF 未定义截断、饱和等溢出行为，最终与 DUT 输出比较前仍需明确该约定。17 位选择仅针对本课固定的 M=2。

三个独立手算例子为：原来的混合正负矩阵得到 `[[-11,8],[17,-6]]`；稀疏边界矩阵仅 C[0][0] 得到 32768、其余为零，因此只有该元素的 fits_output=0；A 全为 −128、B 全为 127 时，四个结果均为 −32512 且可由 16 位表示。正常运行的 12 个完整结果及对应范围标志均通过独立答案检查，退出码为 0。加上 `+INJECT_UNKNOWN` 时，将首个 A 元素设为 X，运行按预期在计算前报 UNKNOWN_INPUT，退出码为 1。日志见 [正常算例](logs/36_reference_width.log) 和 [未知值注入](logs/36_reference_width_unknown.log)，均为真实本机运行结果，不是 UVM 或 DUT 验证结果。

本机 Icarus 对直接传给 `$isunknown()` 的动态索引 unpacked-array 元素出现误报；小型隔离例子显示已知值直接检查可能为 1，而复制到标量后检查为 0，实际 X 则两者均为 1。本课因此先把元素复制到同宽的四态标量，再调用 `$isunknown()`。此处理保留未知值检查；修正后已重新编译并运行正常和注错路径。

在项目目录中可单独运行：

```sh
mkdir -p build/lessons
iverilog -g2012 -Wall -s reference_width_demo -o build/lessons/36_reference_width.vvp lessons/36_reference_width.sv
vvp build/lessons/36_reference_width.vvp
vvp build/lessons/36_reference_width.vvp +INJECT_UNKNOWN
```

最后一条命令预期报告 fatal 并以非零退出码结束。这个例子没有 DUT、随机生成、UVM 或时钟，不能据此宣称阵列模块或子系统验证通过。

第 37 份把第 35 份的带种子、带权重随机输入与第 36 份的完整位宽计算接起来。package 在 matrix_item 定义后提供 `calculate_reference(item, C_full, fits_output)`，输入为对象句柄，输出为 17 位完整结果矩阵和逐元素 16 位可表示标志。函数只读 item.A/B，先拒绝空句柄和 X/Z，再按 i、j、k 循环计算；保留 signed 16 位乘积、signed 17 位符号扩展及累加。本课仍固定 DIN_WIDTH=8、N=M=2，没有把位宽规则推广到任意 M。

顶层每轮先创建新 item、设置种子并检查随机化成功，打印 A/B 后把同一个 item 交给参考函数，再打印四个 C_full 及 fits_output；期间不再随机化或修改输入。顶层结果数组在下一轮计算时会被覆盖，本例每次立即打印，没有保存历史预测队列。种子、权重和约束开关沿用第 35 份，默认四个 seed 为 2026～2029，可用 `+ITEM_SEED` 设置起始值。

所有输出标为 REFERENCE_ONLY，没有实际 C 或比较器，也没有结果通过标志。fits_output=0 表示该数学结果不能用 16 位精确表示，仍需明确 DUT 溢出规则才能比较。第 36 份的确定性算术检查已在 Icarus 运行；第 37 份加入 UVM 对象、随机求解和函数参数后的组合尚未编译、未仿真，不能沿用前课的运行结论。顶层为 `random_reference_demo`；本课也未连接第 32 份的定时采样环境或真实 DUT。

第 38 份新增 `matrix_prediction extends uvm_object`，保存 trial_id、item_seed、17 位完整结果 C_full 和逐元素 fits_output。字段没有 rand，元数据由调用者填写，结果由参考函数计算。顶层不再反复覆盖一组共享结果数组，而是每轮创建新的 prediction 对象，调用 `calculate_reference(item, prediction.C_full, prediction.fits_output)`，计算完成后用 `predictions.push_back(prediction)` 保存到对象队列。超出 16 位范围的结果同样保留，没有选择 DUT 溢出规则。

队列声明为 `matrix_prediction predictions[$]`。push_back 保存对象句柄，不自动深拷贝；如果复用同一个 prediction 并不断改字段，多个队列项就可能指向同一份最终内容。因此本例每轮创建新对象，入队后只读。下一轮把局部 prediction 变量改为新对象的句柄，不影响队列仍然引用的旧对象。记录中没有保存 A/B 副本或输入 item 句柄，seed 和 trial_id 只是本地定位信息，不是 DUT 返回的配对标识。

四组输入全部生成后，顶层按索引读取队列并打印每条记录的元数据、四个完整结果及范围标志；读取索引不移除条目，本例也不调用 pop_front。这里仅展示预测保存，没有真实输出、匹配或完成检查，不能要求它像完整 scoreboard 一样清空待比较队列。队列顺序只是本例生成顺序，未来实际输出如何配对仍取决于 DUT 协议。固定尺寸、随机权重、种子和数学计算沿用第 37 份；未编译、未仿真，顶层为 `prediction_queue_demo`。

第 39 份将保存的预测与两组独立手填结果比较。本课采用第 19 份的两组确定性输入：第一组 C 为 `[[-11,8],[17,-6]]`；第二组 B 为单位矩阵，A/C 为 `[[-2,1],[0,3]]`。只使用直接赋值，没有随机化或 seed 参数；输入对象的入门约束不会作用于直接赋值。新增 matrix_result 保存完整 signed 16 位 C，预测仍保存 signed 17 位 C_full 和 fits_output。actual 由固定常量独立填写，没有从参考结果复制。

顶层的 enqueue_prediction 每次创建独立预测对象、计算后入队。compare_result 先检查输出对象、队列以及队首对象非空，再确认队首全部 fits_output 都严格为 1；任一元素不满足时，以 REFERENCE_NOT_COMPARABLE 停止教学流程，保留队列，不选择溢出策略，也不给出 DUT 正误结论。全部满足后才 pop_front，取出并移除最早的预测。每个实际 16 位元素先符号扩展到 signed 17 位，再以 `!==` 比较，既保留负数，也能发现实际值中的 X/Z。

两组预测先全部入队，再按输入顺序提交两份手填输出；case_id 只用于本地日志，不是 DUT 返回标识。这个演示要求按序配对，不支持乱序，也没有建立实际阵列的返回顺序协议。调用同步发生在时间 0，没有 DUT、monitor、接口或 UVM phases。结束时分别检查两份结果、八个比较元素、无剩余预测及无 mismatch；TEACHING_CHECK_PASS 仅指这两组人工数据的比较链路。

`+INJECT_ERROR` 将第一份手填 C[1][0] 从 17 改为 18，按静态推导应产生一次 RESULT_MISMATCH，随后 TEACHING_CHECK_FAILED fatal。正常和注错路径均未编译、未仿真；其它保护路径也未运行验证。第 36 份基础数学模型的通过不能代替本课的 UVM 对象/队列集成验证。顶层为 `result_matching_demo`。

第 40 份将预测队列、计数和逐元素比较移入 `matrix_scoreboard extends uvm_scoreboard`。输入暂由 test 调用 `scoreboard.add_input(item)` 登记；scoreboard 创建独立预测对象、调用数学参考函数并入队。输出端使用 `uvm_analysis_imp #(matrix_result, matrix_scoreboard) output_in`，test 的 result_ap 在 connect_phase 连接到它。`result_ap.write(result)` 同步调用 scoreboard.write(result)，没有自动复制对象或推进时间；双方均只读提交后的结果对象。

write 仍先检查空对象、队列和全部 fits_output，再出队，把实际元素符号扩展到 signed 17 位后比较。scoreboard 的 check_phase 检查通用完整性：至少有输入、登记与比较数量一致、无待匹配预测、比较元素数量完整以及无 mismatch。test 的 check_phase 单独要求本例恰好两组输入、两份输出、八个比较元素。test 在 run_phase 持有 objection，完成所有同步提交后释放；report_phase 根据整个 UVM 报告服务的 ERROR/FATAL 计数打印教学通过或失败。

两组确定性输入及独立手填结果沿用第 39 份。`+INJECT_ERROR` 的单次 mismatch 会即时产生 uvm_error，结束时还会产生比较错误汇总；mismatch 数不等于错误消息数。默认 UVM 报告行为下，该路径会到达 TEACHING_CHECK_FAIL，不保证操作系统退出码非零。scoreboard 的 fatal 保护会提前终止；沿用的数学参考函数对无效输入仍使用 `$fatal`，它不会增加 UVM_FATAL 计数，且默认直接结束，不进入正常 report_phase 汇总。

所有提交仍发生在仿真时间 0，输入由 helper 登记、输出由 test 手填并经 analysis port 提交，没有真实 monitor 或 DUT。按序返回是教学样例约定，溢出策略未确定，接口时序和子系统验证尚未接入。正常与注错用例均未编译、未仿真；单独编译时顶层为 `full_width_scoreboard_demo`。

第 41 份把输入登记也移到 analysis 连接。package 内声明一次 `uvm_analysis_imp_decl(_input)` 和 `uvm_analysis_imp_decl(_output)`，分别生成带后缀的 imp 类型。scoreboard 的 input_in 使用 matrix_item 类型并转发到 write_input，output_in 使用 matrix_result 类型并转发到 write_output。原 add_input 的计算入队逻辑和原 write 的出队比较逻辑保留，只改变入口名称和连接方式。后缀用于区分回调，不是因为 UVM 禁止存在多个普通 imp；宏定义可参考 [Accellera UVM TLM 宏源码](https://github.com/accellera-official/uvm-core/blob/main/src/macros/uvm_tlm_defines.svh)。

test 在构造器中创建 input_ap 和 result_ap，在 connect_phase 分别连接 scoreboard.input_in 和 scoreboard.output_in。run_phase 改为 input_ap.write(input0/input1)，不再直接调用输入 helper；完整结果仍从 result_ap.write 提交。两条 analysis 调用都同步执行、不推进时间、不自动复制对象，提交后 test 不再修改这些对象。本例先完成两次输入回调再提交输出，未处理未来独立 monitor 同时到达时的回调先后次序。

两组确定性输入、独立手填 actual、完整位宽参考计算、范围保护、队列配对、结束检查和 +INJECT_ERROR 均沿用第 40 份。端口连接不代表已实现真实输入采样、输出矩阵重组或 DUT 协议。正常与注错用例均未编译、未仿真，顶层为 `scoreboard_ports_demo`。

第 42 份新增运行参数 `+DROP_LAST_RESULT`，保留两组输入及第一份手填输出，只跳过第二次 result_ap.write。第二份预测继续留在队列中，没有为了结束测试而清空它。有限的教学源完成提交后释放 objection，UVM 随后调用 check_phase；这里不是在时间 0 判定真实 DUT 超时，也未增加 DUT 延迟或 watchdog 规则。

单独使用 `+DROP_LAST_RESULT` 时，按代码应得到 enqueued_count=2、received_count=1、compared_elements=4、待比较队列大小=1、mismatch_count=0。已收到的第一份数据全部正确，所以没有元素 mismatch；但 scoreboard 的 MATRIX_COUNT 和 PENDING_RESULTS，以及 test 的 FIXTURE_COUNT 都应报错，最终 TEACHING_CHECK_FAIL。通用 ELEMENT_COUNT 检查不应报错，因为已收到的一份矩阵确实比较了全部四个元素；它不能替代预期矩阵数量检查。

默认、仅 `+INJECT_ERROR`、仅 `+DROP_LAST_RESULT`、两者同时启用，共四种用例。组合用例仍提交被改成 18 的第一份 C[1][0]，因此应同时发现一次元素 mismatch 和缺失第二份输出。所有结果均为静态推导，四种组合全部未编译、未仿真；真实 DUT 验证尚未接入。顶层为 `missing_result_demo`，原来的数学计算、端口连接和结束检查保持不变。

第 43 份将第 42 份的完整位宽检查链路组织进 `matrix_env extends uvm_env`。env 在 build_phase 创建 matrix_fixture_source 和 matrix_scoreboard，在 connect_phase 连接 source.input_ap → scoreboard.input_in、source.result_ap → scoreboard.output_in。test 的 build_phase 只创建 env；组件层级为 uvm_test_top.env.source 和 uvm_test_top.env.scoreboard。env 负责创建与连接，数学预测、队列和比较仍由 scoreboard 负责。

原先 test 中直接赋值并发送的人工样例移入 source。send_inputs() 每次创建两份新的 A/B 对象，完成赋值后同步发布；send_results(inject_error, drop_last_result) 独立创建两份手填 C，并按参数改错或遗漏第二份。source 没有 run_phase，不会自动送数；test 在持有 objection 时依次调用这两个无延时函数，保留输入提交后的入队检查，完成后释放 objection。plusargs 由 test 读取并传给 source，固定样例的数量检查与最终报告仍在 test 中，通过 env.scoreboard 读取计数。source 不持有 scoreboard 句柄，也不从参考结果复制 actual。

第 42 份的四种静态预期保持不变：默认应比较两份结果、八个元素且无剩余预测；仅错值应发现一次 mismatch；仅缺输出应得到两组输入、一份输出、四个比较元素、一份待比较预测及零 mismatch，并由完整性检查报告失败；两参数同时启用应同时发现错值和缺失。全部用例未在 UVM 仿真器中编译或运行。此处 source 是有限的人工事务源，不是 driver、monitor、sequencer 或 DUT 模型；没有接口采样、周期时序或子系统接入，不能据此宣称项目已完成。顶层为 `matrix_env_demo`，固定 8 位及 2×2 的范围限制、按序配对和溢出待定约定沿用前课。

第 44 份新增 `matrix_env_config extends uvm_object`，用两个默认值为 0 的 bit 字段 inject_error、drop_last_result 集中保存人工场景开关。test 在 build_phase 创建 cfg，从原来的 +INJECT_ERROR 和 +DROP_LAST_RESULT 参数填入字段，然后调用 `uvm_config_db#(matrix_env_config)::set(this, "env", "cfg", cfg)`，再创建 env。这里相对路径 env 指向 uvm_test_top.env；cfg 是查找用的字段名，set/get 必须使用同一个配置类型和字段名。

env 在自己的 build_phase 用 get(this, "", "cfg", cfg) 取得配置，用 set(this, "source", "cfg", cfg) 定向传给 uvm_test_top.env.source，再创建 source 和 scoreboard。source 也在 build_phase 读取配置并打印两个开关；env/source 都对 get 失败或 null 配置做 fatal 保护。build_phase 从父组件向子组件执行，因此配置在对应子组件读取前就已发布。这里只使用精确的相对路径，没有全局通配符。

config_db 传递的是同一个对象句柄，不会自动复制或冻结字段。本例约定 test 发布后不再修改，env 只转发，source 只读取；这种只读约定不是语言层面的 const 保护。source.send_results() 改为无参函数，从 cfg 读取开关；test 的 run_phase 仍先提交输入、检查入队，再提交人工结果。scoreboard 不读取这些开关，始终要求结果正确且完整；选择注错场景不会使比较器容忍错误或缺失，因此三个故障组合仍应报告 TEACHING_CHECK_FAIL。

四种组合的计数、完整位宽数学计算、独立手填 actual 和结束检查均沿用第 43 份，所有用例仍未编译、未仿真。配置控制的是教学数据源行为，不是 DUT 的引脚或 N/M/DIN_WIDTH 参数；固定 8 位、2×2、时间 0 的样例范围不变。顶层为 `matrix_config_demo`，尚未接入真实 DUT 或子系统。

第 45 份将共同的 build/run/check/report 流程放在 matrix_base_test 中，新增 virtual configure_scenario()，默认把两个 cfg 开关都设为 0。build_phase 先创建 cfg，再调用该虚函数，最后才通过 config_db 发布并创建 env。派生测试可以覆写这个函数来选择场景，其余流程继承基类；这次调用不是在构造函数中进行，cfg 已经存在。每个故障测试先调用 super.configure_scenario() 恢复默认，再设置自己的开关。配置仍在发布后保持只读。

四个命名测试及静态预期如下；表中顺序均为输入数 / 已比较结果数 / 已比较元素数 / 待比较预测数 / mismatch 数：

| UVM 测试类名 | inject_error / drop_last_result | 预期计数 | 预期教学报告 |
| --- | --- | --- | --- |
| matrix_smoke_test | 0 / 0 | 2 / 2 / 8 / 0 / 0 | TEACHING_CHECK_PASS |
| matrix_wrong_value_test | 1 / 0 | 2 / 2 / 8 / 0 / 1 | TEACHING_CHECK_FAIL |
| matrix_missing_result_test | 0 / 1 | 2 / 1 / 4 / 1 / 0 | TEACHING_CHECK_FAIL |
| matrix_combined_fault_test | 1 / 1 | 2 / 1 / 4 / 1 / 1 | TEACHING_CHECK_FAIL |

顶层默认 run_test("matrix_smoke_test")。在支持 UVM 的仿真器中，可用运行参数 `+UVM_TESTNAME=matrix_missing_result_test` 等选择另一测试；一次仿真只选择一个。本课不再读取旧 +INJECT_ERROR / +DROP_LAST_RESULT 开关，场景由所选派生测试决定。UVM_TESTNAME 会优先于 run_test 的默认参数，这是 [Accellera 官方 uvm_root 源码](https://raw.githubusercontent.com/accellera-official/uvm-core/main/src/base/uvm_root.svh) 的行为；这里仅核对了官方实现，没有实际运行。派生测试注册了工厂类型，但实例名仍为 uvm_test_top，因此配置的 env/source 相对路径不变。注册的 matrix_base_test 若被显式选择，也采用两开关为 0 的默认设置；表中列出供本课使用的四个场景。

source、env、scoreboard、数学函数、两组输入和独立手填 C 均沿用第 44 份。三个故障测试仍会产生 UVM_ERROR 和教学 FAIL；尚未实现把“预期错误被正确检出”单独统计为回归通过的机制，也不能仅凭仿真进程退出码认定通过。所有命名测试均未编译、未仿真，表格不是运行报告。顶层为 matrix_test_cases_demo；仍无 DUT、接口时序或子系统接入。

第 46 份将第 36 份固定尺寸的数学参考思想扩展到正整数参数 DIN_WIDTH、N、M：A 为 N×M，B 为 M×N，C 为 N×N。乘积宽度为 2*DIN_WIDTH；EXTRA_BITS 在 M=1 时为 0，否则取 $clog2(M)，完整累加宽度 ACC_WIDTH 为两者之和。这是足以容纳全部合法输入的安全宽度，并非所有 M 下的最小宽度。N 改变输出数量，每个输出累加多少项则由 M 决定。参数在编译/展开时选择，本课不通过运行时 cfg 修改数组尺寸。

每个乘积先按符号位扩展到 ACC_WIDTH，再与同宽有符号 sum 相加；sum 对每个 C 元素清零。输入和输出边界由定宽位拼接生成，输出边界先保存为 signed 2*DIN_WIDTH，再有符号扩展到 ACC_WIDTH，避免无符号拼接的零扩展。已知答案也先将 1 或 M 存入 ACC_WIDTH 位变量再移位，避免 32 位 int 中间表达式限制。C_full 始终保留完整数学结果，fits_output 只报告它能否放入 signed 2*DIN_WIDTH；没有假定 DUT 的截断或饱和行为。

四组独立已知答案分别是：全零 A；仅偶数行最后一个 k 有贡献且 B 列交替取输入最大/最小值；仅 C[0][0] 累加 M 个 min×min、其他结果为零；全部 min×max。端点乘积由位移恒等式构造，不再调用另一套矩阵乘法循环。正端点 C00 只在 M=1 时能放入输出，其他零元素应始终可表示；负端点范围检查通过将已知答案窄化再符号扩展是否不变来独立判断。这里的窄化只用于检查可表示性，未规定 DUT 如何处理超范围值。

已使用本机 Icarus 13.0 对下面七组参数分别编译并运行，每组都核对四个样例的全部 C 元素及范围标志，共 108 个结果和 108 个标志，全部匹配：

| DIN_WIDTH | N | M | PRODUCT_WIDTH / ACC_WIDTH | 本组核对元素数 | 实际日志 |
| --- | --- | --- | --- | --- | --- |
| 8 | 2 | 3 | 16 / 18 | 16 | [默认参数](logs/46_reference_w8_n2_m3.log) |
| 8 | 3 | 2 | 16 / 17 | 36 | [N=3](logs/46_reference_w8_n3_m2.log) |
| 8 | 2 | 1 | 16 / 16 | 16 | [M=1](logs/46_reference_w8_n2_m1.log) |
| 4 | 2 | 4 | 8 / 10 | 16 | [4 位输入](logs/46_reference_w4_n2_m4.log) |
| 20 | 1 | 3 | 40 / 42 | 4 | [超过 32 位的结果](logs/46_reference_w20_n1_m3.log) |
| 2 | 2 | 4 | 4 / 6 | 16 | [负端点恰为输出下界 −8](logs/46_reference_w2_n2_m4.log) |
| 1 | 1 | 3 | 2 / 4 | 4 | [1 位输入边界](logs/46_reference_w1_n1_m3.log) |

默认参数下，正端点 C00=49152、负端点结果=-48768，二者均被保留且标记为超出 signed 16 位范围。另一次运行启用 +INJECT_UNKNOWN，在 A[0][0] 注入 X，得到 UNKNOWN_INPUT fatal 和退出码 1，这是预期拒绝；见 [X 注入日志](logs/46_reference_unknown.log)。各日志包含实际编译/运行命令及退出码。复现默认配置可执行：

```sh
mkdir -p build/lessons
/opt/homebrew/bin/iverilog -g2012 -Wall -s parameterized_reference_demo -o build/lessons/46_reference.vvp lessons/46_parameterized_reference.sv
/opt/homebrew/bin/vvp build/lessons/46_reference.vvp
/opt/homebrew/bin/vvp build/lessons/46_reference.vvp +INJECT_UNKNOWN
```

其他参数可在 iverilog 命令中加 `-Pparameterized_reference_demo.N=3` 等编译参数。顶层为 parameterized_reference_demo；本课仍是独立的普通 SystemVerilog 数学模型练习，尚未把参数化改动接入前课 UVM，也未验证 DUT、阵列周期或子系统。

第 47 份把输入事务类改为 `matrix_item #(int DIN_WIDTH=8, int N=2, int M=3)`。每个对象保存一整组 A[N][M] 和 B[M][N]，元素为 signed DIN_WIDTH 位；本例没有保存或计算 C。这三个整数是类的值参数，必须在选择具体特化时确定，不能像 cfg.inject_error 一样运行中赋值改变尺寸。字段保留 rand，但本课不调用 randomize，也未增加随机约束。

参数化对象使用 `uvm_object_param_utils(matrix_item #(DIN_WIDTH, N, M))`。该宏按类型注册，不提供用于按名称查找的字符串类型名；具体行为见 [Accellera 官方对象宏源码](https://raw.githubusercontent.com/accellera-official/uvm-core/main/src/macros/uvm_object_defines.svh)。顶层先 typedef 两个具体类型，再分别调用 `item_23_t::type_id::create("item23")` 和 `item_32_t::type_id::create("item32")`；create 的字符串参数是新对象的实例名，不是参数化类的工厂查找名称。宏也不会自动为 A/B 生成字段复制、比较或打印逻辑，本例自己提供 describe()。

两个示例类型的形状如下，这是根据声明推导的预期，不是仿真输出：

| 类型别名 | 参数 DIN_WIDTH / N / M | A | B | 每个元素位宽 |
| --- | --- | --- | --- | --- |
| item_23_t | 8 / 2 / 3 | 2×3 | 3×2 | 8 位有符号 |
| item_32_t | 4 / 3 / 2 | 3×2 | 2×3 | 4 位有符号 |

这两个特化是不同的类类型，各自通过工厂创建独立对象。顶层用 foreach 完整填写数组：item23 的 A 全为 -1、B 全为 2，item32 的 A 全为 1、B 全为 -2，都在各自表示范围内。describe() 用 $size 查询实际数组的两个维度，用 $bits 查询元素位宽，并打印对象实例名和 A/B 各一个样例值；没有依赖 get_type_name() 自动生成参数字符串。

本例只是参数化 UVM 对象的结构演示，没有 run_test、UVM phases、参考计算或 DUT 接口，未宣称任何计算检查通过。它与第 46 份已运行的数学模型尚未连接，也未将旧 env、scoreboard、analysis 端口全面参数化。正整数参数是前提，尚未在 UVM 仿真器中编译或运行。顶层为 parameterized_item_demo，应独立编译本文件。

第 48 份把第 47 份的参数化 matrix_item 交给参考计算。新增普通参数化类 matrix_reference，集中定义同一组 DIN_WIDTH/N/M 下的输入类型 item_t、完整结果数组类型 sum_array_t、范围标志类型 fits_array_t 及 calculate()。calculate 是 static 方法，通过类类型调用，无需 new 或 UVM 工厂注册参考工具类；它只使用类参数、常量、类型、函数参数和局部变量。输入事务仍是经 UVM 工厂创建的对象。

顶层以 matrix_reference#(8,2,3) 和 matrix_reference#(4,3,2) 定义 ref23_t/ref32_t，再从各自的 item_t 取得输入类型，从 sum_array_t/fits_array_t 取得对应输出数组类型。这样输入与数学函数的参数保持一致：第一组完整 C 为 2×2、每元素 signed 18 位、对应输出宽度16；第二组完整 C 为 3×3、每元素 signed 9 位、对应输出宽度8。接口调用形如 ref23_t::calculate(item23, C23, fits23)。

输入参数传递的是 item 句柄，函数只读 A/B；输出参数把完整 C 和标志数组的值带回调用方。没有对输入重新随机化，也没有复制一份 A/B 后另算。每次调用都对每个结果清零、计算完整内积并填写全部标志；下一次用相同输出变量调用会覆盖其内容，本课还没有预测对象或预测队列。数学计算保留第 46 份的参数化宽度、有符号扩展与范围判定，并检查空输入及 X/Z；这些保护使用 $fatal，提前终止且不计入 UVM_FATAL 报告计数。

本例预置三组独立已知答案，均为尚未运行的检查代码：

| 参数 DIN_WIDTH / N / M | 输入样例 | 每个 C 的已知答案 | fits_output | 元素数 |
| --- | --- | --- | --- | --- |
| 8 / 2 / 3 | A 全为 -1，B 全为 2 | -6 | 1 | 4 |
| 4 / 3 / 2 | A 全为 1，B 全为 -2 | -4 | 1 | 9 |
| 8 / 2 / 3 | A/B 全为 -128 | 49152 | 0 | 4 |

检查使用独立的定宽常量及 !==，预计核对17个参考结果和17个范围标志。第三组是在第一组同步计算及检查结束后重新填写 item23，再覆盖 C23/fits23；没有其他组件保留该输入句柄，因此这不是发布后修改共享事务的示例。REFERENCE_OBJECT_DEMO_PASS 若将来出现，只代表这些数学已知答案检查通过，不表示存在 DUT actual 或完成阵列验证。

本文件需要 UVM，尚未编译、未仿真。第 46 份普通 SystemVerilog 数学模型的实际通过不能代替本课类、工厂和数组接口的集成验证。本课没有 UVM phases、接口时序、scoreboard 或子系统，顶层为 parameterized_reference_object_demo，需单独编译。

第 49 份新增参数化 matrix_prediction，继承 uvm_object 并使用 uvm_object_param_utils。它从同参数的 matrix_reference 取得 sum_array_t 和 fits_array_t，保存完整 C_full、逐元素 fits_output，以及本地 case_id；这些字段不是 rand，不保存 A/B 副本或输入对象句柄。顶层从 prediction 类型取得 reference 类型，再从 reference 取得输入类型，使整条计算与存储链路使用相同参数。

8/2/3 和 4/3/2 分别形成两个具体 prediction 类型，本例各用自己的 typed queue。每组输入都创建新的 item 和 prediction，先算入 prediction.C_full/fits_output，再 push_back。队列保存对象句柄，没有自动深拷贝；循环下一次将局部句柄指向新对象，不会改变队列中之前的对象。预测入队后只读，不能复用同一个 prediction 并不断覆盖其中的结果。

三份预测全部生成后，才按队列索引读取，检查数量、case_id 顺序和独立常量答案。已知答案由预定队列位置决定，不从待检查对象的 case_id 或计算结果反推。预期内容如下，尚未通过仿真验证：

| 队列及位置 | 参数 DIN_WIDTH / N / M | 本地 case_id | 每个 C 的已知答案 / fits_output |
| --- | --- | --- | --- |
| predictions23[0] | 8 / 2 / 3 | 0 | -6 / 1 |
| predictions23[1] | 8 / 2 / 3 | 1 | 49152 / 0 |
| predictions32[0] | 4 / 3 / 2 | 0 | -4 / 1 |

两份 2×2 和一份 3×3 共17个元素及标志；第一份在所有后续计算完成后仍应保留 -6，能用独立答案检查发现对象复用导致的覆盖。超出输出范围的49152也保存在完整位宽对象中，未丢弃且未选择 DUT 溢出策略。case_id 只在本地队列内编号，不是 DUT 返回的 transaction ID。

本例没有 actual 输出、pop_front 配对或完整 scoreboard，队列有意保留全部预测至演示结束。PREDICTION_STORAGE_PASS 若将来出现，仅表示三份预测的数学答案和存储检查通过。代码尚未在 UVM 仿真器中编译或运行，也未连接 UVM phases、接口时序或子系统。顶层为 parameterized_predictions_demo，需单独编译；第46份的数学模型通过不代表此参数化对象/队列集成已通过。

第 50 份新增 matrix_result#(DIN_WIDTH,N)，保存 N×N 个 signed 2*DIN_WIDTH 位 C 元素。M 决定参考内积及累加位宽，但不改变输出矩阵的形状或每个输出元素位宽，因此该输出载体不需要 M 参数；这并不提供事务身份或自动配对保证。matrix_result 使用参数化 UVM 对象工厂，字段非 rand，本课由独立常量手填，未采样 DUT。

matrix_result_checker#(DIN_WIDTH,N,M) 是普通无状态工具类，集中引用同参数的 prediction/reference 类型和对应 result 类型。它的 static compare() 每次先把 mismatches、compared_elements 置零，检查两个句柄非空，并在比较任何元素前确认全部 fits_output 严格为 1。遇到越界或未知范围标志，使用 REFERENCE_NOT_COMPARABLE fatal 终止，不定义 DUT 截断或饱和策略。可比较时，把实际元素先存入 signed 2W 临时变量，再复制符号位扩展到参考 ACC_WIDTH，用 !== 逐元素比较；实际 X/Z 也会成为 mismatch。完整参考计算、类型和预测存储仍沿用前课。

为演示全部完成比较，本课第二个 8 位输入样例改为 A 全1、B 全3，结果全9，取代第49课的49152越界样例。这是改变输入 fixture，不是静默丢弃越界预测。三个独立手填输出依次为：8/2/3 的全 -6 和全9，以及4/3/2的全 -4，全部可由对应的16位或8位输出表示。三份预测先全部入队，再按各自队列顺序提交手填 actual，人工输出从未读取预测字段来填值。

调用方先确认预测队列非空，将队首和 actual 交给 compare，正常返回后才 pop_front。数值 mismatch 会计数并返回，使其余元素与矩阵继续比较；null/范围 fatal 则在出队前停止。每次返回的计数累加到顶层总数，最后要求两条预测队列都为空、共3份结果/17个元素且总 mismatch 为0。两个参数组仍使用各自的具体类型和队列；FIFO顺序只是本课人工场景约定，没有建立真实阵列的输出协议。

默认用例按静态推导应完成三份人工矩阵比较并打印 TEACHING_CHECK_PASS。+INJECT_ERROR 在第一份 actual 入队前，把 C[1][0] 从 -6 改为 -5，应产生一次 RESULT_MISMATCH，完成17个元素比较后以 TEACHING_CHECK_FAILED fatal 结束，不会打印通过。这两种路径以及 null/越界保护均未在 UVM 仿真器中编译或运行；不提供虚构日志。此处没有 UVM phases、analysis 端口、scoreboard 组件、接口时序或 DUT；顶层为 parameterized_matching_demo，需独立编译。

第 51 份新增 matrix_scoreboard#(DIN_WIDTH,N,M)，继承 uvm_scoreboard，使用 uvm_component_param_utils 按具体类型创建。scoreboard 内的 checker/prediction/reference/item/result 类型由同一组参数推导，this_t 别名表示当前 scoreboard 特化。package 仅声明一次 _input、_output 两个 analysis imp 后缀；input_in 使用 #(item_t,this_t) 并回调 write_input，output_in 使用 #(result_t,this_t) 并回调 write_output。宏的类型参数确保连接双方事务类型对应，但不替代 DUT 时序及结果配对协议。

write_input 每次新建预测对象，调用参考函数后入队并登记输入数。write_output 先检查实际对象及待比较队列，再复用第50份 checker.compare；返回后才出队、累加结果数/元素数/mismatch 数。比较器继续用 $display 打印具体错值，scoreboard 对非零 mismatch 发出 UVM_ERROR，避免详细打印未进入 UVM 报告计数却最终显示通过。check_phase 分别检查至少有输入、输入输出数一致、无剩余预测、已收到矩阵的元素数量完整及无 mismatch；组件没有写死某一场景的矩阵个数。

非参数化的 parameterized_scoreboard_test 同时创建两个具体 scoreboard：8/2/3 的 scoreboard23 和4/3/2的 scoreboard32。test 有四个类型匹配的 analysis port，在 connect_phase 分别连接两组 input_in/output_in。run_phase 持有 objection，先完成三组输入提交，再按序提交独立手填的 -6、9、-4 输出，所有 write 同步发生于时间0，结束后释放 objection。对象提交后不再修改。这展示同一个组件类在不同参数下复用，尚未接入真实输入/输出 monitor。

test 的 check_phase 单独要求 scoreboard23 为2组输入/2份输出/8个比较元素，scoreboard32为1组输入/1份输出/9个元素；各自队列完整性由 scoreboard 检查。所有 check_phase 完成后，test 的 report_phase 根据全局 UVM_ERROR/UVM_FATAL 计数报告教学结果。默认静态预期是3份人工矩阵、17个元素全部匹配；+INJECT_ERROR 只把第一份 C[1][0] 改为 -5，应记录一次 mismatch，并到达 TEACHING_CHECK_FAIL。一次 mismatch 可产生即时错误和 check_phase 汇总错误，错误消息数不等于 mismatch 数。

默认 UVM_ERROR 不保证仿真进程退出码非零，应检查 UVM 日志与教学报告。保留的数学/比较 helper 对非法输入、空预测或不可比较范围仍使用 $fatal，默认直接终止，既不增加 UVM_FATAL 计数，也不到达正常 report_phase；scoreboard 自身的 null/空队列等保护使用 uvm_fatal，同样默认提前终止。正常、注错及保护路径全部尚未在 UVM 仿真器中编译或运行。本课尚无 env、DUT、接口时序或子系统；顶层为 parameterized_scoreboard_demo，需独立编译。

第 52 份开始准备子系统的输入数据，固定 DIN_WIDTH=8、N=2、M=3。A 为 2×3，B 为 3×2；第 k 个输入字包含 A 的第 k 列和 B 的第 k 行，共 2*N 个元素，因此 BUS_WIDTH=2*DIN_WIDTH*N=32。遍历 k=0、1、2 可以得到完整一组 A/B 的三个输入字；这里没有规定它们在哪个时钟周期被 FIFO 接收。

PDF 未指定 din 的位序。本课采用的教学约定是：低 N*DIN_WIDTH 位放 A 列，高 N*DIN_WIDTH 位放 B 行，每半段内索引 0 的元素占最低位。对应公式为 `word[i*DIN_WIDTH +: DIN_WIDTH] = A[i][k]` 和 `word[(N+j)*DIN_WIDTH +: DIN_WIDTH] = B[k][j]`。在本例中，拼接写法为 `{B[k][1], B[k][0], A[1][k], A[0][k]}`；这是局部演示约定，不能当作已确认的 DUT 协议，[规格问题清单](../docs/spec-questions.md) 中的位序问题仍待确认。

固定输入 A=`[[1,-2,3],[4,5,-6]]`，B=`[[7,8],[-9,10],[11,-12]]`，按上述位序独立写出的已知答案为：

| k | A 的一列（行索引递增） | B 的一行（列索引递增） | 32 位输入字 |
| --- | --- | --- | --- |
| 0 | 1，4 | 7，8 | 32'h08070401 |
| 1 | -2，5 | -9，10 | 32'h0AF705FE |
| 2 | 3，-6 | 11，-12 | 32'hF40BFA03 |

pack_input_word(k) 只读取 A/B 并返回打包值，访问数组前有 k 范围保护；非法 k 路径尚未运行。顶层先用 `!==` 对比三个独立十六进制常量，避免只做打包后解包而漏掉双方一致的位序错误，再把每个切片赋给 signed 8 位变量，与原始元素逐一比较。切片本身是原始位串，先存入有符号变量后再解释数值，才能将 FE、F7、FA、F4 分别显示为 -2、-9、-6、-12。

本机 Icarus 13.0 编译成功；正常运行核对了三个字和十二个元素，打印 PACKING_DEMO_PASS，退出码为 0，见[正常运行日志](logs/52_subsystem_input_packing.log)。另一次启用 +INJECT_ERROR，翻转第二个字的 bit 0，使 0AF705FE 变成 0AF705FF；独立常量检查报告 PACKING_MISMATCH fatal，退出码为 1，未打印通过，见[注错日志](logs/52_subsystem_input_packing_injected.log)。两个日志均保存实际编译、运行命令及退出码。在项目目录复现：

```sh
mkdir -p build/lessons
/opt/homebrew/bin/iverilog -g2012 -Wall -s subsystem_input_packing_demo -o build/lessons/52_subsystem_input_packing.vvp lessons/52_subsystem_input_packing.sv
/opt/homebrew/bin/vvp build/lessons/52_subsystem_input_packing.vvp
/opt/homebrew/bin/vvp build/lessons/52_subsystem_input_packing.vvp +INJECT_ERROR
```

最后一条命令预期失败。此例全部在时间 0 进行，无时钟、wr_fifo、full、FIFO、UVM 或 DUT，也不计算矩阵乘法；通过只表示这组数据符合所选打包约定。三个字不等于已经完成三次 FIFO 写入，也不能直接当作 PE 阵列边界的逐拍输入。顶层为 subsystem_input_packing_demo，需单独编译。

第 53 份沿用第 52 份准备的三个 32 位字，重点改为观察实际接受的写入。局部教学合同是：在 sys_clk 正沿，以沿前的 `wr_fifo && !in_fifo_full` 判断接受；writer 在负沿驱动，满时让 wr_fifo=0 并保留当前待发送字，只有接受后才增加 next_word。等待空位不计作一次传输。这里直接使用前课的三个已知字，没有重新实现矩阵打包函数，也没有接入 UVM driver。

教学 FIFO 只有一个存储槽，occupied 决定 full；存储和占用状态在正沿用非阻塞赋值更新。模型空时可写，满时可由内部 consumer 取走，但不支持空时当拍写入并消费，也不支持满时同拍消费并替换为新字。该选择使满状态下发生消费的那个正沿仍不能接受新写入。同步低有效复位、10 ns 周期及上述接受条件都是本例假设；真实子系统 FIFO 的握手、深度和时钟域问题仍待确认。

consumer 起初暂停，80 ns 在负沿启用，以保证实际占用会造成等待。它的 consume_enable 是模型内部的教学控制，不能映射成 PDF 外部的 rd_fifo；PDF 的 rd_fifo 用于读取输出 FIFO。此处没有 sr_clk、跨时钟逻辑、输出 FIFO、阵列计算或面试方 RTL。

正沿观察器分别维护 accepted_count 和 consumed_count，并将 din 或沿前存储槽数据与独立手填常量比较；不读取 writer 的 next_word 或 prepared_words 来决定期望值。因此 writer 如果错误跳过某个字，不会带着观察器一起跳过检查。观察器还检查控制信号为已知值、当前教学 writer 没有在 full 时置高 wr_fifo。全部字消费后，等待下一个负沿检查计数、空状态及确实发生过等待；500 ns watchdog 限制此有限样例的等待时间。未知值等保护路径及 watchdog 路径未单独注错运行。

本机 Icarus 13.0 实际编译、运行结果如下：

| 时刻 | 正常运行的事件 |
| --- | --- |
| 35 ns | 接受第 1 个字 08070401，槽变满 |
| 45、55、65、75 ns | writer 等待，保留第 2 个字 |
| 85 ns | 消费第 1 个字；沿前仍为满，因此 writer 继续等待 |
| 95 ns | 接受第 2 个字 0AF705FE |
| 105 ns | 消费第 2 个字；writer 等待第 3 个字的空位 |
| 115 ns | 接受第 3 个字 F40BFA03 |
| 125 ns | 消费第 3 个字 |
| 130 ns | 检查完成：3 次接受、3 次消费、6 个等待采样沿，槽为空 |

正常路径打印 WRITE_DEMO_PASS，退出码为 0，见[正常日志](logs/53_fifo_write_acceptance.log)。启用 +INJECT_SKIP 后，writer 在 45 ns 满状态下故意丢弃待发送的第 2 个字；95 ns 实际送来的第 3 个字与观察器仍期待的第 2 个字不符，触发 ACCEPT_ORDER fatal，退出码为 1，未打印通过，见[跳过数据的注错日志](logs/53_fifo_write_acceptance_injected.log)。这验证了本例的顺序检查可以发现该错误，不是完整的 FIFO 验证结论。

在项目目录单独运行；最后一条命令预期失败：

```sh
mkdir -p build/lessons
/opt/homebrew/bin/iverilog -g2012 -Wall -s fifo_write_acceptance_demo -o build/lessons/53_fifo_write_acceptance.vvp lessons/53_fifo_write_acceptance.sv
/opt/homebrew/bin/vvp build/lessons/53_fifo_write_acceptance.vvp
/opt/homebrew/bin/vvp build/lessons/53_fifo_write_acceptance.vvp +INJECT_SKIP
```

顶层为 fifo_write_acceptance_demo。普通 SystemVerilog 教学模型的运行不替代 UVM 编译或真实 DUT 验证；PDF 的接受条件仍保留在[规格问题清单](../docs/spec-questions.md) 中。

第 54 份增加输入 monitor 的矩阵重组逻辑，固定 DIN_WIDTH=8、N=2、M=3。沿用第 52 份的低半部 A 列／高半部 B 行位序，以及第 53 份在正沿以沿前 wr_fifo && !in_fifo_full 判断接受的教学约定。此例只有一帧，另外假设初始复位后第一个接受字对应 k=0，后续每个接受字按 k 递增；M 是本例已知常量。没有实现或确认真实 M_minus_one 的锁存、逐帧更新、帧边界或运行中复位协议。

monitor 独立维护 rebuild_k，仅在接受事件中把引脚 din 的切片写入 `observed_A[lane][rebuild_k]` 和 `observed_B[rebuild_k][lane]`，不读取 writer 的 next_word 或 prepared_words 数组来重组。A/B 的每个元素都是 signed 8 位四态变量，保存负数的补码并以有符号数显示。正常 writer 在满时仍保留待发送 din，但 monitor 不收这些等待拍。写入重组数组使用阻塞赋值，先复制本次所有元素再递增 k，因此第三次接受后可以立即检查刚写入的最后一列／行。

初始复位清零 monitor 计数，重组数组置 X；访问数组前有边界保护。rebuild_k 达到 M 时才核对完整矩阵，并登记一份已完成输入帧。独立手填的 known_A/known_B 为 `[[1,-2,3],[4,5,-6]]` 和 `[[7,8],[-9,10],[11,-12]]`，没有由输入字解包生成。逐元素用 !== 比较，以发现错位、错误符号值或未知值；结束要求重组 k=M、恰好 1 帧、12 个元素完成检查，并保留前课的接受数、消费数、等待及清空检查。

本机 Icarus 13.0 编译运行成功。三次采样发生在 35、95、115 ns，分别填写 k=0、1、2；中间六个等待采样沿不增加重组索引。115 ns 的 FRAME_COMPLETE 表示输入 A/B 已收齐，不表示矩阵计算或输出 C 已完成；教学 FIFO 在 125 ns 消费最后一个字，130 ns 完成整体检查。正常日志记录 frames=1、elements=12、accepted=3、consumed=3、waits=6，并以 0 退出，见[正常日志](logs/54_input_reconstruction.log)。

`+INJECT_LANE_SWAP` 故意让 monitor 把 A 的两个 lane 交换，FIFO 接受的三个输入字仍正确，B 的重组也保持原样。完整帧检查在 115 ns 发现 A[0][0] 实际为 4、期望为 1，以 REBUILD_A fatal 和退出码 1 结束，未打印通过，见[重组错位注入日志](logs/54_input_reconstruction_injected.log)。这是检查 monitor 实现错误的用例，不是注入 DUT 算术错误；本课不再保留第 53 份的 +INJECT_SKIP 入口。额外字、未知控制及 watchdog 保护路径未单独运行。

在项目目录单独运行；最后一条命令预期失败：

```sh
mkdir -p build/lessons
/opt/homebrew/bin/iverilog -g2012 -Wall -s input_reconstruction_demo -o build/lessons/54_input_reconstruction.vvp lessons/54_input_reconstruction.sv
/opt/homebrew/bin/vvp build/lessons/54_input_reconstruction.vvp
/opt/homebrew/bin/vvp build/lessons/54_input_reconstruction.vvp +INJECT_LANE_SWAP
```

顶层为 input_reconstruction_demo。此例尚未把 observed_A/B 交给数学参考模型，也未创建 UVM transaction、analysis 连接或真实 DUT；只检查从已接受输入到完整矩阵的重组过程。原有单时钟、深度 1 FIFO、内部 consumer 及位序等局部假设保持不变。

第 55 份在第三次接受、重组完最后一列 A／最后一行 B 后，调用 calculate_reference_from_observed()。函数仅从 monitor 的 observed_A/B 读取运算数据，不从 writer 的 prepared_words 或检查用 known_A/B 取值。保留第 54 份的 12 个输入元素检查，确认收齐一帧后才调用参考函数；函数额外检查 rebuild_k=M、completed_frames=1。这里只处理固定 DIN_WIDTH=8、N=2、M=3 的单帧，仍使用前课未获 PDF 确认的位序、接受条件及帧定位假设。

参考算法复用第 46 份的完整位宽方法：signed 16 位保存乘积，显式符号扩展到 signed 18 位再累加，每个 C 元素的 sum 独立清零。18 位来自 2*DIN_WIDTH+$clog2(M)，是安全宽度。计算前复制输入元素到四态标量并检查 X/Z；C_full 保存完整数学值，fits_output 分别检查能否由 signed 16 位输出表示。没有选择 DUT 的溢出、截断或饱和策略。本课未单独运行未知值或未收齐输入的保护路径。

本例 A=`[[1,-2,3],[4,5,-6]]`、B=`[[7,8],[-9,10],[11,-12]]`，独立手填 C_known=`[[58,-48],[-83,154]]`。四个结果都应有 fits_output=1；例如 C[0][0]=1*7+(-2)*(-9)+3*11=58。check_prediction 使用 !== 比较全部完整结果及范围标志，结束时额外要求参考函数恰好调用一次、四个结果全部检查。C_known 用来检查本课参考模型的连接和计算，不是 DUT 的实际输出。

本机 Icarus 13.0 编译及正常运行成功：115 ns 收齐 A/B 后，同一仿真时刻生成并核对四个期望值，打印 PREDICTION_READY；125 ns 教学 FIFO 消费最后一个字，130 ns 检查完成并打印 OBSERVED_REFERENCE_PASS。计数为一帧、12 个输入元素、1 次参考调用、4 个预测检查、3 次接受、3 次消费、6 个等待采样沿，退出码为 0，见[正常日志](logs/55_observed_reference.log)。参考函数不推进仿真时间，115 ns 仅是本例期望计算的完成时刻，不代表 DUT 输出 C 的时刻或运算延迟。

`+INJECT_PREDICTION_ERROR` 在参考计算之后、独立结果检查之前，将 C_full[0][0] 从 58 改为 59。115 ns 的 PREDICTION_MISMATCH 显示 full=59、known=58、fits=1，退出码为 1，未打印通过，见[预测改错日志](logs/55_observed_reference_injected.log)。它验证独立常量检查能发现被改动的预测值，不是模拟 DUT 错误。本课移除了第 54 份的 +INJECT_LANE_SWAP 入口。

在项目目录单独运行；最后一条命令预期失败：

```sh
mkdir -p build/lessons
/opt/homebrew/bin/iverilog -g2012 -Wall -s observed_reference_demo -o build/lessons/55_observed_reference.vvp lessons/55_observed_reference.sv
/opt/homebrew/bin/vvp build/lessons/55_observed_reference.vvp
/opt/homebrew/bin/vvp build/lessons/55_observed_reference.vvp +INJECT_PREDICTION_ERROR
```

顶层为 observed_reference_demo。当前通路为“接口接受输入 → monitor 重组 A/B → 数学参考函数 → C_full 与 fits_output”，尚未接入输出 monitor、实际 C、UVM 组件或面试方 RTL。单时钟教学 FIFO 也不构成真实子系统或跨时钟行为的验证。

第 56 份保留第 55 份的输入接受、重组、完整位宽参考计算及独立常量自检，新增 compare_manual_result()。预测在 115 ns 生成并检查后，将 prediction_pending 置 1；本例只允许一份待处理预测，不是多帧队列。主流程在输入 FIFO 排空、原有输入和预测计数检查完成后的 130 ns，独立手填 signed 16 位 C_demo=`[[58,-48],[-83,154]]` 并调用比较任务。填值不读取 C_full 或 C_known。130 ns 是演示程序安排的比较时刻，不代表 DUT 输出到达时间或延迟。

比较任务先要求存在待处理预测，再遍历全部 fits_output，确认每个值严格为 1 后才开始数值比较。每个 C_demo 元素先存入 signed 16 位四态变量，再显式符号扩展到 signed 18 位，以 !== 与 C_full 比较；避免负数被零扩展或 X/Z 被普通条件表达式漏掉。完整数学预测保持不变，未自行采用溢出截断或饱和规则。空预测、不可比较范围及实际输出含 X/Z 的路径本课未单独注错运行。

任务会检查全部四个元素，记录逐项匹配情况，累计比较元素数与不匹配数，然后清除 prediction_pending 并登记已处理一份结果。清除 pending 只代表该结果已完成比较，不代表比较通过。结束条件还独立要求一份结果、四个元素、无待处理预测和零 mismatch；遇到错值时先完成全部逐元素检查，再通过 RESULT_CHECK_FAILED fatal 结束。本课移除了第 55 份的 +INJECT_PREDICTION_ERROR 入口。

本机 Icarus 13.0 编译及正常运行通过：130 ns 四项全部 RESULT_MATCH，计数为 manual_matrices=1、compared_elements=4、mismatches=0、pending=0，打印 OBSERVED_COMPARISON_PASS，退出码为 0，见[正常日志](logs/56_observed_result_comparison.log)。输入仍为一帧、12 个元素，参考调用一次并核对四个期望值，三次写入、三次消费及六个等待采样沿均沿用前课。

`+INJECT_RESULT_ERROR` 仅将手填 C_demo[1][0] 从 -83 改为 -82，预测仍为 -83。实际日志显示三项 RESULT_MATCH、一项 RESULT_MISMATCH；完成四项后，RESULT_PROCESSED 记录 matrices=1、elements=4、mismatches=1、pending=0，随后以 RESULT_CHECK_FAILED 和退出码 1 结束，没有通过标志，见[手填结果改错日志](logs/56_observed_result_comparison_injected.log)。这是比较器对人工输出的教学检查，尚无输出 FIFO、输出 monitor、UVM 或面试方 RTL。

在项目目录单独运行；最后一条命令预期失败：

```sh
mkdir -p build/lessons
/opt/homebrew/bin/iverilog -g2012 -Wall -s observed_result_comparison_demo -o build/lessons/56_observed_result_comparison.vvp lessons/56_observed_result_comparison.sv
/opt/homebrew/bin/vvp build/lessons/56_observed_result_comparison.vvp
/opt/homebrew/bin/vvp build/lessons/56_observed_result_comparison.vvp +INJECT_RESULT_ERROR
```

顶层为 observed_result_comparison_demo，固定 DIN_WIDTH=8、N=2、M=3。前课的位序、沿前接受条件、单帧定位及单时钟深度 1 FIFO 等局部教学假设保持不变，不能据此认定真实子系统已验证。

第 57 份增加 +DROP_RESULT，故意不提交唯一一份手填结果。输入采集、重组、数学参考和预测自检照常完成；DROP 分支不填 C_demo、不注入错值、不调用 compare_manual_result，也不清除 prediction_pending。有限人工源完成提交或省略的选择后，将 manual_source_done 置 1，再调用 check_completion。此标志只表示本例人工源已经结束，不是 DUT 信号；130 ns 的收尾不是对真实 DUT 的超时判定。

check_completion 汇总四类检查：已比较矩阵数是否等于完整输入帧数；是否还有待处理预测；每份已收到结果是否检查了 N*N 个元素；是否存在数值 mismatch。保留前课输入帧恰为 1、参考调用恰为 1、输入和预测自检数量正确的检查，避免零输入与零输出一起误报通过。各类失败分别打印诊断，最后用 COMPLETION_FAILED fatal 统一结束，只有无失败时才打印 COMPLETION_DEMO_PASS。

缺结果时，compared_matrices=0、compared_elements=0、mismatch_count=0、prediction_pending=1。没有进行比较，所以没有数值 mismatch；MATRIX_COUNT 与 PENDING_RESULT 会分别发现数量不齐及遗留预测。两个失败检查源于同一份缺失结果，不代表丢了两份。ELEMENT_COUNT 检查的是已收到结果的逐份完整性，0==0*N*N 在此成立，因此它不报错，也不能替代矩阵数量检查。

本机 Icarus 13.0 已编译并实际运行全部四种组合，均在 130 ns 到达收尾。每组完整输入帧数及参考调用数均为 1：

| 运行参数 | 已比较矩阵 / 元素 | mismatch / pending | 完成检查失败数 | 退出码与日志 |
| --- | --- | --- | --- | --- |
| 无 | 1 / 4 | 0 / 0 | 0 | 0，[正常日志](logs/57_observed_completion.log) |
| +INJECT_RESULT_ERROR | 1 / 4 | 1 / 0 | 1 | 1，[错值日志](logs/57_observed_completion_wrong.log) |
| +DROP_RESULT | 0 / 0 | 0 / 1 | 2 | 1，[缺结果日志](logs/57_observed_completion_missing.log) |
| 两个参数同时使用 | 0 / 0 | 0 / 1 | 2 | 1，[组合日志](logs/57_observed_completion_combined.log) |

同时使用两个参数时，DROP 分支优先，日志打印 DROP_PRECEDENCE；没有提交结果，也没有注入数值错误，因此只检测缺失，mismatch 仍为 0。三种故障组合均无通过标志。保留的 500 ns watchdog、未知控制、空预测及范围保护路径本课未单独注错运行。

在项目目录单独运行；后三条命令预期失败：

```sh
mkdir -p build/lessons
/opt/homebrew/bin/iverilog -g2012 -Wall -s observed_completion_demo -o build/lessons/57_observed_completion.vvp lessons/57_observed_completion.sv
/opt/homebrew/bin/vvp build/lessons/57_observed_completion.vvp
/opt/homebrew/bin/vvp build/lessons/57_observed_completion.vvp +INJECT_RESULT_ERROR
/opt/homebrew/bin/vvp build/lessons/57_observed_completion.vvp +DROP_RESULT
/opt/homebrew/bin/vvp build/lessons/57_observed_completion.vvp +DROP_RESULT +INJECT_RESULT_ERROR
```

顶层为 observed_completion_demo，仍固定 DIN_WIDTH=8、N=2、M=3，仅有一个待处理预测。通过只涉及教学输入 FIFO、数学期望及人工结果的检查；真实输出 monitor、输出 FIFO、UVM 组件和面试方 RTL 尚未接入，原有位序、握手及帧定位假设保持待确认状态。

第 58 份新增 rd_fifo、out_fifo_empty、dout，以及一次预装最多两字的教学输出 FIFO。局部读协议采用 FWFT：非空时 dout 已显示队首，在 sys_clk 正沿以沿前 rd_fifo && !out_fifo_empty 判定接受；指针用非阻塞赋值前进，因此正沿 monitor 读到旧队首。reader 在负沿驱动 rd_fifo，读完后到下一个负沿观察更新后的 empty 再决定是否继续。PDF 没有确认这一读延迟行为，不能将它直接用于未知 DUT。

输出位序也采用明确的教学假设：每个 32 位字表示 C 的一行，低 16 位为第 0 列，高 16 位为第 1 列，按行号递增输出。130 ns 人工源独立预装如下常量，不读取 C_full、C_known 或已重组的输入来生成数据：

| 行号 | 输出字 | 低 16 位（第 0 列） | 高 16 位（第 1 列） |
| --- | --- | --- | --- |
| 0 | 32'hFFD0003A | 58 | -48 |
| 1 | 32'h009AFFAD | -83 | 154 |

这是一个仅供教学的有限输出源，只有初始化后的单次预装和按序读出，没有动态入队、输出 full、跨时钟逻辑或真实矩阵计算。输入侧原有的 consume_enable 仍是输入模型内部消费控制；新增的 rd_fifo 才用于本例输出接口。固定 DIN_WIDTH=8、N=2、M=3、单帧定位和初始复位范围保持不变。

独立输出 monitor 只在接受读事件时，从 dout 的切片写入 signed 16 位 C_observed[output_row][j]，使用自己的行号和读字计数，不读取 output_storage、output_length 或输出指针来重组。阻塞赋值确保最后一行写完后才调用 compare_observed_result；随后沿用 signed 16→18 位符号扩展、全部范围标志检查及逐元素比较。未收齐两行时不比较部分矩阵，也不清除待处理预测。输入侧预测在 115 ns 已准备好，本例没有处理输入预测与输出完整矩阵同时到达的通用配对问题。

正常运行中，130 ns 完成人工预装，140 ns reader 首次驱动读请求，145 ns 采样第一行，155 ns 采样第二行并比较四项，160 ns 确认输出源排空后收尾。135 ns 虽然 dout 已有第一行，但没有读请求，不采样。这里的具体时间由教学程序安排，不是 DUT 延迟或吞吐规格；源排空结束也不是未知真实硬件的超时判定。

完成检查新增 output_word_count == completed_frames*N，保留完整结果数量、pending、每份结果的元素完整性及错值检查。+DROP_LAST_ROW 只让首行可读；reader 按实际非空状态排空源，不等待预期的两行，因此在 150 ns 到达收尾。此时读字数=1、已组装行数=1、完整结果数=0、比较元素数=0、mismatch=0、pending=1；OUTPUT_WORD_COUNT、MATRIX_COUNT、PENDING_RESULT 三项分别报告缺字、缺完整结果及遗留预测，均源于同一缺行故障。

本机 Icarus 13.0 已实际编译运行四种组合：

| 运行参数 | 读字数 / 已比较矩阵 / 元素 | mismatch / pending | 完成检查失败数 | 退出码与日志 |
| --- | --- | --- | --- | --- |
| 无 | 2 / 1 / 4 | 0 / 0 | 0 | 0，[正常日志](logs/58_output_reconstruction.log) |
| +INJECT_RESULT_ERROR | 2 / 1 / 4 | 1 / 0 | 1 | 1，[错值日志](logs/58_output_reconstruction_wrong.log) |
| +DROP_LAST_ROW | 1 / 0 / 0 | 0 / 1 | 3 | 1，[缺行日志](logs/58_output_reconstruction_missing.log) |
| 两个参数同时使用 | 1 / 0 / 0 | 0 / 1 | 3 | 1，[组合日志](logs/58_output_reconstruction_combined.log) |

错值用例将第二个字改为 32'h009AFFAE，monitor 实际采到 C[1][0]=-82，对照期望 -83 产生一次 mismatch；完整四项仍全部比较。组合用例以缺行为优先，第二行未被改动或提交，无数值比较；三种故障运行均没有通过标志。本课使用 +DROP_LAST_ROW 代替第 57 份的 +DROP_RESULT；未知输出控制、空读、额外行及 watchdog 等保护路径未单独注错运行。

在项目目录单独运行；后三条命令预期失败：

```sh
mkdir -p build/lessons
/opt/homebrew/bin/iverilog -g2012 -Wall -s output_reconstruction_demo -o build/lessons/58_output_reconstruction.vvp lessons/58_output_reconstruction.sv
/opt/homebrew/bin/vvp build/lessons/58_output_reconstruction.vvp
/opt/homebrew/bin/vvp build/lessons/58_output_reconstruction.vvp +INJECT_RESULT_ERROR
/opt/homebrew/bin/vvp build/lessons/58_output_reconstruction.vvp +DROP_LAST_ROW
/opt/homebrew/bin/vvp build/lessons/58_output_reconstruction.vvp +DROP_LAST_ROW +INJECT_RESULT_ERROR
```

顶层为 output_reconstruction_demo。通过仅验证所选教学协议下的输入采集、期望计算、输出采样重组和比较；monitor 仍为过程块实现，没有 UVM 组件、sr_clk、CDC 或面试方 RTL。输出每字一行、位序及 FWFT 时序仍须对真实设计确认。
