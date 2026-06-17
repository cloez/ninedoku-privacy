# 사운드 자산 라이센스 문서

> v1.0.1+7 — 프로그래밍 합성으로 전환
> 작성: DEV / 일자: 2026-06-15

## v1.0.1+7 정책 — 프로그래밍 합성

모든 사운드 자산은 `scripts/generate_sounds.dart`로 사인파/노이즈 합성하여 생성됨.
- 외부 자산 0건
- 라이센스: **자체 제작 (퍼블릭 도메인 동등, 자유 사용)**
- 포맷: 16-bit PCM 모노 WAV (44.1kHz)
- 재생성: `dart run scripts/generate_sounds.dart` 실행

각 사운드 합성 사양은 `scripts/generate_sounds.dart` 의 주석 참조.

| 파일 | 합성 방식 | 길이 |
|---|---|---|
| `click.wav` | 1200Hz 사인파 + 빠른 페이드아웃 | 60ms |
| `mistake.wav` | 200Hz + 400Hz 비프 | 200ms |
| `line_complete.wav` | 800Hz + 1200Hz 화음 | 300ms |
| `game_complete.wav` | C5-E5-G5-C6 상승 음계 | 1000ms |
| `badge.wav` | 1500Hz + 2000Hz + 트레몰로 | 500ms |
| `hint.wav` | 400Hz→1600Hz 글리산도 | 400ms |
| `pause.wav` | 600Hz 부드러운 톤 | 300ms |

---

## (구) v1.0.1+6 기록 — 외부 자산 후보 (사용 안 함)

## 자산 목록

현재 `assets/sounds/` 의 7개 파일은 **빈 플레이스홀더(0 byte)** 이다.
실제 라이센스 안전한 자산으로 교체 예정. 파일 누락 시 SoundManager 는 silent fail 로
동작하여 게임 진행에는 영향이 없다.

| 파일명 | 용도 | 권장 출처 | 라이센스 |
|---|---|---|---|
| `click.ogg` | 셀 입력 / 버튼 탭 | Mixkit "Light click" | Mixkit Free |
| `mistake.ogg` | 잘못된 입력 | Mixkit "Error 1" 또는 Freesound CC0 | Mixkit Free / CC0 |
| `line_complete.ogg` | 행/열/박스 완성 | Mixkit "Bell chime" | Mixkit Free |
| `game_complete.ogg` | 퍼즐 완성 | Mixkit "Achievement bell" | Mixkit Free |
| `badge.ogg` | 새 배지 획득 팝업 | Mixkit "Magic spell" | Mixkit Free |
| `hint.ogg` | 힌트 사용 | Mixkit "Magic wand" | Mixkit Free |
| `pause.ogg` | 일시정지/재개 | Mixkit "Soft pop" | Mixkit Free |

## Mixkit Free 라이센스 조건

- 상업 / 비상업 무료 사용 가능
- 출처 표기 권장(필수 아님)
- 재배포 불가 (앱 임베드는 OK)
- Mixkit 소속물로 판매 금지

출처: https://mixkit.co/license/

## Freesound CC0 (우선 검토)

가능하면 Freesound.org 의 **CC0 (Public Domain)** 라이센스 자산을 우선 사용한다.
- https://freesound.org/browse/tags/cc0/

## 교체 절차

1. 위 권장 출처에서 OGG/MP3 다운로드 (각 < 100KB)
2. `assets/sounds/{이름}.ogg` 로 덮어쓰기
3. 본 문서의 "다운로드 URL" 컬럼을 채워 출처를 명시
4. 빌드/실기기 검증

## 다운로드 URL 추적 (TBD)

| 파일명 | 다운로드 URL | 다운로드 일자 |
|---|---|---|
| click.ogg | TBD | - |
| mistake.ogg | TBD | - |
| line_complete.ogg | TBD | - |
| game_complete.ogg | TBD | - |
| badge.ogg | TBD | - |
| hint.ogg | TBD | - |
| pause.ogg | TBD | - |

---

## 사용자/관리자 자산 교체 절차

**현재 상태**: `assets/sounds/*.ogg` 7개가 0 byte 더미. SoundManager는 silent fail로 게임은 정상 진행되나 사운드가 들리지 않음. APK 출시 전 반드시 실제 자산으로 교체해야 한다.

**교체 절차**:

1. 다음 사이트에서 라이센스 안전한 사운드 다운로드:
   - **Mixkit Free**: https://mixkit.co/free-sound-effects/
   - **Freesound CC0**: https://freesound.org (필터: License → Creative Commons 0)
2. 각 사운드를 OGG Vorbis 포맷으로 변환 (Audacity 무료 사용 가능):
   - File → Export → Export as OGG → Quality 5 정도
3. 다음 7개 파일을 동일 파일명으로 덮어쓴다 (`assets/sounds/`):

| 파일명 | 권장 길이 | 분위기 |
|---|---|---|
| `click.ogg` | 50ms | 부드러운 틱 (셀 입력) |
| `mistake.ogg` | 200ms | 가벼운 부저 (실수) |
| `line_complete.ogg` | 300ms | 짧은 차임 (행/열/박스 완성) |
| `game_complete.ogg` | 1000ms | 팡파레 (게임 클리어) |
| `badge.ogg` | 500ms | 별/반짝임 사운드 (배지 획득) |
| `hint.ogg` | 400ms | 마법 반짝임 (힌트 표시) |
| `pause.ogg` | 300ms | 부드러운 톤 (일시정지) |

4. 각 자산의 다운로드 URL/라이센스를 본 문서의 위 추적표("다운로드 URL 추적")에 기록한다.
5. APK 재빌드 → 자동 적용 (별도 코드 변경 없음).

**알려진 안전 자산 예시** (실제 다운로드 후 검증 필요):

| 키 | 추천 자산 | URL | 라이센스 |
|----|----------|-----|----------|
| click | Mixkit "Tile click sound" | https://mixkit.co/free-sound-effects/click/ | Mixkit Free |
| mistake | Mixkit "Wrong electricity buzz" | https://mixkit.co/free-sound-effects/error/ | Mixkit Free |
| line_complete | Mixkit "Game level completed" | https://mixkit.co/free-sound-effects/win/ | Mixkit Free |
| game_complete | Mixkit "Winning a coin video game" | https://mixkit.co/free-sound-effects/win/ | Mixkit Free |
| badge | Freesound CC0 "Star pickup" | https://freesound.org/search/?q=star+pickup&f=license:%22Creative+Commons+0%22 | CC0 |
| hint | Mixkit "Magic notification" | https://mixkit.co/free-sound-effects/notification/ | Mixkit Free |
| pause | Mixkit "Soft pause" | https://mixkit.co/free-sound-effects/click/ | Mixkit Free |

**참고**: Mixkit Free 라이센스는 앱 임베드 OK이지만 자산을 별도로 재배포하는 것은 금지. 본 저장소에 OGG 파일을 커밋해도 앱 내 사용이므로 라이센스 위반은 아님.
