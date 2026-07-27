document.addEventListener("DOMContentLoaded", () => {
  initDarkMode();
  initScrollProgress();
  initLightbox();
  initCodeCopyButtons();
  initGiscusComments(); // Giscus 댓글 마운트 기동
});

// ── 다크 모드 제어 ──
function initDarkMode() {
  const toggleBtn = document.getElementById("darkModeToggle");
  if (!toggleBtn) return;

  const currentTheme = localStorage.getItem("theme");
  const systemPrefersDark = window.matchMedia("(prefers-color-scheme: dark)").matches;

  // 초기 테마 설정 적용
  if (currentTheme === "dark" || (!currentTheme && systemPrefersDark)) {
    document.body.classList.add("dark-mode");
    document.body.classList.remove("light-mode");
    toggleBtn.textContent = "🌙";
  } else {
    document.body.classList.add("light-mode");
    document.body.classList.remove("dark-mode");
    toggleBtn.textContent = "☀️";
  }

  // 토글 버튼 클릭 이벤트
  toggleBtn.addEventListener("click", () => {
    if (document.body.classList.contains("dark-mode")) {
      document.body.classList.remove("dark-mode");
      document.body.classList.add("light-mode");
      toggleBtn.textContent = "☀️";
      localStorage.setItem("theme", "light");
      updateGiscusTheme("light"); // 실시간 Giscus 댓글 테마 갱신
    } else {
      document.body.classList.remove("light-mode");
      document.body.classList.add("dark-mode");
      toggleBtn.textContent = "🌙";
      localStorage.setItem("theme", "dark");
      updateGiscusTheme("dark"); // 실시간 Giscus 댓글 테마 갱신
    }
  });

  // 시스템 테마 변경 실시간 반영 (사용자가 수동 설정을 안 한 경우만)
  window.matchMedia("(prefers-color-scheme: dark)").addEventListener("change", (e) => {
    if (!localStorage.getItem("theme")) {
      if (e.matches) {
        document.body.classList.add("dark-mode");
        document.body.classList.remove("light-mode");
        toggleBtn.textContent = "🌙";
        updateGiscusTheme("dark");
      } else {
        document.body.classList.add("light-mode");
        document.body.classList.remove("dark-mode");
        toggleBtn.textContent = "☀️";
        updateGiscusTheme("light");
      }
    }
  });
}

// ── 스크롤 진행 바 ──
function initScrollProgress() {
  const progressBar = document.getElementById("scrollProgress");
  if (!progressBar) return;

  window.addEventListener("scroll", () => {
    const scrollTop = window.scrollY || document.documentElement.scrollTop;
    const scrollHeight = document.documentElement.scrollHeight - document.documentElement.clientHeight;
    const scrollPercentage = scrollHeight > 0 ? (scrollTop / scrollHeight) * 100 : 0;
    progressBar.style.width = scrollPercentage + "%";
  });
}

// ── 이미지 라이트박스 (모달 확대) ──
function initLightbox() {
  const images = document.querySelectorAll(".main img");
  const lightbox = document.getElementById("lightbox");
  if (!lightbox || images.length === 0) return;

  // 모달 내부 에셋 바인딩
  const lightboxImg = lightbox.querySelector(".lightbox-content");
  const lightboxClose = lightbox.querySelector(".lightbox-close");

  images.forEach(img => {
    // 앵커 링크나 아이콘 성격의 미니 이미지가 아닐 경우에만 바인딩
    if (img.width < 50 || img.height < 50) return;

    img.style.cursor = "zoom-in";
    img.addEventListener("click", () => {
      lightboxImg.src = img.src;
      lightboxImg.alt = img.alt || "Expanded Image";
      lightbox.classList.add("active");
      document.body.style.overflow = "hidden"; // 배경 스크롤 차단
    });
  });

  const closeLightbox = () => {
    lightbox.classList.remove("active");
    document.body.style.overflow = ""; // 배경 스크롤 복원
    setTimeout(() => {
      lightboxImg.src = ""; // 이미지 캐시 초기화
    }, 300);
  };

  // 닫기 클릭 바인딩
  lightboxClose.addEventListener("click", closeLightbox);
  lightbox.addEventListener("click", (e) => {
    // 확대 이미지 영역 자체가 아닌 바깥 레이어를 클릭했을 때 닫기
    if (e.target === lightbox || e.target.classList.contains("lightbox-overlay-wrapper")) {
      closeLightbox();
    }
  });

  // ESC 키 바인딩
  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape" && lightbox.classList.contains("active")) {
      closeLightbox();
    }
  });
}

