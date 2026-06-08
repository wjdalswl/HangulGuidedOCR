# 실험/버그 기록 / Experiment or Bug Log

## 목적 / Goal

<!-- 어떤 OCR 실패 유형을 개선하려는지 적어주세요. -->
<!-- Describe which OCR failure pattern this issue targets. -->

## 입력 이미지 유형 / Image Type

- [ ] 지하철 세로 역명판 / Subway vertical station label
- [ ] 세로 안내문 / Vertical notice
- [ ] 분산 타이포그래피 / Dispersed typography
- [ ] 간판 / Signboard
- [ ] 기타 / Other

## Raw Vision OCR 결과

```text

```

## 기대 결과 / Expected Guided Text

```text

```

## 적용한 설정 / Configuration

- imageTransforms:
- readingStrategy: automatic / rawVisionOrder / horizontalLines / verticalColumnsLeftToRight / verticalColumnsRightToLeft / topToBottomRows
- resolvedStrategy:
- expectedOrder:
- enablesFuzzyCorrection:

## DeepSolo-guided 연결 / DeepSolo-guided Connection

- 어떤 boundary/ordered-points/reading-order 관점이 적용되었나요?
- Which boundary, ordered-points, or reading-order idea is applied?
- raw Vision order를 보존해야 하나요, 아니면 재정렬해야 하나요?
- Should the library preserve raw Vision order or reorder observations?

## 결과 / Result

- rawText:
- guidedText:
- auto decision:
  - [ ] raw Vision order preserved
  - [ ] reordered vertical/multi-column/dispersed layout
- 개선 여부:
- CER/WER or qualitative result:

## 한계 / Limitation

<!-- 실패 원인이나 추가로 필요한 detector/ROI/annotation을 적어주세요. -->
<!-- Note remaining detector, ROI, layout, or annotation needs. -->
