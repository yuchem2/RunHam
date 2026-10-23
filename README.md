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
- 메뉴: 시스템 메트릭 대시보드(CPU 그래프, 메모리, 저장공간, 배터리, 네트워크), 설정…, 활성 상태 보기
- 설정 창: General(로그인 시 실행, 업데이트 간격) / Runner(미리보기, 반전, 부하 시 감속, 메뉴바 CPU 표시) / Metrics(카드 표시)
- 고양이 스프라이트는 원본 에셋을 쓰지 않고 코드로 그린다
- `RunCatClone --export-previews <dir>`: 러너 프레임·대시보드·설정 화면을 PNG 로 내보내는 개발용 플래그

## 아직 없는 것

메트릭스 바(메뉴바에 수치 상시 표시), 다른 러너, 커스텀 러너(PNG 업로드) 에디터, 커스텀 메트릭(JSON)
