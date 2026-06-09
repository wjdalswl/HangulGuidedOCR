# Usage Guide

This guide explains where HangulGuidedOCR fits in an iOS/macOS app that already uses Apple Vision OCR. The library is not a replacement OCR engine. It is a Korean reading-order and layout correction layer that runs before and after Vision OCR.

## When to Use

Use HangulGuidedOCR when your app needs to read:

- Korean subway or venue signs with vertical station/place names.
- Poster titles arranged top-to-bottom or as separated typography components.
- Stylized Korean titles where Vision detects partial or repeated characters.
- Mixed Korean/English layouts where the Korean reading order is clearer than Vision's raw observation order.

You usually do not need a forced reorder for ordinary horizontal posters, receipts, menus, or paragraphs. In those cases, keep `strategy: .automatic`; the library should preserve Vision's raw order.

## Installation

Add the repository as a Swift Package in Xcode:

```text
https://github.com/wjdalswl/HangulGuidedOCR.git
```

Or add it to `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/wjdalswl/HangulGuidedOCR.git", branch: "main")
]
```

Then import the module:

```swift
import HangulGuidedOCR
```

## API Overview

The main types are:

| Type | Purpose |
|---|---|
| `HangulGuidedOCR` | Runs Vision OCR with optional preprocessing and ordered spot proposals. |
| `HangulOCRConfiguration` | Sets recognition level, language, image transforms, and reading guide. |
| `HangulReadingGuide` | Controls automatic/raw/manual reading strategy, expected terms, and duplicate collapse. |
| `HangulTextObservation` | A normalized OCR observation: text, confidence, and bounding box. |
| `HangulReadingOrderResolver` | Postprocesses existing Vision observations without rerunning OCR. |
| `HangulSpottingProposal` | Builds a pre-OCR ROI from ordered points when text is not detected reliably. |

## Recommended App Flow

1. Start with `strategy: .automatic`.
2. If the app has a clear ROI, pass `.cropNormalized(...)` in `imageTransforms`.
3. If the layout is physically vertical and needs side rotation, add `.rotate90Clockwise` or `.rotate90CounterClockwise`.
4. If the app has reliable domain terms, pass them through `expectedOrder`.
5. Compare `rawText`, `guidedText`, and `resolvedStrategy` during development.
6. In production, display or store `guidedText`, while logging `resolvedStrategy` for debugging.

## Full OCR Example

Use this when HangulGuidedOCR should run Vision OCR itself.

```swift
import CoreGraphics
import HangulGuidedOCR

func readStationSign(from cgImage: CGImage) throws -> String {
    let configuration = HangulOCRConfiguration(
        recognitionLevel: .accurate,
        recognitionLanguages: ["ko-KR", "en-US"],
        usesLanguageCorrection: true,
        imageTransforms: [
            .cropNormalized(CGRect(x: 0.32, y: 0.10, width: 0.36, height: 0.78)),
            .rotate90Clockwise
        ],
        readingGuide: HangulReadingGuide(
            strategy: .automatic,
            expectedOrder: ["동대문역사", "문화공원"]
        )
    )

    let result = try HangulGuidedOCR().recognize(
        cgImage,
        configuration: configuration
    )

    print("raw:", result.rawText)
    print("guided:", result.guidedText)
    print("strategy:", result.resolvedStrategy)

    return result.guidedText
}
```

## Postprocess Existing Apple Vision Results

Use this when your app already has `VNRecognizedTextObservation` results and you only want reading-order correction.

```swift
import CoreGraphics
import Vision
import HangulGuidedOCR

func postprocessVisionResults(
    _ visionResults: [VNRecognizedTextObservation]
) -> String {
    let observations = visionResults.compactMap { observation -> HangulTextObservation? in
        guard let candidate = observation.topCandidates(1).first else {
            return nil
        }

        return HangulTextObservation(
            text: candidate.string,
            confidence: candidate.confidence,
            boundingBox: observation.boundingBox
        )
    }

    let resolved = HangulReadingOrderResolver.resolveWithStrategy(
        observations: observations,
        guide: HangulReadingGuide(
            strategy: .automatic,
            expectedOrder: ["예쁜", "그림을", "그리고", "싶다"]
        )
    )

    print("strategy:", resolved.resolvedStrategy)
    return resolved.text
}
```

