import json
import os
import sentence_transformers
import sys
import torch

model_name = os.getenv("MODEL_NAME")
if not model_name:
    raise "Must set MODEL_NAME env var"
command_sep = os.getenv("COMMAND_SEP")
if not command_sep:
    raise "Must set COMMAND_SEP env var"

model = sentence_transformers.SentenceTransformer(model_name, device="cpu")
model = model.to(dtype=torch.float16)


def encode(txt):
    return model.encode(txt).tolist()

def writesync(f, s):
    f.write(s)
    f.flush()

def read_input():
    accum = []
    while True:
        line = sys.stdin.readline().strip()
        writesync(sys.stderr, f"readline: {line}\n")
        if line == command_sep:
            inp = "\n".join(accum)
            writesync(sys.stderr, f"readinput: {inp}")
            return inp
        accum.append(line)

def write_output(text):
    txt = f"{text}\n{command_sep}\n"
    writesync(sys.stderr, f"write: {len(txt)}\n")
    writesync(sys.stdout, txt)
    writesync(sys.stderr, f"wrote\n")

while True:
    try:
        inp = read_input()
        enc = encode(inp)
        resp = {"embeddings": enc, "input": inp}
        write_output(json.dumps(resp))
    except (BrokenPipeError, IOError):
        sys.exit(0)
