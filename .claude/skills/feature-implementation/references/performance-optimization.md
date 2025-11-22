# Performance Optimization Guide

## Quick Profiling Steps
- Measure baseline with lightweight benchmarking (e.g., `time`, `bench`, `pytest -k benchmark`).
- Identify top hotspots with profiler of the target stack (Node: `0x`/Chrome DevTools, Python: `cProfile`, Rust: `cargo flamegraph`).
- Focus on the top 1-2 bottlenecks before wider changes.

## Common Patterns
- Prefer streaming/iterator処理でメモリ常駐を避ける。
- バッチ処理やまとめ書きでIO回数を削減。
- キャッシュはTTLと容量上限を必ず設定し、失効戦略を明示。
- 並列化は共有リソースとロック粒度を確認して適用。

## Verification Checklist
- 最適化前後で同じテストスイートがPASSすることを確認。
- 目標指標（p95レイテンシ/スループット/メモリ）を定義し、改善率を測定。
- 回帰を防ぐため、ベンチマークをCIに組み込み可能か検討。
