# RunCatClone

CPU 사용률에 따라 메뉴바의 고양이가 빨리 달리는 RunCat Neo 를 리버스 엔지니어링으로 분석해 Swift 로 다시 만든 학습용 프로젝트.
분석 내용은 [docs/reverse-engineering.md](docs/reverse-engineering.md) 참고.

## 빌드 & 실행

```bash
./scripts/bundle.sh          # build/RunCatClone.app 생성 (release)
open build/RunCatClone.app
```

Xcode 없이 Command Line Tools(SwiftPM)만으로 빌드한다.
