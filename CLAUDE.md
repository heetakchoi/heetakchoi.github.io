# heetakchoi.github.io

개인 블로그 "Life Logging" (https://heetakchoi.github.io) 을 빌드하는 정적 사이트 생성기.

## 디렉토리 구조

```
data/
  articles/     # 아티클 콘텐츠 (1.txt ~ 91.txt, ...)
  books/        # 북 콘텐츠 (1.txt, 2.txt, ...)
  front.txt     # 홈(index.html) 본문
  info.txt      # Info 페이지 본문
  sf.txt        # SF 페이지 본문
template/
  base.html     # 전체 레이아웃 (헤더, 메뉴, 푸터)
  article.html  # 아티클 본문 + 이전/다음 네비게이터
  book.html     # 북 본문 + 이전/다음 네비게이터
build/
  build.pl      # 빌드 스크립트
docs/           # 빌드 결과물 (GitHub Pages 서빙) — 직접 수정 금지
```

## 빌드

`build/` 디렉토리에서 실행해야 한다.

```bash
cd build
perl build.pl
```

외부 의존성: `../../volken/lib` 의 `Volken::Mark` 모듈 (volken 저장소가 형제 디렉토리에 있어야 함).

## 콘텐츠 파일 형식 (Volken::Mark 마크업)

| 문법 | 결과 |
|------|------|
| `h2. 제목` | `<h2>` |
| `h3. 제목` | `<h3>` |
| `h5. 날짜` | `<h5>` |
| `- 항목` | `<ul><li>` |
| `| 텍스트` | `<blockquote>` |
| HTML 태그 | 그대로 출력 |

## 새 아티클 추가

1. `data/articles/` 에 다음 번호로 파일 생성 (예: `92.txt`)
2. 첫 줄: `h2. 제목`, 둘째 줄: `h5. MM/DD/YYYY` 형식 날짜
3. `build/` 에서 `perl build.pl` 실행
4. `docs/` 변경사항 확인 후 커밋

예시:
```
h2. 글 제목
h5. 04/04/2026

본문 내용...
```

## 새 북 추가

`data/articles/` 대신 `data/books/` 에 추가하는 것 외에 아티클과 동일.
현재 Books 메뉴는 `template/base.html` 에서 주석 처리되어 있음.

## 템플릿 플레이스홀더

`template/base.html` 과 각 템플릿에서 `____PLACEHOLDER____` 형식으로 치환됨.

| 플레이스홀더 | 내용 |
|-------------|------|
| `____TITLE____` | 페이지 제목 |
| `____MAIN____` | 본문 |
| `____SCRIPT____` | script.js 링크 |
| `____STYLESHEET____` | style.css 링크 |
| `____MENUINDEX____` | Home 메뉴 |
| `____MENUARTICLE____` | Articles 메뉴 (최신 글로 이동) |
| `____MENUSF____` | SF 메뉴 |
| `____MENUINFO____` | Info 메뉴 |
| `____MENUBOOK____` | Books 메뉴 (현재 주석 처리됨) |

`data/front.txt` 내에서는 `__ARTICLELINK__`, `__BOOKLINK__` 플레이스홀더도 사용 가능.

## 사이트 구조

- **Home** (`index.html`) — `data/front.txt` 로 생성
- **Articles** — `data/articles/번호.txt` 로 생성, 번호 역순으로 정렬 (최신이 첫 페이지)
- **SF** (`sf.html`) — `data/sf.txt` 로 생성
- **Info** (`info.html`) — `data/info.txt` 로 생성
- **Books** — `data/books/번호.txt` 로 생성 (메뉴 비활성화 상태)
