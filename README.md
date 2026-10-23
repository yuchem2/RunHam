# RunHam 🐹

CPU 사용률이 높을수록 메뉴바의 햄스터가 빨리 깡총깡총 뛰는 macOS 메뉴바 앱.
RunCat Neo 의 동작을 참고해 Swift 로 새로 만든 프로젝트다.

## 빌드 & 실행

```bash
./scripts/bundle.sh          # build/RunHam.app 생성 (release)
open build/RunHam.app
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
- 다국어: English / 한국어 / 日本語 / 简体中文, 설정 > 일반 > 언어에서 재시작 없이 전환. 새 언어는 `Sources/RunHam/Resources/<code>.lproj/Localizable.strings` 만 추가하면 된다
- 러너: 깡총 햄스터(기본), 햄스터 공 굴리기, 해바라기씨 먹는 햄스터(CPU 가 높을수록 빨리 오물오물), 갤럽하는 고양이. 햄스터들은 검은 실루엣에 하얀 눈 하나인 같은 모양(`HamsterSilhouette`)을 쓰고, 모두 Core Graphics 곡선으로 그려 원본 에셋은 쓰지 않는다
- 앱 아이콘: 해바라기씨 색 그라데이션 위로 하얀 햄스터가 뛰어드는 그림(`AppIconRenderer`). 그림을 바꾸면 `./scripts/make-icon.sh` 로 `Assets/AppIcon.icns` 를 다시 만든다
- 커스텀 러너: RunCat Neo 와 같은 형식(PNG, 높이 36px, 너비 10~100px, 최대 30장)의 프레임 폴더를 설정 > 러너에서 추가.
  프레임은 `~/Library/Application Support/RunHam/Runners/` 에 복사해 둔다. [러너 갤러리](https://runcat-dev.github.io/RunnerGallery/)(Apache 2.0)의 러너도 zip 을 풀어 추가할 수 있다
- `RunHam --export-previews <dir>`: 러너 프레임·대시보드·설정 화면을 PNG 로 내보내는 개발용 플래그

## Custom Metrics

스키마: [RunCat Neo CustomMetricsSchema.md](https://github.com/runcat-dev/RunCatNeo/blob/main/docs/CustomMetricsSchema.md) (같은 파일을 두 앱에서 함께 쓸 수 있다)

```bash
./scripts/custom-metrics-example.sh ~/custom-metrics/load.json --watch   # 부하 정보를 5초마다 갱신
```

설정 > Metrics > Custom Metrics > Add Custom Metrics Source… 에서 출력 파일을 추가한다.

## 출처

RunCat Neo (Copyright 2026 Kyome22 / Takuto Nakamura, Apache License 2.0, https://github.com/runcat-dev/RunCatNeo) 의
동작, 공개 스키마, 메트릭스 바 레이아웃(MetricsBarView / IndicatorKind)을 참고했다. 원본 소스·이미지는 포함하지 않는다.
원본 코드를 가져올 경우 해당 파일에 원본 저작권 헤더를 유지하고, 변경 사실을 적고, Apache 2.0 LICENSE 사본을 함께 둔다.
외부 오픈소스 라이브러리는 쓰지 않는다. 나중에 추가하면 앱의 "오픈소스 라이선스" 창(`LicensesView.entries`)과 `Resources/Licenses/` 에 라이선스를 함께 넣는다.

## 라이선스

Apache License 2.0 (`LICENSE`). 버그 리포트는 https://github.com/yuchem2/RunHam/issues 로 받는다(앱 메뉴 → 문제 보고를 누르면 환경 정보가 채워진 새 이슈 화면이 열린다).
