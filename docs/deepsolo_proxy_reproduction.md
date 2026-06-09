# DeepSolo Proxy Reproduction Notes

## English

The original DeepSolo implementation depends on Detectron2, CUDA, and Linux-oriented inference paths. The local development environment was macOS arm64, so official inference could not be completed in a fully faithful CUDA setting. The project therefore separates two notions:

1. **Official model reproduction attempt**: environment setup, Docker/UTM notes, dependency failure points, and the reason CUDA inference was not claimed as directly reproduced.
2. **Representation-level reproduction**: the DeepSolo output form `I -> {(P_i, y_i, s_i)}` was reproduced as a proxy from Vision OCR observations.

This proxy is not reported as DeepSolo model performance. It is used as a design bridge: ordered center-line points and boundary cues are transformed into Korean OCR reading-order correction rules.

## Korean

DeepSolo 공식 구현은 Detectron2, CUDA, Linux 중심 inference 경로에 크게 의존합니다. 로컬 개발 환경은 macOS arm64였기 때문에 CUDA 기반 official inference를 완전하게 재현했다고 주장하지 않습니다. 따라서 본 프로젝트는 두 가지를 분리합니다.

1. **공식 모델 재현 시도**: 환경 설정, Docker/UTM 기록, dependency 실패 지점, CUDA inference를 직접 재현했다고 주장하지 않는 이유입니다.
2. **표현 수준 재현**: DeepSolo 출력 형태 `I -> {(P_i, y_i, s_i)}`를 Vision OCR 관측값에서 proxy로 재현했습니다.

이 proxy는 DeepSolo 모델 성능으로 보고하지 않습니다. ordered center-line points와 boundary cues를 한국어 OCR 읽기 순서 보정 규칙으로 옮기는 설계 연결고리로 사용합니다.
