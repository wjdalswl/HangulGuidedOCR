# Open OCR Baseline Comparison

Apple Vision OCR is treated as the main closed-source black-box baseline in
the paper. To check whether HangulGuidedOCR's ordered/spot-guided strategy is
useful beyond Apple Vision, the experiment repository also evaluates open OCR
engines.

| Engine | Scope | GT rows | Target O/G | Core O/G | Title O/S |
|---|---|---:|---:|---:|---:|
| EasyOCR | full | 1236 | 1.393 / 0.066 | 0.840 / 0.023 | 9.333 / 0.333 |
| Tesseract | full | 1236 | 1.439 / 0.082 | 1.255 / 0.096 | 6.333 / 1.667 |
| PaddleOCR | bounded | 36 | -- | 0.636 / 0.459 | 5.667 / 1.333 |

`Target O/G` means targeted synthetic original vs guided strip. `Core O/G`
means core hard original vs guided strip. `Title O/S` means stylized title
original vs pre-spot strip.

The full reproduction script is maintained in:

```text
https://github.com/wjdalswl/textspotting-guided-vision-ocr
```

The summary files copied into this repository are:

```text
results/open_ocr_baselines/open_ocr_baseline_summary.csv
results/open_ocr_baselines/open_ocr_baseline_compact_table.csv
results/open_ocr_baselines/open_ocr_baseline_summary.json
```

PaddleOCR is reported as a runtime-bounded auxiliary observation because
CPU-only execution on macOS arm64 was substantially slower than Tesseract and
EasyOCR.
