# RFW Preview Editor — Design Spec

## Context

rfw_gen은 Flutter 위젯 코드를 rfwtxt로 변환하는 코드 생성기. 현재 생성된 rfwtxt를 실제로 렌더링해서 확인하려면 수동으로 Runtime을 셋업해야 함. **rfwtxt가 실제로 어떻게 보이는지 바로 확인할 수 있는 에디터/프리뷰 도구**가 필요.

## Target Users

- rfw_gen 개발자 — rfwtxt 변환 결과 확인 및 디버깅
- 3o3 팀 — Mystique 커스텀 위젯이 RFW에서 제대로 렌더되는지 QA
- rfw_gen 사용하는 외부 개발자

## Architecture

`rfw_preview` 패키지에서 두 가지 위젯을 export:
- **`RfwEditorApp`** — `MaterialApp`을 포함하는 독립 실행용. `runApp()`에 직접 전달.
- **`RfwEditor`** — `MaterialApp` 없이 임베드 가능한 위젯. 기존 앱의 탭/페이지에 삽입.

```dart
// 독립 앱으로 실행
void main() {
  runApp(RfwEditorApp(
    localWidgetLibraries: {
      customWidgetsLibraryName: LocalWidgetLibrary(customWidgetBuilders),
    },
  ));
}

// 기존 앱에 임베드
Scaffold(
  body: RfwEditor(
    localWidgetLibraries: { ... },
  ),
)
```

### State Management

`RfwEditorController` (ChangeNotifier)가 전체 에디터 상태를 관리:
- rfwtxt 소스 코드
- 선택된 widget name
- JSON data
- 이벤트 로그 리스트
- 테마 모드 (다크/라이트)
- 패널 접힘 상태
- 에러 상태 + 마지막 성공 렌더링

각 패널은 `ListenableBuilder`로 필요한 상태만 구독.

### Dependencies

- `flutter_code_editor` 또는 동급 — syntax highlighting, 줄번호, 현재 줄 하이라이트
- `file_picker` — 파일 열기/저장 (데스크톱/웹 모두 지원)
- `rfw` — 런타임 렌더링

### Package Structure

```
packages/rfw_preview/
├── lib/
│   ├── rfw_preview.dart              # barrel export
│   └── src/
│       ├── rfw_preview_widget.dart   # RfwPreview (기존)
│       ├── rfw_source.dart           # RfwSource (기존)
│       └── editor/
│           ├── rfw_editor_app.dart       # RfwEditorApp (MaterialApp 포함)
│           ├── rfw_editor.dart           # RfwEditor (임베드용)
│           ├── rfw_editor_controller.dart # 상태 관리
│           ├── editor_panel.dart         # 코드 에디터
│           ├── preview_panel.dart        # 라이브 프리뷰
│           ├── data_panel.dart           # JSON 데이터 에디터
│           ├── event_panel.dart          # 이벤트 로그
│           └── editor_theme.dart         # 다크/라이트 테마
```

## API

```dart
RfwEditorApp({
  /// custom widget libraries 주입
  Map<LibraryName, LocalWidgetLibrary>? localWidgetLibraries,

  /// 에디터에서 사용할 library name (default: LibraryName(['preview']))
  LibraryName? libraryName,

  /// 초기 rfwtxt 코드
  String? initialRfwtxt,

  /// 초기 data
  Map<String, Object>? initialData,

  /// 프리셋 snippet 목록
  List<RfwSnippet>? snippets,

  /// 파일 저장 콜백
  void Function(String rfwtxt)? onSave,
})

class RfwSnippet {
  final String name;        // 표시 이름
  final String rfwtxt;      // rfwtxt 소스
  final String widgetName;  // 기본 선택 widget
  final Map<String, Object>? data;  // 연관 데이터
}
```

`RfwEditor`는 동일한 파라미터를 받되 `MaterialApp`을 포함하지 않음.

## Layout

