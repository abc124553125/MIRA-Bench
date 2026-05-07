# MIRA-Bench Evaluation Code

This repository contains the evaluation code for MIRA-Bench, a benchmark for
visual reasoning in mirror and reflective-surface scenes. The repository is
prepared for anonymous review: it does not include the dataset files, model
weights, raw logs, or private API keys.

The code supports RGB, RGB+D, RGB+mirror-marked, and RGB+D+mirror-marked
evaluation settings. It produces per-sample predictions, grouped metrics,
overall metrics, and an Excel summary.


## Repository Layout

```text
MIRA-Bench-anonymous/
  configs/                 # Example evaluation configs
  scripts/
    run/                   # End-to-end launchers for common evaluations
    setup/                 # Model download / external dependency setup scripts
    serve/                 # Local vLLM serving scripts
  src/
    main.py                # Main entry point: python -m src.main --config ...
    core/                  # Dataset loading, prompting, runner, scoring, reporting
    models/                # OpenAI, Gemini, local OpenAI-compatible, DeepSeek, MiniCPM adapters
    tools/                 # Optional diagnostics
  Dataset/                 # Empty placeholder. Download the Kaggle dataset here
  requirements.txt         # Core Python dependencies for evaluation and reporting
  .env.example             # Placeholder environment variables
```

The following generated or external contents are intentionally ignored by Git
in this code repository:

```text
Dataset/*      # Dataset images, annotations, and precomputed visual prompts
models/        # Downloaded model weights
third_party/   # External repositories cloned by setup scripts
Outputs/       # Evaluation outputs
logs/          # Runtime logs
```

The repository keeps an empty `Dataset/` placeholder only. Dataset files are
distributed separately on Kaggle. Download the Kaggle dataset release and
extract or copy its contents into this repository's `Dataset/` folder before
running evaluation.


## Expected Dataset Layout

After downloading the released dataset from Kaggle, `Dataset/` should contain:

```text
Dataset/
  _cache/
    *_bbox_*.jpg
    *_depth_bbox_*.png
    *_binmask_*.png
  _cache_mm/
    *_bbox_*.jpg
    *_depth_bbox_*.png
  images/
    rgb/
    depth_colorized/
    mirror_marked_rgb/
    mirror_marked_depth/
  annotations/
    questions.json                  # required by evaluation
    objects.json                    # optional dataset metadata, not read by evaluation
```

The provided configs assume:

```yaml
paths:
  qa_json: "Dataset/annotations/questions.json"
  data_root: "."
  rgb_dir: "Dataset/images/mirror_marked_rgb"
  depth_dir: "Dataset/images/mirror_marked_depth"
  output_dir: "Outputs/<experiment_name>"
```

`Dataset/annotations/questions.json` is the only annotation file read by the
evaluation runner. It is expected to contain the visual asset paths used by the
benchmark. For the released question file, visual bbox and mask questions refer
directly to:

```text
./Dataset/_cache/...
./Dataset/_cache_mm/...
```

Therefore these two cache directories are required for full evaluation. They
are not temporary runtime caches in this release; they are precomputed visual
prompt assets used by `visual_bbox`, `visual_bbox_desc`, and `visual_mask`
questions.

`reviewed_text_desc.json` is not used by evaluation and is not required for
reproducing benchmark scores. Text descriptions used by the benchmark are
already materialized in `questions.json`.

If your dataset is stored elsewhere, edit the `paths` block in the chosen
config file.


## Environment Setup

We recommend Python 3.10 or 3.11.

```bash
git clone <anonymous-repository-url> MIRA-Bench
cd MIRA-Bench

python3 -m venv .venv
source .venv/bin/activate
python -m pip install -U pip
python -m pip install -r requirements.txt
```

`requirements.txt` is sufficient for:

- loading the dataset
- building prompts
- calling OpenAI-compatible cloud APIs
- calling Gemini APIs
- calling local OpenAI-compatible vLLM servers
- scoring and reporting

