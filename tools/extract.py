import pyarrow.parquet as pq, glob, os, re
from PIL import Image
import io
OUT = "/home/hatch/workspace/last-signal/assets/sprites/atlas-candidates"
os.makedirs(OUT, exist_ok=True)
def clean(s): return re.sub(r"[^a-z0-9]+","_", s.lower()).strip("_")[:60]
wanted = {
 "player": lambda s,c: s in ("scientist","space explorer","explorer","space engineer","engineer","humanoid robot","astronaut") and "top-down" in c,
 "player_any": lambda s,c: s in ("scientist","space explorer","explorer","space engineer") and ("top-down" in c or "side-view" in c),
 "floor": lambda s,c: s == "floor tile",
 "wall": lambda s,c: s in ("brick wall segment","castle wall segment"),
 "props": lambda s,c: s in ("robot companion","security camera","battery","satellite dish","radar dish","signal beacon","computer tower","shipping crate","door","energy cell","electric generator"),
}
counts = {k:0 for k in wanted}
limits = {"player":10,"player_any":10,"floor":10,"wall":8,"props":30}
for f in sorted(glob.glob("/home/hatch/workspace/last-signal/assets/pixel-atlas/train-*.parquet")):
    t = pq.read_table(f, columns=["image","caption","subject","row_id"])
    imgs = t.column("image").to_pylist(); caps = t.column("caption").to_pylist()
    subj = t.column("subject").to_pylist(); rids = t.column("row_id").to_pylist()
    for img,c,s,r in zip(imgs,caps,subj,rids):
        for k,fn in wanted.items():
            if counts[k] >= limits[k]: continue
            if fn(s,c.lower()):
                d = os.path.join(OUT,k); os.makedirs(d, exist_ok=True)
                p = os.path.join(d, f"{r}_{clean(s)}.png")
                if not os.path.exists(p):
                    open(p,"wb").write(img["bytes"])
                counts[k]+=1
                print(k, r, s, "|", c)
    if all(counts[k]>=limits[k] for k in wanted): break
print(counts)