```
┌─────────────────────────────────────────────────────────┐
│  RFW Editor    [widget▼]    [Theme] [Data] [Events] [📁]│  Top Nav (48px)
├────────────────────┬────────────────────────────────────┤
│                    │                                    │
│  rfwtxt Editor     │     Live Preview                   │
│  (줄번호+syntax)   │     (디바이스 프레임)                │
│                    │                                    │
│                    │                                    │
│  ─ Line 12, Col 8 ─  ── iPhone 375pt / 100% ──────── │  Status bars
├────────────────────┴────────────────────────────────────┤
│  [Data] JSON Editor  |  [Events] Event Log              │  Bottom Panel
└─────────────────────────────────────────────────────────┘
```

- **좌우 split**: 드래그로 비율 조절 (기본 50:50)
- **Top Nav**: widget name 드롭다운 (중앙), 액션 버튼들 (우측)
  - [Data] / [Events] 버튼: Bottom Panel의 해당 탭을 열고 펼침. 이미 열려있으면 접음.
  - [📁]: snippet 로드 메뉴
  - [Theme]: 다크/라이트 토글
- **Bottom Panel**: Data / Events 탭 전환, 접힘/펼침 가능
  - 기본 높이: 전체의 25%, 드래그로 조절
- **Responsive**: 넓은 화면 → 좌우 split, 좁은 화면 → 상하 split

## Phased Delivery

### V1a — Core (먼저 출시)

**에디터 패널:**
- `flutter_code_editor` 기반: 줄번호, syntax highlighting, 현재 줄 하이라이트
- 커서 위치 표시 (Line, Col)
- debounce 500ms 자동 렌더 + Cmd+Enter 수동 렌더
- 에러 표시: `parseLibraryFile`의 `FormatException`에서 offset 추출 → 줄 번호 변환 후 표시
- widget name 드롭다운 (rfwtxt에 widget 여러 개일 때)

**프리뷰 패널:**
- RfwPreview로 라이브 렌더링
- custom widget은 `localWidgetLibraries`로 외부 주입
- 디바이스 프레임: iPhone (375pt), Android (360pt), 자유 (SizedBox 제약만, 비주얼 크롬 없음)
- 배경색 전환: 흰색 / szsGray5 / 체커보드
- 줌: 50%~200% 슬라이더
- 에러 시 마지막 성공 렌더링 유지 + 새로고침 버튼

**Bottom Panel:**
- Data 탭: JSON 에디터, 실시간 검증, DynamicContent 즉시 반영
- Events 탭: 이벤트 이름 + args + 타임스탬프 로그, 클리어 버튼

**기타:**
- Snippet 로드: `RfwSnippet` 프리셋 목록에서 선택
- Custom widget 주입
- 다크/라이트 테마 토글 (프리뷰는 항상 라이트)

### V1b — Polish (V1a 직후)

- 검색/치환 (Cmd+F / Cmd+H)
- 자동 정렬 (Cmd+Shift+F) — rfwtxt pretty-printer 구현 필요
- Cmd+S 파일 내보내기 (`file_picker`)
- snippet 전환 시 이전 코드 복원 (history stack)
- 파일 시스템에서 .rfwtxt 열기 (`file_picker`)

### V2 — Future

**에디터 고도화:**
- **자동완성**: widget 이름, 파라미터 이름 자동 제안. rfw_gen.yaml의 widget 목록 + core/material 위젯 목록에서 후보 생성. 파라미터는 rfw-widgets.md의 위젯별 params 참조.
- **코드 접기(folding)**: widget 블록 단위로 접기/펼치기. 큰 rfwtxt 탐색에 유용.
- **멀티 탭**: 여러 rfwtxt 파일을 탭으로 동시에 열어서 전환. 탭 간 복붙 가능.
- **diff 뷰**: 두 rfwtxt를 나란히 비교 (수정 전/후 확인). 코드젠 결과 변경점 추적에 활용.
- **minimap**: 에디터 우측에 코드 전체 미니맵 (VS Code 스타일). 긴 rfwtxt 탐색용.

**프리뷰 고도화:**
- **위젯 탭 → 소스 연결**: 프리뷰에서 위젯을 탭하면 에디터의 해당 rfwtxt 줄로 이동. 디버깅 시 "이 위젯이 어디서 선언됐지?" 바로 확인.
- **위젯 트리 인스펙터**: 렌더된 위젯 트리를 계층 구조로 시각화. 각 노드 선택 시 해당 rfwtxt + 파라미터 값 표시.
- **디바이스 프레임 비주얼 크롬**: `device_frame` 패키지로 실제 디바이스 베젤 표시 (iPhone notch, Android status bar 등).
- **애니메이션 디버깅**: duration/curve 파라미터가 있는 위젯의 애니메이션을 슬로우 모션으로 재생. 애니메이션 타임라인 컨트롤.
- **스크린샷 내보내기**: 프리뷰 결과를 PNG로 저장. PR이나 문서에 첨부용.

