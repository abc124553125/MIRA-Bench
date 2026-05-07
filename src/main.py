from __future__ import annotations

import argparse
import yaml

from .core.benchmark_runner import BenchmarkRunner
from .core.utils import set_seed, save_json, ensure_dir


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", type=str, required=True)
    args = parser.parse_args()

    with open(args.config, "r", encoding="utf-8") as f:
        cfg = yaml.safe_load(f)

    set_seed(int(cfg.get("seed", 42)))
    output_dir = ensure_dir(cfg["paths"]["output_dir"])
    save_json(cfg, output_dir / f"{cfg['experiment_name']}_config_used.json")

    runner = BenchmarkRunner(cfg)
    df = runner.run()
    print(f"Done. Evaluated {len(df)} samples.")


if __name__ == "__main__":
    main()
