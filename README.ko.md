# RunHam 🐹

[English](README.md) | **한국어**

CPU 사용률이 높을수록 메뉴바의 햄스터가 빨리 깡총깡총 뛰는 macOS 메뉴바 앱입니다.
메뉴를 열면 CPU, 메모리, 저장 공간, 배터리, 네트워크 사용량을 대시보드로 볼 수 있습니다.

## 기능

- **러너**: 깡총 햄스터(기본), 햄스터 공, 해바라기씨 먹는 햄스터(부하가 높을수록 빨리 오물오물), 갤럽하는 고양이.
  CPU를 많이 쓸수록 러너가 빨라집니다. 좌우 반전이나, 부하가 높을 때 오히려 느려지게 할 수도 있습니다.
- **대시보드**: CPU 사용률 그래프, 메모리, 저장 공간, 배터리, 네트워크 종류·속도·로컬 IP 주소.
  맨 위 햄버거 버튼에서 설정, 활성 상태 보기, RunHam에 관하여, 오픈소스 라이선스, 문제 보고, 종료를 엽니다.
- **메트릭스 바**: 고른 값(CPU, 메모리, 저장 공간, 배터리, 네트워크, 커스텀 메트릭)을 러너 옆에 항상 표시합니다.
  아무것도 고르지 않으면 자는 햄스터가 보입니다.
- **커스텀 러너**: 직접 만든 PNG 프레임(높이 36px, 너비 10~100px, 최대 30장)을 추가합니다.
  프레임을 끌어서 순서를 바꾸고, 미리보기로 확인하고, 흑백(메뉴바 글자색을 따름)이나 컬러를 고를 수 있습니다.
  [러너 갤러리](https://runcat-dev.github.io/RunnerGallery/)의 러너도 추가할 수 있습니다.
- **커스텀 메트릭**: JSON 파일을 등록하면 대시보드 카드로 보이고, 파일이 바뀔 때마다 갱신됩니다.
  형식은 [RunCat Neo 커스텀 메트릭 스키마](https://github.com/runcat-dev/RunCatNeo/blob/main/docs/CustomMetricsSchema.md)와 호환됩니다.
- **언어**: English, 한국어, 日本語, 简体中文. 설정 › 일반 › 언어에서 재시작 없이 바꿉니다.

## 요구 사항

macOS 14 이상

## 빌드와 실행

```bash
./scripts/bundle.sh        # build/RunHam.app 생성 (release)
open build/RunHam.app
```

Swift 패키지라서 Xcode나 Command Line Tools로 빌드합니다.

```bash
./scripts/test.sh          # 단위 테스트
```

## 커스텀 메트릭 예제

```bash
./scripts/custom-metrics-example.sh ~/custom-metrics/load.json --watch   # 5초마다 시스템 부하를 기록
```

설정 › 메트릭 › 사용자 지정 메트릭 › 사용자 지정 메트릭 추가…에서 출력 파일을 추가합니다.

## 개발 메모

- 러너 프레임과 앱 아이콘은 Core Graphics 코드로 그립니다(`HamsterSilhouette`, `AppIconRenderer`). 이미지 에셋은 넣지 않습니다.
- 아이콘 그림을 바꾸면 `./scripts/make-icon.sh`로 `Assets/AppIcon.icns`를 다시 만듭니다.
- 새 언어는 영어와 같은 키로 `Sources/RunHam/Resources/<code>.lproj/Localizable.strings`를 추가하면 됩니다.
- `RunHam --export-previews <dir>`는 러너 프레임과 화면을 PNG로 내보냅니다.
- 외부 라이브러리는 쓰지 않습니다. 추가하면 `LicensesView.entries`에 적고 `Resources/Licenses/`에 라이선스를 넣습니다.

## 감사의 말

RunHam은 [RunCat Neo](https://github.com/runcat-dev/RunCatNeo)(Copyright 2026 Kyome22 / Takuto Nakamura, Apache License 2.0)의
동작과 데이터 형식을 참고해 새로 만들었습니다. RunCat Neo의 코드와 이미지는 포함하지 않습니다.

## 문제 보고

앱 메뉴에서 **문제 보고**를 누르면 환경 정보가 채워진 새 이슈 화면이 열립니다.
[Issues](https://github.com/yuchem2/RunHam/issues)에서 직접 남겨도 됩니다.

## 라이선스

[Apache License 2.0](LICENSE)
