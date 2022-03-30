import csv
import sys
from pyecharts.charts import Page, Sunburst
from pyecharts import options as opts


class TopDown:
    """TopDown node"""
    def __init__(self, name, percentage):
        self.name = name
        if isinstance(percentage, TopDown):
            self.percentage = percentage.percentage
        else:
            self.percentage = percentage
        self.down = {}
        self.top = None
        self.level = 0

    def __add__(self, rhs):
        if isinstance(rhs, TopDown):
            return self.percentage + rhs.percentage
        return self.percentage + rhs

    def __radd__(self, lhs):
        if isinstance(lhs, TopDown):
            return lhs.percentage + self.percentage
        return lhs + self.percentage

    def __sub__(self, rhs):
        if isinstance(rhs, TopDown):
            return self.percentage - rhs.percentage
        return self.percentage - rhs

    def __rsub__(self, lhs):
        if isinstance(lhs, TopDown):
            return lhs.percentage - self.percentage
        return lhs - self.percentage

    def __mul__(self, rhs):
        if isinstance(rhs, TopDown):
            return self.percentage * rhs.percentage
        return self.percentage * rhs

    def __rmul__(self, lhs):
        if isinstance(lhs, TopDown):
            return lhs.percentage * self.percentage
        return lhs * self.percentage

    def __truediv__(self, rhs):
        if isinstance(rhs, TopDown):
            return self.percentage / rhs.percentage
        return self.percentage / rhs

    def __rtruediv__(self, lhs):
        if isinstance(lhs, TopDown):
            return lhs.percentage / self.percentage
        return lhs / self.percentage

    def add_down(self, name, percentage):
        """Add a leaf node

        Args:
            name (str): Name of leaf node
            percentage (float): Percentage of leaf node

        Returns:
            TopDown: leaf
        """
        self.down[name] = TopDown(name, percentage)
        self.down[name].top = self
        self.down[name].level = self.level + 1
        return self.down[name]

    def draw(self):
        """Draw the TopDown sunburst chart

        Returns:
            _type_: _description_
        """
        if not self.down:
            return [opts.SunburstItem(name=self.name, value=self.percentage)]
        items = []
        for value in self.down.values():
            items.append(value.draw()[0])
        if self.top:
            return [opts.SunburstItem(name=self.name, value=self.percentage, children=items)]
        return items



def process_one(path, head):
    """Process one chart

    Args:
        path (String): csv path
        head (String): chart head

    Returns:
        Sunburst chart
    """
    with open(path, encoding='UTF-8') as file:
        csv_file = dict(csv.reader(file))

    csv_file['total_slots'] = int(csv_file['total_cycles']) * 6

    stall_cycles_core = float(csv_file['stall_cycle_fp']) + float(csv_file['stall_cycle_int']) + float(csv_file['stall_cycle_rob']) + float(csv_file['stall_cycle_int_dq']) + float(csv_file['stall_cycle_fp_dq'])

    top = TopDown("Top", 1.0)

    frontend_bound = top.add_down("Frontend Bound", float(csv_file['decode_bubbles']) / float(csv_file['total_slots']))
    bad_speculation = top.add_down("Bad Speculation", (float(csv_file['slots_issued']) - float(csv_file['slots_retired']) + float(csv_file['recovery_bubbles'])) / float(csv_file['total_slots']))
    retiring = top.add_down("Retiring", float(csv_file['slots_retired']) / float(csv_file['total_slots']))
    backend_bound = top.add_down("Backend Bound", top - frontend_bound - bad_speculation - retiring)

    fetch_latency = frontend_bound.add_down("Fetch Latency", float(csv_file['fetch_bubbles']) / float(csv_file['total_slots']))
    fetch_bandwidth = frontend_bound.add_down("Fetch Bandwidth", frontend_bound - fetch_latency)
    branch_mispredicts = bad_speculation.add_down("Branch Mispredicts", bad_speculation)
    memory_bound = backend_bound.add_down("Memory Bound", backend_bound * float(csv_file['stall_cycle_ls_dq']) / (
        stall_cycles_core + float(csv_file['stall_cycle_ls_dq'])))
    core_bound = backend_bound.add_down("Core Bound", backend_bound - memory_bound)

    itlb_miss = fetch_latency.add_down("iTLB Miss", float(csv_file['itlb_miss_cycles']) / float(csv_file['total_cycles']))
    icache_miss = fetch_latency.add_down("iCache Miss", float(csv_file['icache_miss_cycles']) / float(csv_file['total_cycles']))
    fetch_latency_others = fetch_latency.add_down("Others", fetch_latency - itlb_miss - icache_miss)
    stores_bound = memory_bound.add_down("Stores Bound", float(csv_file['store_bound_cycles']) / float(csv_file['total_cycles']))
    loads_bound = memory_bound.add_down("Loads Bound", memory_bound - stores_bound)
    integer_dq = core_bound.add_down("Integer DQ", core_bound * float(csv_file['stall_cycle_int_dq']) / stall_cycles_core)
    floatpoint_dq = core_bound.add_down("Floatpoint DQ", core_bound * float(csv_file['stall_cycle_fp_dq']) / stall_cycles_core)
    rob = core_bound.add_down("ROB", core_bound * float(csv_file['stall_cycle_rob']) / stall_cycles_core)
    integer_prf = core_bound.add_down("Integer PRF", core_bound * float(csv_file['stall_cycle_int']) / stall_cycles_core)
    floatpoint_prf = core_bound.add_down("Floatpoint PRF", core_bound * float(csv_file['stall_cycle_fp']) / stall_cycles_core)

    if 'l1d_loads_bound_cycles' in csv_file:
        l1d_loads_bound = loads_bound.add_down("L1D Loads Bound", float(csv_file['l1d_loads_bound_cycles']) / float(csv_file['total_cycles']))
        l2_loads_bound = loads_bound.add_down("L2 Loads Bound", float(csv_file['l2_loads_bound_cycles']) / float(csv_file['total_cycles']))
        l3_loads_bound = loads_bound.add_down("L3 Loads Bound", float(csv_file['l3_loads_bound_cycles']) / float(csv_file['total_cycles']))
        ddr_loads_bound = loads_bound.add_down("DDR Loads Bound", float(csv_file['ddr_loads_bound_cycles']) / float(csv_file['total_cycles']))

    return (
        Sunburst(init_opts=opts.InitOpts(width="1000px", height="1200px"))
        .add(series_name="", data_pair=top.draw(), radius=[0, "90%"])
        .set_global_opts(title_opts=opts.TitleOpts(title=head))
        .set_series_opts(label_opts=opts.LabelOpts(formatter="{b}")))


title = sys.argv[1]
directory = sys.argv[2]
suffix = sys.argv[3]
print(title)
(
    Page(page_title=title, layout=Page.SimplePageLayout)
    # .add(process_one("spec06_rv64gcb_o2_20m/256/" + sys.argv[1], title + "_256"))
    # .add(process_one("spec06_rv64gcb_o2_20m/600/" + sys.argv[1], title + "_600"))
    # .add(process_one("spec06_rv64gcb_o2_20m/600_scaled/" + sys.argv[1], title + "_600_scaled"))
    .add(process_one(directory + "/csv/" + title + ".log.csv", title + "_" + suffix))
    .render(directory + "/html/" + title + ".html"))
