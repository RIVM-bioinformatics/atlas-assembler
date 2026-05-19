import sys
import json
import os

if len(sys.argv) < 3:
    print("Usage: python parse_fastplong.py <input1.json> [<input2.json> ...] <output.tsv>")
    sys.exit(1)

input_jsons = sys.argv[1:-1]
output_tsv = sys.argv[-1]

columns = [
    "sample",
    # Before filtering
    "before_total_reads", "before_total_bases", "before_q20_bases", "before_q30_bases", "before_q20_rate", "before_q30_rate", "before_read_mean_length", "before_gc_content",
    # After filtering
    "after_total_reads", "after_total_bases", "after_q20_bases", "after_q30_bases", "after_q20_rate", "after_q30_rate", "after_read_mean_length", "after_gc_content",
    # Filtering result
    "passed_filter_reads", "low_quality_reads", "too_many_N_reads", "too_short_reads", "too_long_reads"
]

rows = []

for input_json in input_jsons:
    sample = os.path.splitext(os.path.basename(input_json))[0]
    with open(input_json) as f:
        data = json.load(f)
    before = data['summary']['before_filtering']
    after = data['summary']['after_filtering']
    result = data['filtering_result']
    row = [sample]
    row += [before.get(k, "") for k in ['total_reads', 'total_bases', 'q20_bases', 'q30_bases', 'q20_rate', 'q30_rate', 'read_mean_length', 'gc_content']]
    row += [after.get(k, "") for k in ['total_reads', 'total_bases', 'q20_bases', 'q30_bases', 'q20_rate', 'q30_rate', 'read_mean_length', 'gc_content']]
    row += [result.get(k, "") for k in ['passed_filter_reads', 'low_quality_reads', 'too_many_N_reads', 'too_short_reads', 'too_long_reads']]
    rows.append(row)

with open(output_tsv, "w") as out:
    out.write("\t".join(columns) + "\n")
    for row in rows:
        out.write("\t".join(str(x) for x in row) + "\n")