## Pre-OCR Ordered Spot Proposal

Use this when Vision misses a stylized title, such as a vertical holiday title or a poster headline. The proposal creates a crop/rotation path before Vision OCR and passes the expected term as a soft reading prior.

```swift
import CoreGraphics
import HangulGuidedOCR

func readVerticalTitle(from cgImage: CGImage) throws -> String {
    let proposal = HangulSpottingProposal.fromNormalizedRect(
        CGRect(x: 0.42, y: 0.25, width: 0.18, height: 0.50),
        direction: .verticalTopToBottom,
        expectedText: "광복절",
        sampleCount: 25,
        normalizationPadding: 0.03,
        rotation: .clockwise90
    )

    let result = try HangulGuidedOCR().recognize(
        cgImage,
        proposal: proposal,
        configuration: HangulOCRConfiguration(
            recognitionLevel: .accurate,
            recognitionLanguages: ["ko-KR", "en-US"],
            readingGuide: HangulReadingGuide(strategy: .automatic)
        )
    )

    return result.guidedText
}
```

## Strategies

| Strategy | Use case |
|---|---|
| `.automatic` | Default for apps. Preserves raw Vision order unless layout evidence supports reordering. |
| `.rawVisionOrder` | Keep Vision output untouched except duplicate-character collapse. |
| `.horizontalLines` | Sort same-row text left-to-right. |
| `.verticalColumnsLeftToRight` | Korean station/sign columns that should read from the left column to the right column. |
| `.verticalColumnsRightToLeft` | Traditional vertical writing or layouts that should read from the right column to the left column. |
| `.topToBottomRows` | Poster titles arranged as separated rows from top to bottom. |

## Coordinate Notes

All bounding boxes use Vision-style normalized coordinates in the unit image rectangle. `CGRect(x: 0, y: 0, width: 1, height: 1)` covers the whole image.

## Output Fields

| Field | Meaning |
|---|---|
| `rawText` | Vision's raw recognized text order after any image transforms. |
| `guidedText` | HangulGuidedOCR's corrected output. |
| `observations` | Text, confidence, and bounding boxes from Vision. |
| `pointProxies` | DeepSolo-style sampled center-line and boundary points. |
| `resolvedStrategy` | The strategy used after automatic inference. |
| `durationMilliseconds` | Vision OCR runtime inside the package call. |

## Practical Advice

- Keep `.automatic` as the default path in production.
- Add `expectedOrder` only when the app has reliable context. Too many speculative terms can overcorrect.
- For very stylized titles, create a small `HangulSpottingProposal` instead of running OCR over the whole poster.
- Log `rawText` and `guidedText` during QA. The difference is often the clearest way to find harmful reordering.
- If a character is not visible or the crop is too blurry, this library cannot recover it without a better ROI or detector.

---

# 사용 가이드

이 문서는 Apple Vision OCR을 이미 쓰는 iOS/macOS 앱 안에서 HangulGuidedOCR를 어디에 붙여야 하는지 설명합니다. 이 라이브러리는 새 OCR 엔진이 아니라, Vision OCR 앞뒤에서 동작하는 한국어 읽기 순서 및 레이아웃 보정 레이어입니다.

## 언제 사용하나요?

다음과 같은 입력을 읽어야 할 때 사용합니다.

- 한국어 지하철/장소 간판처럼 역명이나 장소명이 세로로 배치된 경우
- 포스터 제목이 위에서 아래로 배치되거나 분산된 타이포그래피 컴포넌트로 나뉜 경우
- Vision이 장식형 한국어 제목을 일부만 검출하거나 같은 글자를 반복 검출하는 경우
- 한국어와 영어가 섞인 레이아웃에서 Vision의 raw observation 순서보다 한국어 독자 기준의 순서가 더 명확한 경우

