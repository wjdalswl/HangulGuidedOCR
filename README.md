# HangulGuidedOCR

한국어 세로쓰기, 다열 안내문, 지하철 역명판, 분산 타이포그래피 이미지에서 Apple Vision OCR의 읽기순서 오류를 줄이기 위한 Swift Package 라이브러리입니다.

HangulGuidedOCR is a Swift Package that wraps Apple Vision OCR and adds Korean-oriented preprocessing and postprocessing for vertical text, multi-column signs, subway station labels, and dispersed typography posters.

## 연구 배경 / Research Motivation

Apple Vision OCR은 iOS/macOS 앱에서 바로 사용할 수 있는 강력한 OCR 엔진이지만, 한국어 실제 사진에서는 다음 문제가 자주 발생합니다.

- 세로쓰기에서 어떤 열부터 읽어야 하는지 틀림
- 지하철 역명판처럼 한글과 영어가 섞인 세로 안내문에서 한글 역명을 부분적으로만 복원함
- 포스터형 분산 타이포그래피에서 큰 글자 일부만 검출하고 문장 순서를 놓침
- Vision OCR raw 결과는 bbox를 반환하지만 앱 개발자가 이를 DeepSolo식 ordered point sequence로 변환해 한국어 읽기 순서에 활용하기 어렵다

This library is inspired by DeepSolo's ordered points and boundary representation. It does not train a new OCR model. Instead, it converts Apple Vision OCR observations into `(P_i, y_i, s_i)`-style point proxies, accepts pre-OCR spotting proposals, and helps app developers guide Apple Vision OCR with ROI boundaries, rotation, scaling, contrast, reading-order strategies, repeated-point decoding, overlap suppression, and expected vocabulary correction.

기본값은 `HangulReadingStrategy.automatic`입니다. 앱 개발자는 일반 포스터에서도 `HangulGuidedOCR`을 계속 호출하고, 라이브러리 내부 auto strategy가 raw Vision 순서가 이미 좋은 경우에는 재정렬을 생략합니다. 세로쓰기·다열 안내문·분산 타이포그래피처럼 reading-order 보정이 필요한 layout에서만 자동 또는 명시 전략으로 component를 다시 조립합니다.

## DeepSolo식 점 처리 반영 / DeepSolo-inspired Point Handling

| DeepSolo 관점 | HangulGuidedOCR 반영 |
|---|---|
| ordered center points | `HangulPointProxyBuilder`가 Vision observation마다 25개 중심선 point를 생성 |
| text boundary points | observation/proposal boundary를 `HangulOrderedPoint` polygon으로 보존 |
| point proposal before recognition | `HangulSpottingProposal`로 OCR 전 ROI와 ordered spot을 지정 |
| score | `HangulTextObservation.confidence`와 proposal confidence 유지 |
| repeated point decoding | `HangulOrderedSequenceDecoder`가 `광광광복절` 같은 반복 음절을 `광복절`로 collapse |
| duplicate point suppression | 겹치는 같은 글자 관측값은 confidence가 높은 하나만 유지 |
| query/lexicon prior | `expectedOrder`로 역명, 포스터 문구 같은 앱 도메인 어휘를 재조립 |

즉 이 라이브러리는 official DeepSolo detector/recognizer를 그대로 옮긴 것이 아니라, Apple Vision OCR 위에서 재사용 가능한 **ordered point representation + spotting proposal + sequence decoding** 계층을 구현합니다.

## 설치 / Installation

Xcode에서:

1. `File > Add Package Dependencies...`
2. GitHub URL 입력:

```text
https://github.com/wjdalswl/HangulGuidedOCR.git
```

Swift Package Manager:

```swift
.package(url: "https://github.com/wjdalswl/HangulGuidedOCR.git", branch: "main")
```

## 사용 예시 / Usage

### 지하철 세로 역명판

세로로 적힌 한국어 역명판에서 영어 병기 위→아래 순서와 같은 역명 순서로 `동대문역사 문화공원`을 얻는 예시입니다.

```swift
import HangulGuidedOCR

let ocr = HangulGuidedOCR()

let result = try ocr.recognize(
    cgImage,
    configuration: HangulOCRConfiguration(
        recognitionLevel: .accurate,
        imageTransforms: [
            .cropNormalized(CGRect(x: 0.35, y: 0.20, width: 0.22, height: 0.58)),
            .rotate90Clockwise,
            .upscale(2.0),
            .contrast(1.4),
        ],
        readingGuide: HangulReadingGuide(
            strategy: .verticalColumnsLeftToRight,
            expectedOrder: ["동대문역사", "문화공원"]
        )
    )
)

print(result.rawText)
print(result.guidedText) // 동대문역사 문화공원
print(result.resolvedStrategy) // verticalColumnsLeftToRight
print(result.pointProxies.first?.orderedPoints.count) // 25
```

### 분산 타이포그래피 포스터

`user_typography_wall`처럼 위에서 아래로 읽어야 하는 포스터에서 `예쁜 그림을 그리고 싶다`를 얻는 예시입니다.

```swift
let result = try ocr.recognize(
    cgImage,
    configuration: HangulOCRConfiguration(
        recognitionLevel: .accurate,
        imageTransforms: [
            .cropNormalized(CGRect(x: 0.25, y: 0.20, width: 0.45, height: 0.42)),
            .upscale(3.0),
            .contrast(1.8),
        ],
        readingGuide: HangulReadingGuide(
            strategy: .topToBottomRows,
            expectedOrder: ["예쁜", "그림을", "그리고", "싶다"]
        )
    )
)

print(result.guidedText) // 예쁜 그림을 그리고 싶다
```