Direct-load local models such as DeepSeek-VL2 and MiniCPM-V have heavier
GPU-specific dependencies. Their setup scripts install those additional
packages in the target environment.

For cloud models, export the relevant API key:

```bash
export OPENAI_API_KEY="your_openai_api_key"
export GOOGLE_API_KEY="your_google_api_key"
```

You may also copy `.env.example` to `.env` for local bookkeeping, but the
scripts read environment variables from the shell.


## Quick Start

After installing dependencies and extracting the Kaggle dataset into
`Dataset/`, run one of the following minimal commands.

Gemini Flash RGBDM:

```bash
export GOOGLE_API_KEY="your_google_api_key"
python -m src.main --config configs/Benchmark_config_gemini_2_5_flash_rgbdm.yaml
```

OpenAI-style RGBDM:

```bash
export OPENAI_API_KEY="your_openai_api_key"
python -m src.main --config configs/Benchmark_config_rgbdm.yaml
```

Local vLLM RGBDM, after starting a compatible server:

```bash
export OPENAI_API_KEY=EMPTY
python -m src.main --config configs/Benchmark_config_qwen3_vl_8b_rgbdm.yaml
```

For a quick test, set `input.max_samples: 20` in the config first. For the full
benchmark, set `input.max_samples: null`.


## Paper Table Coverage

The evaluation code covers the model and baseline rows used in the paper table:

| Table row | How to reproduce or locate it |
| --- | --- |
| Random Guess | Automatically reported as `random_baseline` in summary files. |
| Human Performance (RGB) | Human-study baseline; not generated by the model runner. Use the released human-evaluation records if provided with the dataset release. |
| Human Performance (RGB-D) | Human-study baseline; not generated by the model runner. Use the released human-evaluation records if provided with the dataset release. |
| GPT-5.4 | `configs/Benchmark_config_rgbdm.yaml` or the four-condition runner `scripts/run/Run_gpt5.4_parallel.sh`. |
| Gemini-2.5-Pro | `configs/Benchmark_config_gemini_2_5_pro_rgbdm.yaml`. |
| Gemini-2.5-Flash | `configs/Benchmark_config_gemini_2_5_flash_rgbdm.yaml`. |
| Qwen3.5-9B | `configs/Benchmark_config_qwen3_rgbdm.yaml`. |
| Qwen3-VL-8B | `configs/Benchmark_config_qwen3_vl_8b_rgbdm.yaml`. |
| Qwen2.5-VL-7B | `configs/Benchmark_config_qwen2_5_vl_7b_rgbdm.yaml`. |
| LLaVA-OV-7B | `configs/Benchmark_config_llava_ov_7b_rgbdm.yaml`. |
| InternVL3-8B | `configs/Benchmark_config_internvl3_rgbdm.yaml`. |
| DeepSeek-VL2-Tiny | `configs/Benchmark_config_deepseek_vl2_tiny_rgbdm.yaml`. |

The automated runner writes model predictions and metrics. Human baselines are
not model executions; they should be computed from the released human response
files or copied from the paper's human-study protocol.


## Running a Small Smoke Test

Before launching a full evaluation, set `input.max_samples` in a config to a
small value, for example:

```yaml
input:
  max_samples: 20
```

Then run:

```bash
python -m src.main --config configs/Benchmark_config_gemini_2_5_flash_rgbdm.yaml
```

Successful output will be written to:

```text
Outputs/<experiment_name>/
  <experiment_name>_per_sample.csv
  <experiment_name>_overall.json
  <experiment_name>_summary.xlsx
```


## Running Cloud-API Models

### OpenAI-Compatible OpenAI Models

Edit the `model` block in a config:

```yaml
model:
  provider: "openai"
  model_name: "<openai-model-name>"
  api_key_env: "OPENAI_API_KEY"
  temperature: 0.0
  max_tokens: 2048
  timeout_sec: 120
```

Then run:

```bash
export OPENAI_API_KEY="your_openai_api_key"
python -m src.main --config configs/Benchmark_config_rgbdm.yaml
```