일반적인 가로 포스터, 영수증, 메뉴, 문단에는 강제 재정렬이 필요하지 않은 경우가 많습니다. 이때는 `strategy: .automatic`을 유지하면 라이브러리가 Vision raw 순서를 보존합니다.

## 설치

Xcode에서 아래 저장소를 Swift Package로 추가합니다.

```text
https://github.com/wjdalswl/HangulGuidedOCR.git
```

또는 `Package.swift`에 추가합니다.

```swift
dependencies: [
    .package(url: "https://github.com/wjdalswl/HangulGuidedOCR.git", branch: "main")
]
```

그다음 모듈을 import합니다.

```swift
import HangulGuidedOCR
```

## API 개요

주요 타입은 다음과 같습니다.

| 타입 | 역할 |
|---|---|
| `HangulGuidedOCR` | 전처리와 ordered spot proposal을 포함해 Vision OCR을 실행합니다. |
| `HangulOCRConfiguration` | recognition level, 언어, 이미지 변환, reading guide를 설정합니다. |
| `HangulReadingGuide` | 자동/raw/manual 읽기 전략, 기대 단어, 중복 collapse를 제어합니다. |
| `HangulTextObservation` | 정규화된 OCR 관측값입니다. text, confidence, bbox를 담습니다. |
| `HangulReadingOrderResolver` | OCR을 다시 돌리지 않고 기존 Vision 관측값을 후처리합니다. |
| `HangulSpottingProposal` | 텍스트 검출이 불안정할 때 ordered points 기반 pre-OCR ROI를 만듭니다. |

## 권장 앱 흐름

1. 먼저 `strategy: .automatic`으로 시작합니다.
2. 앱이 명확한 ROI를 알고 있다면 `imageTransforms`에 `.cropNormalized(...)`를 넣습니다.
3. 실제 레이아웃이 세로이고 옆으로 돌려 읽어야 한다면 `.rotate90Clockwise` 또는 `.rotate90CounterClockwise`를 추가합니다.
4. 앱이 신뢰할 수 있는 도메인 단어를 알고 있다면 `expectedOrder`로 전달합니다.
5. 개발 중에는 `rawText`, `guidedText`, `resolvedStrategy`를 함께 비교합니다.
6. 배포 시에는 `guidedText`를 사용하되, 디버깅을 위해 `resolvedStrategy`를 로그로 남기는 것이 좋습니다.

## 전체 OCR 예시

HangulGuidedOCR가 Vision OCR 실행까지 담당해야 할 때 사용합니다.

```swift
import CoreGraphics
import HangulGuidedOCR

func readStationSign(from cgImage: CGImage) throws -> String {
    let configuration = HangulOCRConfiguration(
        recognitionLevel: .accurate,
        recognitionLanguages: ["ko-KR", "en-US"],
        usesLanguageCorrection: true,
        imageTransforms: [
            .cropNormalized(CGRect(x: 0.32, y: 0.10, width: 0.36, height: 0.78)),
            .rotate90Clockwise
        ],
        readingGuide: HangulReadingGuide(
            strategy: .automatic,
            expectedOrder: ["동대문역사", "문화공원"]
        )
    )

    let result = try HangulGuidedOCR().recognize(
        cgImage,
        configuration: configuration
    )

    print("raw:", result.rawText)
    print("guided:", result.guidedText)
    print("strategy:", result.resolvedStrategy)

    return result.guidedText
}
```

## 기존 Apple Vision 결과 후처리

앱이 이미 `VNRecognizedTextObservation`을 가지고 있고 읽기 순서만 보정하고 싶을 때 사용합니다.

```swift
import CoreGraphics
import Vision
import HangulGuidedOCR

func postprocessVisionResults(
    _ visionResults: [VNRecognizedTextObservation]
) -> String {
    let observations = visionResults.compactMap { observation -> HangulTextObservation? in
        guard let candidate = observation.topCandidates(1).first else {
            return nil
        }

        return HangulTextObservation(
            text: candidate.string,
            confidence: candidate.confidence,
            boundingBox: observation.boundingBox
        )
    }

    let resolved = HangulReadingOrderResolver.resolveWithStrategy(
        observations: observations,
        guide: HangulReadingGuide(
            strategy: .automatic,
            expectedOrder: ["예쁜", "그림을", "그리고", "싶다"]
        )
    )

    print("strategy:", resolved.resolvedStrategy)
    return resolved.text
}
```

