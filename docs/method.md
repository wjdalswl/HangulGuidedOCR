# Method

This document describes the method behind HangulGuidedOCR. The text is written in English first, followed by Korean.

## English

### 1. Observation Model

Apple Vision OCR returns observations as normalized bounding boxes, recognized strings, and confidence values:

```text
o_i = (b_i, y_i, s_i)
b_i = (x_i, y_i, w_i, h_i)
```

HangulGuidedOCR treats these observations as a lightweight proxy for the DeepSolo output representation:

```text
I -> {(P_i, y_i, s_i)}
```

where `P_i` is an ordered point sequence, `y_i` is the recognized text, and `s_i` is the confidence score.

### 2. Bounding Box to Ordered Points

For each observation box, the method samples 25 center-line points:

```text
c_left  = (x_i, y_i + h_i / 2)
c_right = (x_i + w_i, y_i + h_i / 2)
p_k = c_left + (k / 24) * (c_right - c_left), k in [0, 24]
P_i = {p_0, ..., p_24}
```

For vertical crops that are rotated before OCR, the inverse transform maps the points back into the original image coordinate space. This keeps the representation compatible with DeepSolo's ordered center/boundary view while remaining lightweight enough for Swift app use.

### 3. Auto Reading-Order Strategy

The auto strategy estimates whether correction is necessary:

```text
if horizontal_line_evidence is strong:
    keep raw Vision order
elif vertical_column_evidence is strong:
    sort columns by Korean layout policy
elif dispersed_component_evidence is strong:
    group components into rows or title strips
else:
    preserve raw order and expose evidence
```

The strategy is deliberately conservative. A normal horizontal poster should not be harmed by forced reordering. Vertical signs, subway station labels, and dispersed typography are corrected only when the point and box geometry provides evidence that raw Vision order is unreliable.

### 4. Pre-OCR Spot Proposal

Some stylized Korean titles are not detected as text by Apple Vision. For these cases, HangulGuidedOCR supports a pre-OCR proposal stage:

```text
candidate_regions = propose_spots(image, layout_hint)
for region in candidate_regions:
    strip = unwrap(region, ordered_points)
    text = VisionOCR(strip)
    text = suppress_duplicates(text, ordered_points)
```

This does not make HangulGuidedOCR a full detection model. It provides a deterministic, app-friendly proposal path for known Korean poster/title layouts.

### 5. Duplicate Suppression

When the same character is detected repeatedly around adjacent points, the decoder collapses near-duplicate tokens:

```text
merge token_j and token_k
if distance(point_j, point_k) < epsilon
and normalized_text(token_j) == normalized_text(token_k)
```

The output is then optionally matched against expected Korean terms or domain vocabulary.

## Korean

### 1. 관측 모델

Apple Vision OCR은 정규화된 bbox, 인식 문자열, confidence를 반환합니다.

```text
o_i = (b_i, y_i, s_i)
b_i = (x_i, y_i, w_i, h_i)
```

HangulGuidedOCR는 이 관측값을 DeepSolo 출력 표현의 경량 proxy로 다룹니다.

```text
I -> {(P_i, y_i, s_i)}
```

여기서 `P_i`는 순서를 가진 점 시퀀스, `y_i`는 인식 문자열, `s_i`는 confidence입니다.

### 2. bbox에서 ordered points로 변환

각 관측 bbox에 대해 중심선을 따라 25개 점을 샘플링합니다.

```text
c_left  = (x_i, y_i + h_i / 2)
c_right = (x_i + w_i, y_i + h_i / 2)
p_k = c_left + (k / 24) * (c_right - c_left), k in [0, 24]
P_i = {p_0, ..., p_24}
```

세로 crop을 회전해 OCR한 경우에는 inverse transform으로 점을 원본 이미지 좌표계에 되돌립니다. 이렇게 하면 Swift 앱에서 가볍게 사용할 수 있으면서도 DeepSolo의 ordered center/boundary 관점을 유지할 수 있습니다.

### 3. 자동 읽기 순서 전략

Auto strategy는 보정이 필요한지 먼저 판단합니다.

```text
if horizontal_line_evidence is strong:
    keep raw Vision order
elif vertical_column_evidence is strong:
    sort columns by Korean layout policy
elif dispersed_component_evidence is strong:
    group components into rows or title strips
else:
    preserve raw order and expose evidence
```

이 전략은 보수적으로 동작합니다. 일반 가로형 포스터는 강제 재정렬로 망가뜨리지 않아야 합니다. 세로 간판, 지하철 역명판, 분산 타이포그래피처럼 raw Vision order가 불안정하다는 geometry evidence가 있을 때만 보정을 활성화합니다.

### 4. Pre-OCR spot proposal

일부 장식형 한국어 제목은 Apple Vision이 애초에 텍스트로 검출하지 못합니다. 이 경우 HangulGuidedOCR는 OCR 전에 후보 영역을 제안할 수 있습니다.

```text
candidate_regions = propose_spots(image, layout_hint)
for region in candidate_regions:
    strip = unwrap(region, ordered_points)
    text = VisionOCR(strip)
    text = suppress_duplicates(text, ordered_points)
```

이는 완전한 detection 모델이 아니라, 앱에서 알고 있는 포스터/제목 레이아웃에 대해 사용할 수 있는 결정론적 보조 단계입니다.

### 5. 중복 억제

같은 글자가 인접한 점 주변에서 반복 검출되면 decoder가 near-duplicate token을 합칩니다.

```text
merge token_j and token_k
if distance(point_j, point_k) < epsilon
and normalized_text(token_j) == normalized_text(token_k)
```

이후 출력은 선택적으로 expected Korean terms나 domain vocabulary와 매칭됩니다.