### OCR 전 ordered spot proposal

장식적 세로 제목처럼 Vision OCR이 원본에서 글자를 아예 검출하지 못하는 경우에는, OCR 전에 텍스트 후보 영역을 ordered point proposal로 지정할 수 있습니다.

```swift
let proposal = HangulSpottingProposal.fromNormalizedRect(
    CGRect(x: 0.42, y: 0.25, width: 0.18, height: 0.50),
    direction: .verticalTopToBottom,
    expectedText: "광복절",
    sampleCount: 25,
    normalizationPadding: 0.03,
    rotation: .clockwise90
)

let result = try ocr.recognize(
    cgImage,
    proposal: proposal,
    configuration: HangulOCRConfiguration(
        recognitionLevel: .accurate,
        imageTransforms: [
            .upscale(2.0),
            .contrast(1.5),
        ]
    )
)

print(result.guidedText) // 광복절
```

### 일반 가로 포스터

일반 가로 포스터나 카드뉴스에서는 별도 strategy를 지정하지 않습니다. `automatic`이 raw Vision 순서를 보존하므로, HangulGuidedOCR를 항상 사용해도 불필요한 point 재정렬로 CER가 악화되지 않도록 설계했습니다.

```swift
let result = try ocr.recognize(cgImage)

print(result.guidedText)       // raw Vision order preserved
print(result.resolvedStrategy) // rawVisionOrder
```

## 제공 기능 / Features

| 기능 | 설명 |
|---|---|
| Vision OCR wrapper | Apple Vision `VNRecognizeTextRequest` 실행 |
| ROI crop | normalized CGRect 기반 OCR 대상 영역 제한 |
| rotation | 90도 시계/반시계 방향 회전 |
| upscale | 작은 글자 인식을 위한 확대 |
| contrast | 저대비 글자 보정 |
| point proxy | Vision observation을 25개 ordered center points와 boundary points로 변환 |
| spotting proposal | OCR 전에 ordered points와 boundary로 ROI를 지정 |
| repeated point collapse | `광광광복절`처럼 point sequence에서 반복된 음절을 collapse |
| overlap suppression | 같은 글자가 겹쳐 여러 번 검출된 경우 confidence가 높은 관측값만 유지 |
| reading order | automatic, raw Vision order, horizontal, vertical left-to-right, vertical right-to-left, top-to-bottom |
| expectedOrder correction | 앱 도메인 단어 목록 기반 재정렬 및 fuzzy correction |

## API 구성 / API Overview

```text
Sources/HangulGuidedOCR/
├── HangulGuidedOCR.swift
├── HangulOCRModels.swift
├── HangulImagePreprocessor.swift
├── HangulPointProxyBuilder.swift
├── HangulSpottingProposal.swift
├── HangulOrderedSequenceDecoder.swift
├── HangulReadingOrderResolver.swift
└── HangulLexiconCorrector.swift
```

## 테스트 / Tests

```bash
swift test
```

현재 테스트는 다음 시나리오를 확인합니다.

- 일반 가로 포스터: 기본 `automatic`이 `rawVisionOrder`로 판단해 raw 순서를 보존
- image transform: ROI crop, 90도 회전, upscale, contrast가 CGImage에 적용됨
- 지하철 세로 역명판: 기본 `automatic`이 point proxy와 expected order를 이용해 `동대문역사 문화공원`으로 재조립
- 전통 세로쓰기: `verticalColumnsRightToLeft`가 오른쪽 열부터 위→아래로 정렬
- 분산 타이포그래피: 기본 `automatic`이 `topToBottomRows`로 판단해 `예쁜 그림을 그리고 싶다`로 보정
- Vision observation에서 DeepSolo-style `(P_i, y_i, s_i)` ordered point proxy 생성
- OCR 전 `HangulSpottingProposal`이 normalized rect를 25개 ordered point와 boundary로 변환
- DeepSolo/CTC식 반복 point decoding으로 `광광광복절`을 `광복절`로 collapse
- 겹치는 중복 point prediction에서 confidence가 높은 글자만 유지
- 지하철 세로 역명판: `동대문역사`, `문화공원` raw component를 `동대문역사 문화공원`으로 재조립
- 분산 타이포그래피: `예는 그림을 그리고 싶다` raw 결과를 `예쁜 그림을 그리고 싶다`로 보정

## 연구 repo / Research Repository

실험 과정, DeepSolo 재현 기록, Apple Vision OCR 비교 결과, 최종보고서는 별도 연구 repo에 정리되어 있습니다.

```text
https://github.com/wjdalswl/textspotting-guided-vision-ocr
```

## 한계 / Limitations

- 이 라이브러리는 Apple Vision OCR을 대체하지 않습니다.
- 완전 자동 text spotting detector를 학습하지는 않지만, 앱 개발자나 외부 detector가 만든 `HangulSpottingProposal`을 받아 OCR 전 ordered spot 보정을 수행할 수 있습니다.
- 복잡한 실제 이미지에서는 샘플 유형별 ROI 탐색 또는 별도 text detector가 필요할 수 있습니다.

## License

MIT License.

이미지 샘플, 연구용 benchmark, 최종보고서, DeepSolo 재현 기록은 companion research repo인 `textspotting-guided-vision-ocr`에서 관리합니다. 이 repo는 앱 개발자가 import해서 사용할 수 있는 Swift Package 코드와 API 문서를 중심으로 둡니다.

Image samples, research benchmarks, final reports, and DeepSolo reproduction logs are maintained in the companion `textspotting-guided-vision-ocr` repository. This repository focuses on the Swift Package implementation and developer-facing API documentation.
