import pyarrow.parquet as pq, glob, collections
files = sorted(glob.glob("/home/hatch/workspace/last-signal/assets/pixel-atlas/train-*.parquet"))
total = 0
all_subj = collections.Counter()
for f in files:
    pf = pq.ParquetFile(f)
    n = pf.metadata.num_rows
    total += n
    print(f.split("/")[-1], n)
print("total train rows:", total)
# search all shards for human-like subjects
stems = ["scientist","researcher","astronaut","hazmat","spaceman","person","human","soldier","explorer","pilot","engineer","technician","survivor","guard ","worker","character","robot","cyborg","android","golem","knight","wizard","elf","dwarf","alien"]
hits = collections.defaultdict(list)
for f in files:
    t = pq.read_table(f, columns=["subject","caption","row_id"])
    subj = t.column("subject").to_pylist(); cap = t.column("caption").to_pylist(); rid = t.column("row_id").to_pylist()
    for s,c,r in zip(subj,cap,rid):
        low = s.lower()
        for st in stems:
            if st in low:
                hits[st].append((f.split("/")[-1], r, s, c))
for st in stems:
    if hits[st]:
        print(f"\n== {st}: {len(hits[st])}")
        for h in hits[st][:5]: print("  ", h)
