<p align="center">
  <img src="Assets/readme/icon.png" width="128" alt="RunHam 앱 아이콘">
</p>

<h1 align="center">RunHam</h1>

<p align="center">
  CPU가 바빠질수록 더 빨리 깡총깡총 뛰는, Mac 메뉴바 속 햄스터.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14%2B-black?logo=apple" alt="macOS 14 이상">
  <img src="https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white" alt="Swift 6">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-Apache%202.0-blue" alt="Apache License 2.0"></a>
  <img src="https://img.shields.io/badge/languages-EN%20%7C%20KO%20%7C%20JA%20%7C%20ZH-lightgrey" alt="영어, 한국어, 일본어, 중국어">
</p>

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="Assets/readme/hero-dark.gif">
    <img src="Assets/readme/hero-light.gif" height="160" alt="깡총 뛰는 햄스터 러너">
  </picture>
</p>

<p align="center"><a href="README.md">English</a> · <b>한국어</b></p>

---

## 기능

- 🐹 **Mac 상태에 반응하는 러너.** CPU가 바쁠수록 햄스터가 빨리 뜁니다. 반대가 좋다면 *부하가 높을 때 감속*을 켜세요.
- 📊 **클릭 한 번에 대시보드.** CPU 기록, 메모리, 저장 공간, 배터리, 네트워크(종류·속도·로컬 IP)를 메뉴바에서 바로 봅니다.
- 📌 **메트릭스 바.** 자주 보는 수치를 러너 옆에 항상 띄워 둡니다.
- 🎨 **커스텀 러너.** 직접 만든 PNG 프레임을 넣고, 끌어서 순서를 바꾸고, 미리보기로 확인한 뒤 추가합니다.
- 🧩 **커스텀 메트릭.** JSON 파일을 등록하면 실시간 대시보드 카드가 됩니다.
- 🌏 **4개 언어.** English, 한국어, 日本語, 简体中文을 재시작 없이 바꿉니다.
- 🪶 **가벼움.** 외부 라이브러리 없이 Swift로만 만들었고, 보통 CPU를 1% 아래로 씁니다.

## 스크린샷

<table>
  <tr>
    <th>대시보드</th>
    <th>설정</th>
  </tr>
  <tr>
    <td valign="top">
      <picture>
        <source media="(prefers-color-scheme: dark)" srcset="Assets/readme/dashboard-ko-dark.png">
        <img src="Assets/readme/dashboard-ko-light.png" width="330" alt="대시보드">
      </picture>
    </td>
    <td valign="top">
      <picture>
        <source media="(prefers-color-scheme: dark)" srcset="Assets/readme/settings-runner-ko-dark.png">
        <img src="Assets/readme/settings-runner-ko-light.png" width="420" alt="러너 설정">
      </picture>
    </td>
  </tr>
</table>

## 러너

| | 러너 | |
|:---:|---|---|
| <picture><source media="(prefers-color-scheme: dark)" srcset="Runners/hamster/preview-dark.gif"><img src="Runners/hamster/preview-light.gif" height="56" alt="햄스터"></picture> | **햄스터** (기본) | 웅크렸다가 박차고 올라 쭉 늘어나며 착지합니다. |
| <picture><source media="(prefers-color-scheme: dark)" srcset="Runners/hamster-ball/preview-dark.gif"><img src="Runners/hamster-ball/preview-light.gif" height="56" alt="햄스터 공"></picture> | **햄스터 공** | 굴러가는 운동볼 안에서 종종 달립니다. |
| <picture><source media="(prefers-color-scheme: dark)" srcset="Runners/hamster-snack/preview-dark.gif"><img src="Runners/hamster-snack/preview-light.gif" height="56" alt="해바라기씨 먹는 햄스터"></picture> | **해바라기씨 먹는 햄스터** | 씨를 오물오물 먹으며 부스러기를 흘립니다. |
| <picture><source media="(prefers-color-scheme: dark)" srcset="Runners/cat/preview-dark.gif"><img src="Runners/cat/preview-light.gif" height="56" alt="고양이"></picture> | **고양이** | 날렵하게 갤럽하는 고양이. |

기본 러너는 모두 [`Runners/`](Runners/) 폴더에 PNG 프레임으로도 들어 있어서,
다른 앱에서 쓰거나 새 러너를 만드는 출발점으로 쓸 수 있습니다.