## OCR 전 ordered spot proposal

세로 기념일 제목이나 포스터 헤드라인처럼 Vision이 장식형 제목을 놓치는 경우에 사용합니다. Proposal은 Vision OCR 전에 crop/rotation 경로를 만들고, 기대 단어를 soft reading prior로 전달합니다.

```swift
import CoreGraphics
import HangulGuidedOCR

func readVerticalTitle(from cgImage: CGImage) throws -> String {
    let proposal = HangulSpottingProposal.fromNormalizedRect(
        CGRect(x: 0.42, y: 0.25, width: 0.18, height: 0.50),
        direction: .verticalTopToBottom,
        expectedText: "광복절",
        sampleCount: 25,
        normalizationPadding: 0.03,
        rotation: .clockwise90
    )

    let result = try HangulGuidedOCR().recognize(
        cgImage,
        proposal: proposal,
        configuration: HangulOCRConfiguration(
            recognitionLevel: .accurate,
            recognitionLanguages: ["ko-KR", "en-US"],
            readingGuide: HangulReadingGuide(strategy: .automatic)
        )
    )

    return result.guidedText
}
```

## Strategy 선택

| Strategy | 사용 상황 |
|---|---|
| `.automatic` | 앱 기본값입니다. 레이아웃 근거가 충분할 때만 재정렬하고, 그렇지 않으면 Vision raw 순서를 유지합니다. |
| `.rawVisionOrder` | 중복 글자 collapse 외에는 Vision 출력을 유지합니다. |
| `.horizontalLines` | 같은 행의 텍스트를 왼쪽에서 오른쪽으로 정렬합니다. |
| `.verticalColumnsLeftToRight` | 한국어 역명/간판처럼 왼쪽 열에서 오른쪽 열 순서로 읽어야 할 때 사용합니다. |
| `.verticalColumnsRightToLeft` | 전통 세로쓰기나 오른쪽 열에서 왼쪽 열 순서로 읽어야 하는 레이아웃에 사용합니다. |
| `.topToBottomRows` | 포스터 제목이 분리된 행으로 위에서 아래로 배치된 경우 사용합니다. |

## 좌표 기준

모든 bbox는 Vision 방식의 normalized coordinate를 사용합니다. `CGRect(x: 0, y: 0, width: 1, height: 1)`은 전체 이미지를 의미합니다.

## 출력 필드

| 필드 | 의미 |
|---|---|
| `rawText` | 이미지 변환 이후 Vision이 반환한 원본 텍스트 순서입니다. |
| `guidedText` | HangulGuidedOCR가 보정한 최종 출력입니다. |
| `observations` | Vision에서 온 text, confidence, bbox입니다. |
| `pointProxies` | DeepSolo식 center-line/boundary sampled points입니다. |
| `resolvedStrategy` | automatic inference 이후 실제 사용된 전략입니다. |
| `durationMilliseconds` | 패키지 호출 내부에서 Vision OCR에 걸린 시간입니다. |

## 실무 팁

- 배포 기본값은 `.automatic`으로 두는 것이 좋습니다.
- `expectedOrder`는 앱이 확실한 문맥을 알고 있을 때만 추가합니다. 추측성 단어가 많으면 과보정될 수 있습니다.
- 매우 장식적인 제목은 전체 포스터에 OCR을 돌리기보다 작은 `HangulSpottingProposal`을 먼저 만드는 것이 좋습니다.
- QA 중에는 `rawText`와 `guidedText`를 함께 기록하세요. 두 값의 차이가 harmful reorder를 찾는 가장 빠른 단서가 됩니다.
- 글자가 보이지 않거나 crop이 너무 흐리면 더 좋은 ROI 또는 detector 없이는 복구할 수 없습니다.