To launch the four input conditions in parallel:

```bash
export OPENAI_API_KEY="your_openai_api_key"
bash scripts/run/Run_gpt5.4_parallel.sh
```

If you use a different OpenAI model, update `model_name` and
`experiment_name` in the relevant config files.

### Google Gemini

The Gemini adapter uses the official Google Gen AI Python client:

```bash
export GOOGLE_API_KEY="your_google_api_key"
python -m src.main --config configs/Benchmark_config_gemini_2_5_flash_rgbdm.yaml
```

For Gemini Pro:

```bash
export GOOGLE_API_KEY="your_google_api_key"
python -m src.main --config configs/Benchmark_config_gemini_2_5_pro_rgbdm.yaml
```

The batch runner is:

```bash
export GOOGLE_API_KEY="your_google_api_key"
CONFIG=configs/Benchmark_config_gemini_2_5_flash_rgbdm.yaml \
BATCH_RUNS=1 \
bash scripts/run/Run_gemini_rgbdm.sh
```


## Running Local OpenAI-Compatible VLMs

The evaluation code can call a local vLLM server through the OpenAI-compatible
API interface. Install vLLM according to the official documentation:

https://github.com/vllm-project/vllm

Then download and serve a model.

### Qwen3-VL-8B-Instruct

Model page:

https://huggingface.co/Qwen/Qwen3-VL-8B-Instruct

Download:

```bash
bash scripts/setup/Setup_qwen3_vl_8b.sh
```

Serve:

```bash
bash scripts/serve/Serve_qwen3_vl_8b_vllm.sh
```

In another terminal:

```bash
export OPENAI_API_KEY=EMPTY
python -m src.main --config configs/Benchmark_config_qwen3_vl_8b_rgbdm.yaml
```

### Qwen3.5-9B

The included scripts use a local OpenAI-compatible endpoint. If you use a
different Qwen-family model, set `MODEL_ID`, `MODEL_DIR`, and the config
`model_name` accordingly.

```bash
bash scripts/setup/Setup_qwen3.sh
bash scripts/serve/Serve_qwen3_vllm.sh
export OPENAI_API_KEY=EMPTY
python -m src.main --config configs/Benchmark_config_qwen3_rgbdm.yaml
```

### Qwen2.5-VL-7B-Instruct

Model page:

https://huggingface.co/Qwen/Qwen2.5-VL-7B-Instruct

Download:

```bash
bash scripts/setup/Setup_qwen2_5_vl_7b.sh
```

Serve:

```bash
bash scripts/serve/Serve_qwen2_5_vl_7b_vllm.sh
```

In another terminal:

```bash
export OPENAI_API_KEY=EMPTY
python -m src.main --config configs/Benchmark_config_qwen2_5_vl_7b_rgbdm.yaml
```

### LLaVA-OneVision-7B

Model page:

https://huggingface.co/lmms-lab/llava-onevision-qwen2-7b-ov

Download:

```bash
bash scripts/setup/Setup_llava_ov_7b.sh
```

Serve:

```bash
bash scripts/serve/Serve_llava_ov_7b_vllm.sh
```

In another terminal:

```bash
export OPENAI_API_KEY=EMPTY
python -m src.main --config configs/Benchmark_config_llava_ov_7b_rgbdm.yaml
```

### InternVL3-8B

Model page:

https://huggingface.co/OpenGVLab/InternVL3-8B

Serve with vLLM after downloading the model to `models/InternVL3-8B`:

```bash
bash scripts/serve/Serve_internvl3_vllm.sh
export OPENAI_API_KEY=EMPTY
python -m src.main --config configs/Benchmark_config_internvl3_rgbdm.yaml
```


## Running Direct-Load Local Models

Some models are loaded directly rather than through vLLM.

### DeepSeek-VL2

External code repository:

https://github.com/deepseek-ai/DeepSeek-VL2

Model pages:

https://huggingface.co/deepseek-ai/deepseek-vl2-tiny

