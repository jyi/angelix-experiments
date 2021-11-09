import os
import Levenshtein
import sys


act_out_file = sys.argv[1]
with open(act_out_file, "r", encoding="ISO-8859-1") as f:
    actual = f.read()

exp_out_file = sys.argv[2]
with open(exp_out_file, "r", encoding="ISO-8859-1") as f:
    expected = f.read()

cost = Levenshtein.distance(expected, actual)
print('cost: {}'.format(cost))

cost_file = os.getenv('ANGELIX_COST_FILE')
if cost_file is not None:
    with open(cost_file, "w") as f:
        f.write(str(cost))
