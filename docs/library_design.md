# HangulGuidedOCR Library Design

## 한국어 요약

`HangulGuidedOCR`은 Apple Vision OCR의 raw 결과를 한국어 실제 이미지에 맞게 보정하기 위한 Swift Package이다. DeepSolo의 ordered points, boundary, reading order 관점을 앱 레이어 API로 옮겼다. Vision이 반환하는 bbox는 최종 표현이 아니라 `HangulPointProxyBuilder`가 `(P_i, y_i, s_i)` proxy를 만들기 위한 관측값으로 사용된다. 또한 Vision이 글자를 아예 검출하지 못하는 장식적 세로 제목은 `HangulSpottingProposal`로 OCR 전 ordered spot을 지정할 수 있다. 기본 동작은 `automatic`이며, 일반 가로형 포스터에서는 raw Vision 순서를 보존하고 세로쓰기·다열·분산 타이포그래피에서만 재정렬을 적용한다.

## English Summary

`HangulGuidedOCR` is a Swift Package for guiding Apple Vision OCR on Korean scene-text images. It converts Vision observations into DeepSolo-style ordered point proxies, accepts pre-OCR spotting proposals, and translates boundaries, repeated-point decoding, and reading-order priors into reusable iOS/macOS APIs.

## Design Mapping

| DeepSolo idea | Library API | Purpose |
|---|---|---|
| text boundary | `cropNormalized` | limit OCR to a text instance or ROI |
| direction prior | `rotate90Clockwise`, `rotate90CounterClockwise` | make vertical signs readable by Vision OCR |
| ordered points | `HangulPointProxyBuilder` | convert each Vision observation into 25 ordered center points |
| spotting query/proposal | `HangulSpottingProposal` | describe text candidates before OCR with ordered points and boundary |
| point-query prior | `HangulReadingStrategy.automatic` | preserve raw order or reorder point proxies by Korean reading order |
| recognition score | `HangulTextObservation.confidence` | preserve Vision confidence |
| CTC-like repeat decoding | `HangulOrderedSequenceDecoder.collapseRepeatedPointCharacters` | collapse repeated point predictions such as `광광광복절` to `광복절` |
| duplicate suppression | `HangulOrderedSequenceDecoder.deduplicateOverlappingObservations` | keep the highest-confidence text when overlapping points predict the same character |
| vocabulary prior | `expectedOrder` | reconstruct known station names or poster phrases |

## Point Pipeline

```text
image
  -> optional HangulSpottingProposal(P_i, boundary, score)
  -> crop / rotate / upscale / contrast
  -> VNRecognizeTextRequest
  -> HangulPointProxy(P_i, y_i, s_i)
  -> duplicate suppression
  -> repeated-point collapse
  -> reading-order resolver
  -> expectedOrder correction
```

이 흐름에서 `bbox`는 최종 목표가 아니라 boundary polygon과 ordered point를 만들기 위한 관측값이다. 최종 API는 앱 개발자가 text instance를 점의 순서와 경계로 다룰 수 있게 하는 것을 목표로 한다.

## Target Scenarios

| Scenario | Raw Vision issue | Guided strategy |
|---|---|---|
| Subway vertical station label | detects partial Korean or unstable station order | crop red sign, rotate, point proxy, expected station order |
| Dispersed typography poster | detects only large isolated characters | crop typography area, top-to-bottom rows, expected phrase |
| Stylized vertical title | misses the main title entirely | pre-OCR spotting proposal, crop/rotate, repeated-point collapse |
| General horizontal notice | raw Vision is often already correct | automatic keeps raw order |

## Verification

Run:

```bash
swift test
```

Expected:

- `testAutomaticKeepsRawOrderForOrdinaryHorizontalPoster`
- `testAutomaticVerticalStationTermsUseExpectedStationOrder`
- `testVerticalStationTermsCanBeReconstructedByExpectedOrder`
- `testBuildsDeepSoloStylePointProxyFromVisionObservation`
- `testBuildsPreOCRSpottingProposalFromOrderedPoints`
- `testCollapsesRepeatedPointCharactersLikeCTCDecoding`
- `testSuppressesOverlappingDuplicatePointPredictions`
- `testAutomaticTypographyWallFuzzyCorrection`
- `testTypographyWallFuzzyCorrection`
