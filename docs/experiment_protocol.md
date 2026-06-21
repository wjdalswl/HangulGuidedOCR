# Experiment Protocol

## English

The public repository keeps reproducible summaries rather than raw private datasets. The benchmark is organized into four groups:

| Group | Size | Role |
|---|---:|---|
| Core real/hard Korean cases | 20 | Real or controlled hard cases that expose vertical and dispersed Korean reading-order failures. |
| Targeted Korean poster synthetic | 600 | Controlled Korean poster/card-news layouts for measuring layout-specific correction. |
| Canva/MiriCanvas manual templates | 124 | Manually transcribed design-template cases used to verify that auto strategy does not harm ordinary horizontal OCR. |
| Public Korean sign probe | 15 | Public sign photos with manual GT used as a supplementary real-world probe. |

The main reported aggregate contains 784 ground-truth samples. Raw Vision, preprocessing-only, postprocessing-only, and preprocessing-plus-postprocessing variants are compared. The final public claim is based on the always-on `HangulGuidedOCR(auto)` mode, not on manually choosing the best branch after seeing the result.

Because Apple Vision OCR is a closed-source API, an additional open OCR check
was added with Tesseract, EasyOCR, and PaddleOCR. Tesseract and EasyOCR were
run on the full public subset, while PaddleOCR was run on a runtime-bounded
subset due to CPU-only execution time on macOS arm64. The purpose of this
comparison is to show that the contribution is a text-region and ordered-point
correction strategy around OCR engines, not an internal Apple Vision model
modification.

Original Canva/MiriCanvas template images are not redistributed. The repository includes only summary metrics, protocol notes, figures, and final reports.

## Korean

공개 레포에는 비공개 원본 데이터셋 대신 재현 가능한 요약 산출물을 둡니다. 벤치마크는 네 그룹으로 구성됩니다.

| 그룹 | 크기 | 역할 |
|---|---:|---|
| 핵심 실제/난이도 높은 한국어 사례 | 20 | 세로쓰기와 분산 한국어 읽기 순서 실패를 드러내는 실제 또는 controlled hard 사례입니다. |
| 한국어 포스터 targeted synthetic | 600 | 레이아웃별 보정 효과를 측정하기 위한 통제된 한국어 포스터/카드뉴스 샘플입니다. |
| Canva/MiriCanvas 수동 전사 템플릿 | 124 | 일반 가로형 OCR을 auto strategy가 해치지 않는지 검증하기 위한 수동 전사 디자인 템플릿입니다. |
| 공개 한글 간판 probe | 15 | 보조적인 실제 환경 probe로 사용한 공개 간판 사진 수동 GT입니다. |

주요 aggregate는 GT가 있는 784개 샘플입니다. Raw Vision, 전처리만, 후처리만, 전처리+후처리를 비교합니다. 최종 주장은 결과를 보고 분기를 고른 것이 아니라, 항상 호출되는 `HangulGuidedOCR(auto)` 모드 기준입니다.

Apple Vision OCR은 closed-source API이므로 Tesseract, EasyOCR, PaddleOCR을
추가 공개 OCR 비교군으로 실행했습니다. Tesseract와 EasyOCR은 공개 가능
subset 전체에 대해 실행했고, PaddleOCR은 macOS arm64 CPU 실행 시간이 커서
runtime-bounded subset에 한해 실행했습니다. 이 비교의 목적은 본 기여가
Apple Vision 내부 모델 수정이 아니라, OCR 엔진 앞뒤에서 text region과
ordered-point representation을 구조화하는 보정 전략임을 보이는 것입니다.

Canva/MiriCanvas 원본 템플릿 이미지는 재배포하지 않습니다. 공개 레포에는 요약 metric, protocol note, figure, 최종 보고서만 포함합니다.