// ── 코드 블록 "복사" 버튼 동적 생성 ──
function initCodeCopyButtons() {
  const codeBlocks = document.querySelectorAll(".article pre, .book pre");

  codeBlocks.forEach(pre => {
    // 이미 래퍼가 씌워져 있다면 중복 생성 방지
    if (pre.parentElement.classList.contains("code-block-wrapper")) return;

    // 래퍼 생성 및 구조 재정렬
    const wrapper = document.createElement("div");
    wrapper.className = "code-block-wrapper";
    pre.parentNode.insertBefore(wrapper, pre);
    wrapper.appendChild(pre);

    // 복사 버튼 동적 주입
    const copyBtn = document.createElement("button");
    copyBtn.className = "copy-button";
    copyBtn.textContent = "Copy";
    copyBtn.type = "button";
    wrapper.appendChild(copyBtn);

    // 클릭 리스너 연동
    copyBtn.addEventListener("click", () => {
      const codeText = pre.textContent;
      navigator.clipboard.writeText(codeText).then(() => {
        copyBtn.textContent = "Copied!";
        copyBtn.classList.add("copied");

        setTimeout(() => {
          copyBtn.textContent = "Copy";
          copyBtn.classList.remove("copied");
        }, 2000);
      }).catch(err => {
        console.error("복사 실패: ", err);
        copyBtn.textContent = "Error";
        setTimeout(() => {
          copyBtn.textContent = "Copy";
        }, 2000);
      });
    });
  });
}

// ── Giscus 댓글 동적 주입 및 실시간 다크모드 싱크 ──
function initGiscusComments() {
  const container = document.querySelector(".giscus");
  if (!container) return;

  const currentTheme = document.body.classList.contains("dark-mode") ? "noborder_dark" : "light";

  const giscusScript = document.createElement("script");
  giscusScript.src = "https://giscus.app/client.js";
  giscusScript.setAttribute("data-repo", "heetakchoi/heetakchoi.github.io");
  giscusScript.setAttribute("data-repo-id", "R_kgDONzKk-g"); // 임의의 repo ID를 적어두되, 사용자가 discussions를 활성화하면 바로 적용됩니다.
  giscusScript.setAttribute("data-category", "Announcements");
  giscusScript.setAttribute("data-category-id", "DIC_kwDONzKk-s4CmmZ0"); // 임의의 category ID
  giscusScript.setAttribute("data-mapping", "pathname");
  giscusScript.setAttribute("data-strict", "0");
  giscusScript.setAttribute("data-reactions-enabled", "1");
  giscusScript.setAttribute("data-emit-metadata", "0");
  giscusScript.setAttribute("data-input-position", "bottom");
  giscusScript.setAttribute("data-theme", giscusThemeMapping(currentTheme));
  giscusScript.setAttribute("data-lang", "ko");
  giscusScript.setAttribute("crossorigin", "anonymous");
  giscusScript.async = true;

  container.appendChild(giscusScript);
}

// Giscus 테마 세부 매핑 헬퍼
function giscusThemeMapping(theme) {
  return theme === "dark" || theme === "noborder_dark" ? "noborder_dark" : "light";
}

// 실시간 테마 토글 메시지 전달 (화면 무리프레시 갱신)
function updateGiscusTheme(theme) {
  const iframe = document.querySelector("iframe.giscus-frame");
  if (!iframe) return;

  const giscusTheme = giscusThemeMapping(theme);
  iframe.contentWindow.postMessage(
    { giscus: { setConfig: { theme: giscusTheme } } },
    "https://giscus.app"
  );
}
