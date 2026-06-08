# PR 요약 / Summary

## 변경 내용 / Changes

- 

## 왜 필요한가 / Why

<!-- 한국어 OCR 읽기순서, ROI, 전처리, 후처리 개선 관점에서 설명해주세요. -->
<!-- Explain the change in terms of Korean OCR reading order, ROI, preprocessing, or postprocessing. -->

## 구현 방식 / Implementation Details

- 선택한 API 또는 알고리즘:
- Selected API or algorithm:
- DeepSolo ordered-points/boundary/reading-order 관점과의 연결:
- Connection to DeepSolo ordered points, boundary, or reading order:
- 일반 가로형에서 raw Vision order를 보존하는지:
- Whether ordinary horizontal layouts preserve raw Vision order:
- 세로/다열/분산형에서 어떤 조건으로 재정렬하는지:
- Reordering condition for vertical, multi-column, or dispersed layouts:

## 검증 / Verification

- [ ] `swift test`
- [ ] 기본 `.automatic` 전략이 일반 가로형에서 raw Vision order를 보존
- [ ] Default `.automatic` strategy preserves raw Vision order on ordinary horizontal layouts
- [ ] 지하철 역명판 시나리오 확인
- [ ] 분산 타이포그래피 시나리오 확인
- [ ] `resolvedStrategy` 또는 equivalent behavior 확인
- [ ] README 사용 예시와 일치
- [ ] Korean and English documentation/examples updated if user-facing API changed
- [ ] 사용자-facing API 변경 시 한글/영문 문서와 예시가 함께 업데이트됨

## 한계 / Limitations

<!-- 남은 문제와 향후 작업을 적어주세요. -->
<!-- Describe remaining limitations and follow-up work. -->