## 설치

아직 빌드된 배포판은 없습니다. 소스에서 빌드하세요.

```bash
git clone https://github.com/yuchem2/RunHam.git
cd RunHam
./scripts/bundle.sh          # build/RunHam.app 생성
open build/RunHam.app
```

macOS 14 이상과 Swift 6가 들어 있는 Xcode(또는 Command Line Tools)가 필요합니다.
`build/RunHam.app`을 `/Applications`로 옮기고 설정에서 **로그인 시 실행**을 켜 두면 계속 실행됩니다.

## 사용법

- **대시보드**: 메뉴바의 러너를 누릅니다. 맨 위 ☰ 버튼에서 설정, 활성 상태 보기, RunHam에 관하여, 오픈소스 라이선스, 문제 보고, 종료를 엽니다.
- **설정 › 러너**: 러너를 고르고, 좌우 반전, 옆에 CPU 사용률 표시, 부하가 높을 때 감속을 설정합니다.
- **설정 › 메트릭**: 대시보드 카드와 메트릭스 바에 보일 항목을 고릅니다.

### 커스텀 러너

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="Assets/readme/custom-runner-ko-dark.png">
  <img src="Assets/readme/custom-runner-ko-light.png" width="440" align="right" alt="커스텀 러너 편집기">
</picture>

1. **설정 › 러너 › 커스텀 러너 추가…**를 엽니다.
2. **+**를 누르거나 PNG 파일·폴더를 프레임 격자에 끌어 놓습니다.
3. 프레임을 끌거나 ‹ ›로 순서를 정하고, 미리보기를 확인한 뒤 **추가**를 누릅니다.

프레임은 PNG, 높이 36px, 너비 10~100px, 최대 30장입니다.
**흑백**은 라이트·다크 모드에서 메뉴바 글자색을 따르고, **컬러**는 원래 색을 그대로 씁니다.
[러너 갤러리](https://runcat-dev.github.io/RunnerGallery/)의 러너도 쓸 수 있습니다.

<br clear="right">

### 커스텀 메트릭

**설정 › 메트릭 › 사용자 지정 메트릭**에서 JSON 파일을 등록하면 대시보드 카드로 보이고, 파일이 바뀔 때마다 갱신됩니다.
형식은 [RunCat Neo 커스텀 메트릭 스키마](https://github.com/runcat-dev/RunCatNeo/blob/main/docs/CustomMetricsSchema.md)를 따릅니다.

```bash
./scripts/custom-metrics-example.sh ~/custom-metrics/load.json --watch   # 5초마다 시스템 부하를 기록
```

## 개발

```bash
./scripts/test.sh               # 단위 테스트
./scripts/export-showcase.sh    # Runners/ 와 README 이미지를 다시 만듦
./scripts/make-icon.sh          # Assets/AppIcon.icns 를 다시 만듦
```

- 러너와 앱 아이콘은 Core Graphics 코드로 그립니다(`Sources/RunHam/Runner/`, `AppIconRenderer`). 이미지 에셋은 넣지 않습니다.
- 기본 러너를 추가하는 방법은 [`Runners/README.ko.md`](Runners/README.ko.md)를 보세요.
- 새 언어는 영어와 같은 키로 `Sources/RunHam/Resources/<code>.lproj/Localizable.strings`를 추가합니다. 빠진 키가 있으면 테스트가 알려 줍니다.
- 외부 라이브러리는 쓰지 않습니다. 추가하면 `LicensesView.entries`에 적고 `Sources/RunHam/Resources/Licenses/`에 라이선스를 넣습니다.

## 문제 보고

☰ 메뉴에서 **문제 보고**를 누르면 환경 정보가 채워진 새 이슈 화면이 열립니다. [GitHub Issues](https://github.com/yuchem2/RunHam/issues)에서 직접 남겨도 됩니다.

## 감사의 말

RunHam은 [RunCat Neo](https://github.com/runcat-dev/RunCatNeo)(Copyright 2026 Kyome22 / Takuto Nakamura, Apache License 2.0)의
동작과 데이터 형식에서 영감을 받아 새로 만들었습니다. RunCat Neo의 코드와 이미지는 포함하지 않습니다.

## 라이선스

RunHam은 [Apache License 2.0](LICENSE)으로 배포됩니다.
