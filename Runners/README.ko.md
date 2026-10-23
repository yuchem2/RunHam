# 러너

[English](README.md) · **한국어**

RunHam 기본 러너의 PNG 프레임입니다. 그림 코드로 만들어 내는 파일이라 직접 고치지 마세요.

| 미리보기 | 폴더 | 러너 | 프레임 | 크기(pt) |
|:---:|---|---|---:|---|
| <img src="hamster/preview-light.gif" height="40" alt="햄스터 (기본)"> | [`hamster/`](hamster/) | 햄스터 (기본) | 8 | 22 × 18 |
| <img src="hamster-ball/preview-light.gif" height="40" alt="햄스터 공"> | [`hamster-ball/`](hamster-ball/) | 햄스터 공 | 8 | 24 × 18 |
| <img src="hamster-snack/preview-light.gif" height="40" alt="해바라기씨 먹는 햄스터"> | [`hamster-snack/`](hamster-snack/) | 해바라기씨 먹는 햄스터 | 6 | 22 × 18 |
| <img src="hamster-roll/preview-light.gif" height="40" alt="데굴데굴 햄스터"> | [`hamster-roll/`](hamster-roll/) | 데굴데굴 햄스터 | 8 | 24 × 18 |
| <img src="cat/preview-light.gif" height="40" alt="고양이"> | [`cat/`](cat/) | 고양이 | 10 | 30 × 18 |
| <img src="chick/preview-light.gif" height="40" alt="병아리"> | [`chick/`](chick/) | 병아리 | 6 | 20 × 18 |
| <img src="penguin/preview-light.gif" height="40" alt="펭귄"> | [`penguin/`](penguin/) | 펭귄 | 8 | 18 × 18 |
| <img src="whale/preview-light.gif" height="40" alt="고래"> | [`whale/`](whale/) | 고래 | 8 | 26 × 18 |
| <img src="shark/preview-light.gif" height="40" alt="상어"> | [`shark/`](shark/) | 상어 | 8 | 34 × 18 |
| | [`sleeping-hamster.png`](sleeping-hamster.png) | 빈 메트릭스 바에 보이는 자는 햄스터 | 1 | 28 × 18 |

폴더마다 들어 있는 파일:

- `<id>-frame-<n>.png`: 재생 순서대로인 프레임. 높이 36px(@2x 메뉴바 높이), 투명 바탕에 검은 실루엣입니다.
- `preview-light.gif` / `preview-dark.gif`: 밝은·어두운 메뉴바 색 위의 미리보기.

## 다른 곳에서 쓰기

프레임은 [커스텀 러너 형식](../Formats/custom-runner.ko.md)(PNG, 높이 36px, 너비 10~100px, 최대 30장)을 따릅니다.
RunHam에서는 **설정 › 러너 › 커스텀 러너 추가…**에서 폴더를 끌어 놓으면 됩니다.

## 기본 러너 추가하기

러너는 Core Graphics 코드로 그려서 어떤 크기에서도 선명합니다.

1. `Sources/RunHam/Runner/<Name>Sprite.swift`를 만들고 `Runner`를 돌려주는 `makeRunner()`를 둡니다
   (`id`, `nameKey`, 2배 크기 `frames`, 6배 크기 `previewFrames`, `baseFrameRate`).
   캔버스와 배율은 `DrawnRunner.make`가 맡고, 햄스터는 `HamsterSilhouette`, 헤엄치는 동물은 `SwimmerBody`를 쓰면 됩니다.
2. `Sources/RunHam/Runner/Runner.swift`의 `Runner.builtIns`에 넣습니다.
3. 모든 `Localizable.strings`(en, ko, ja, zh-Hans)에 `"runner.<key>"`를 추가합니다.
4. `./scripts/test.sh`를 실행합니다.
5. `./scripts/export-showcase.sh`로 이 폴더와 README 이미지를 다시 만들고, README 표에 새 러너를 넣습니다.

18pt에서도 알아보기 쉽게 만드세요. 또렷한 윤곽, 하얀 눈 하나, 메뉴바에서도 보일 만큼 큰 움직임이 좋습니다.
