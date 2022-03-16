# top-down 分析工具

本仓库集成了 top-down 分析所需要的工具。

## 运行仿真

1. 将仿真文件拷贝至 `emus` 目录下，如 `emus/emu_20220316_0`
2. 修改 `run_emu.sh` 中的 `emu` 变量为你的仿真可执行文件，如 `emu_20220316_0`
3. 将要运行的测试名称写在 `file.f` 中，具体格式可以参考已有文件（目前最大并行度设置为 16 个 emus，以 fifo 顺序运行 `file.f` 中的程序，因此可按需调整该文件的内容）
4. 在 tmux/screen 中运行 `./run_emu.sh`，或是 `nohup ./run_emu.sh`，以忽略退出终端时的 hup 信号

## 提取性能计数器

1. 性能计数器位于 `${spec_name}/${emu}.dir` 中，如 `spec06_rv64gcb_o2_20m/emu_20220316_0.dir`
2. 性能计数器包含 warmup 过程的结果，因此需要先删去每个文件的前半部分（有现成的命令可以干这件事情，TODO: 自动化这一过程）
3. 提取 csv 格式的 top-down 性能计数器

```bash
cd ${spec_name}/${emu}.dir
for file in `ls`; do
../../top-down.sh ${file}
done
```

## 生成图表

生成图表使用的是 `top_down.py`，而 `to_chart.sh` 对其进行了进一步的封装，需要关注的代码如下所示

```python
# top_down.py
(
    Page(page_title=title, layout=Page.SimplePageLayout)
    .add(process_one("spec06_rv64gcb_o2_20m/256/" + sys.argv[1], title + "_256"))
    .add(process_one("spec06_rv64gcb_o2_20m/600/" + sys.argv[1], title + "_600"))
    .add(process_one("spec06_rv64gcb_o2_20m/600_scaled/" + sys.argv[1], title + "_600_scaled"))
    .render("out/" + title + ".html"))
```

每一个以 `.add` 开头的行代表了一个子图，可以按需增删这些行。

然后，运行 `./to_chart.sh` 即可。