**데이터 & 이벤트:**
- **데이터 프리셋 관리**: 프리셋을 저장/편집/삭제 가능한 관리 UI. "로딩 상태", "에러 상태", "빈 데이터", "풀 데이터" 등 시나리오별 프리셋.
- **이벤트 시뮬레이션**: Events 패널에서 이벤트를 수동으로 트리거. `set state.*` 테스트에 유용.
- **data.* 참조 자동 감지**: rfwtxt에서 `data.user.name` 같은 참조를 파싱해서 JSON 에디터에 스키마 자동 생성. 빈 rfwtxt → JSON 골격 자동 제안.

**공유:**
- **클립보드 내보내기**: 현재 rfwtxt + data를 JSON으로 클립보드에 복사. 다른 사람이 붙여넣기로 동일한 상태 복원.

**rfw_gen 연동:**
- **build_runner watch 연동**: `dart run build_runner watch` 실행 중이면 @RfwWidget 함수 수정 → .rfwtxt 자동 재생성 → 에디터가 파일 변경 감지 → 프리뷰 자동 업데이트. 소스 코드 수정부터 프리뷰까지 완전 자동화.
- **커버리지 표시**: rfw_gen이 지원하는 위젯/파라미터와 지원하지 않는 것을 에디터에서 색상으로 구분. 미지원 항목은 경고 표시.

**접근성 & UX:**
- 키보드 네비게이션: 패널 간 Tab 이동, 포커스 관리
- 스크린 리더 라벨
- 에디터 폰트 사이즈 조절 (Cmd++ / Cmd+-)

## Keyboard Shortcuts

| Shortcut | Action | Phase |
|----------|--------|-------|
| Cmd+Enter | 수동 렌더 | V1a |
| Cmd+Z | Undo | V1a |
| Cmd+F | 검색 | V1b |
| Cmd+H | 치환 | V1b |
| Cmd+Shift+F | 자동 정렬 | V1b |
| Cmd+S | 파일 내보내기 | V1b |

## Theme

- **다크 모드** (에디터 기본): 어두운 배경, syntax highlighting 최적화
- **라이트 모드**: Mystique 디자인 시스템 기반 (#FFFFFF 배경, szsBlue55 포인트)
- **프리뷰 패널은 항상 라이트**: 실제 앱 렌더링 결과를 정확히 보기 위해
- Top Nav에 테마 토글 버튼

## Error Handling

- `parseLibraryFile()`가 `FormatException`을 throw — `offset` 필드에서 문자 위치 추출
- 문자 offset → 줄 번호/컬럼 변환 (rfwtxt 문자열에서 `\n` 카운트)
- 에디터 하단 상태바에 에러 메시지 + 줄 번호 표시 (szsRed50)
- 프리뷰는 마지막 성공 렌더링 유지 (타이핑 중 깜빡임 방지)

## Verification

### V1a
1. `flutter run -d macos` (또는 `-d chrome`)로 독립 앱 실행
2. 기본 rfwtxt가 프리뷰에 렌더링되는지 확인
3. rfwtxt 수정 → 500ms 후 프리뷰 자동 업데이트
4. JSON 데이터 수정 → 프리뷰 반영
5. 이벤트 트리거 → Events 탭에 로그
6. 디바이스 프레임 / 줌 / 배경색 전환 동작
7. snippet 프리셋 로드 / widget name 전환
8. 다크/라이트 테마 토글
9. custom widget이 프리뷰에 정상 렌더링
10. 파싱 에러 시 줄 번호 표시 + 마지막 성공 렌더링 유지

### V1b
11. Cmd+F 검색 / Cmd+H 치환
12. Cmd+Shift+F 자동 정렬
13. Cmd+S 파일 저장
14. snippet 전환 → 이전 코드 복원
