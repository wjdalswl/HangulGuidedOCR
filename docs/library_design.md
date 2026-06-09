# Library Design

## English

HangulGuidedOCR is designed as a conservative correction layer over Apple Vision OCR.

### Principles

1. Preserve raw Vision order when the evidence looks like a normal horizontal text layout.
2. Convert Vision observations into ordered point proxies before applying Korean reading-order correction.
3. Keep preprocessing and postprocessing separable so experiments can measure `raw`, `preprocess-only`, `postprocess-only`, and `auto`.
4. Expose expected terms and expected order as optional app-level priors, not mandatory hard-coded vocabulary.
5. Avoid shipping private benchmark images in the Swift package repository.

### Main Components

| Component | Role |
|---|---|
| `HangulPointProxyBuilder` | Converts Vision-style boxes into ordered point sequences. |
| `HangulReadingOrderResolver` | Classifies layout evidence and chooses a reading-order strategy. |
| `HangulOrderedSequenceDecoder` | Reconstructs text order and suppresses near-duplicate tokens. |
| `HangulLexiconCorrector` | Applies optional Korean term and expected-order priors. |
| `HangulImagePreprocessor` | Provides deterministic crop/rotate/upscale metadata paths for app integration. |

## Korean

HangulGuidedOCR는 Apple Vision OCR 위에서 보수적으로 동작하는 보정 계층으로 설계되었습니다.

### 설계 원칙

1. 일반 가로형 텍스트 레이아웃으로 판단되면 raw Vision 순서를 유지합니다.
2. 한국어 읽기 순서 보정 전에 Vision 관측값을 ordered point proxy로 변환합니다.
3. 실험에서 `raw`, `preprocess-only`, `postprocess-only`, `auto`를 분리 측정할 수 있도록 전처리와 후처리를 분리합니다.
4. Expected terms와 expected order는 하드코딩된 어휘가 아니라 앱 레벨에서 선택적으로 주입하는 prior로 둡니다.
5. Swift package 공개 레포에는 비공개 benchmark 원본 이미지를 포함하지 않습니다.

### 주요 컴포넌트

| 컴포넌트 | 역할 |
|---|---|
| `HangulPointProxyBuilder` | Vision 스타일 bbox를 ordered point sequence로 변환합니다. |
| `HangulReadingOrderResolver` | 레이아웃 근거를 분류하고 읽기 순서 전략을 선택합니다. |
| `HangulOrderedSequenceDecoder` | 텍스트 순서를 재구성하고 near-duplicate token을 억제합니다. |
| `HangulLexiconCorrector` | 선택적인 한국어 term과 expected-order prior를 적용합니다. |
| `HangulImagePreprocessor` | 앱 연동을 위한 결정론적 crop/rotate/upscale metadata 경로를 제공합니다. |
