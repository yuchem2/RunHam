# RunCatClone

CPU 사용률에 따라 메뉴바의 고양이가 빨리 달리는 RunCat Neo 를 리버스 엔지니어링으로 분석해 Swift 로 다시 만든 학습용 프로젝트.
분석 내용은 [docs/reverse-engineering.md](docs/reverse-engineering.md) 참고.

## 빌드 & 실행

```bash
./scripts/bundle.sh          # build/RunCatClone.app 생성 (release)
open build/RunCatClone.app
```

Xcode 없이 Command Line Tools(SwiftPM)만으로 빌드한다.
Xcode 가 설치돼 있지만 라이선스에 동의하지 않은 상태라면 CLT 를 직접 지정한다:
`export DEVELOPER_DIR=/Library/Developer/CommandLineTools`

```bash
./scripts/test.sh            # 단위 테스트 (CLT 용 Swift Testing 플러그인 경로 포함)
```

## 구현 범위

- CPU 사용률: `host_statistics64(HOST_CPU_LOAD_INFO)` tick 델타, 링버퍼 평균
- 속도: `clamp(cpu% / 5, 1, 20)`, "Slow Down Under Load" 시 `(21 - speed) * 0.5`
- 애니메이션: `CAKeyframeAnimation(contents)`, 속도 1 = 초당 2프레임, 속도 변경 시 위상 유지
- 메뉴: 시스템 메트릭 대시보드(CPU 그래프, 메모리, 저장공간, 배터리, 네트워크 + 로컬 IP), 설정…, 활성 상태 보기
- Custom Metrics: RunCat Neo 와 같은 JSON 스키마의 파일을 등록하면 대시보드 카드로 표시, 파일이 바뀌면 바로 갱신
- 메트릭스 바: CPU·메모리·저장공간·배터리·네트워크·Custom Metrics(metricsBarValue)를 메뉴바에 상시 표시. 아무것도 켜지 않으면 자는 고양이
- 설정 창: General(로그인 시 실행, 업데이트 간격) / Runner(미리보기, 반전, 부하 시 감속, 메뉴바 CPU 표시) / Metrics(카드 표시)
- 다국어: English / 한국어, 설정 > 일반 > 언어에서 재시작 없이 전환. 새 언어는 lproj 폴더만 추가([docs/localization.md](docs/localization.md))
- 러너: 곡선(벡터)으로 그린 고양이(기본, 뼈대 자세로 프레임 생성)와 도트 고양이 중 선택. 원본 에셋은 쓰지 않는다
- `RunCatClone --export-previews <dir>`: 러너 프레임·대시보드·설정 화면을 PNG 로 내보내는 개발용 플래그

## Custom Metrics

스키마: [RunCat Neo CustomMetricsSchema.md](https://github.com/runcat-dev/RunCatNeo/blob/main/docs/CustomMetricsSchema.md) (같은 파일을 두 앱에서 함께 쓸 수 있다)
예제: [docs/custom-metrics-sample.json](docs/custom-metrics-sample.json)

```bash
./scripts/custom-metrics-example.sh ~/custom-metrics/load.json --watch   # 부하 정보를 5초마다 갱신
```

설정 > Metrics > Custom Metrics > Add Custom Metrics Source… 에서 출력 파일을 추가한다.

## 출처

RunCat Neo (Copyright 2026 Kyome22 / Takuto Nakamura, Apache License 2.0, https://github.com/runcat-dev/RunCatNeo) 의
동작, 공개 스키마, 메트릭스 바 레이아웃(MetricsBarView / IndicatorKind)을 참고했다. 원본 소스·이미지는 포함하지 않는다.
원본 코드를 가져올 경우 해당 파일에 원본 저작권 헤더를 유지하고, 변경 사실을 적고, Apache 2.0 LICENSE 사본을 함께 둔다.

## 아직 없는 것

다른 러너, 커스텀 러너(PNG 업로드) 에디터