https://huggingface.co/deepseek-ai/deepseek-vl2-small

Setup and run the tiny model:

```bash
bash scripts/setup/Setup_deepseek_vl2_tiny.sh
bash scripts/run/Run_deepseek_vl2_tiny_rgbdm.sh
```

Setup and run the small model:

```bash
bash scripts/setup/Setup_deepseek_vl2_small.sh
bash scripts/run/Run_deepseek_vl2_small_rgbdm.sh
```

The setup scripts clone the external DeepSeek-VL2 repository into
`third_party/DeepSeek-VL2` and download model weights into `models/`. These
directories are ignored by Git.

### MiniCPM-V 2.6

Model page:

https://huggingface.co/openbmb/MiniCPM-V-2_6

Setup and run:

```bash
bash scripts/setup/Setup_minicpm_v_2_6.sh
bash scripts/run/Run_minicpm_v_2_6_rgbdm.sh
```


## Config Fields

Important fields in each YAML config:

```yaml
experiment_name: "name_used_for_output_files"

paths:
  qa_json: "Dataset/annotations/questions.json"
  data_root: "."
  output_dir: "Outputs/experiment_name"
  rgb_dir: "Dataset/images/mirror_marked_rgb"
  depth_dir: "Dataset/images/mirror_marked_depth"

input:
  use_depth: true
  use_mirror_marked: true
  max_samples: null
  allowed_question_types: null
  allowed_referring_styles: null
  allowed_template_ids: null
  include_categories: null
  exclude_categories: null

model:
  provider: "openai"        # openai | google | qwen_openai_compatible | deepseek_vl2 | minicpm_v
  model_name: "model-name"
  api_key_env: "OPENAI_API_KEY"
  temperature: 0.0
  max_tokens: 2048

runtime:
  save_raw_response: true
  retry_times: 2
  checkpoint_every_n: 10
  resume_from_checkpoint: true
```

The benchmark supports filtering by question type, referring style, template
ID, and category. This is useful for debugging or reproducing ablations.


## Output Files and Metrics

For each run, the reporter writes:

```text
Outputs/<experiment_name>/
  <experiment_name>_per_sample.csv
  <experiment_name>_overall.json
  <experiment_name>_summary.xlsx
  <experiment_name>_vc_joint.json        # if visibility-classification groups exist
  <experiment_name>_raw/                 # optional raw model responses
```

The summary workbook contains sheets for:

- overall metrics
- category
- subcategory
- template_id
- question_type
- referring_style
- depth/mirror requirements
- model_name
- random baseline by question type
- visibility-classification joint scoring details
- error and parse-failure analysis

Main metrics:

- `exact_acc`: exact-match accuracy.
- `partial_acc`: partial score. For multi-choice questions this is set overlap;
  for 3D spatial-axis questions this is the fraction of correct axes.
- `random_baseline`: theoretical random baseline from the answer space.


## Resuming Interrupted Runs

The runner supports checkpointing. Relevant config fields:

```yaml
runtime:
  checkpoint_every_n: 10
  write_checkpoint_reports: true
  resume_from_checkpoint: true
  resume_success_only: true
```

If a run stops, rerun the same command. Existing successful rows in
`<experiment_name>_per_sample.csv` are reused, and remaining samples continue.


## Reproducibility Checklist for Reviewers

1. Install dependencies from `requirements.txt`.
2. Download the Kaggle dataset release and extract it under the expected
   `Dataset/` layout, including `_cache` and `_cache_mm`.
3. Choose the config matching the input condition and model.
4. Export the required API key or start the local model server.
5. Run a smoke test with `max_samples: 20`.
6. Set `max_samples: null` for the full evaluation.
7. Compare metrics in `<experiment_name>_summary.xlsx` and
   `<experiment_name>_overall.json`.


## Notes

- The repository intentionally does not ship model weights. Use the linked
  Hugging Face or GitHub repositories to obtain each model.
- The repository intentionally does not ship raw run logs or private outputs.
- No API keys are stored in this repository.
