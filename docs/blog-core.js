document.addEventListener("DOMContentLoaded", () => {
  initDarkMode();
  initScrollProgress();
  initLightbox();
  initCodeCopyButtons();
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
    } else {
      document.body.classList.remove("light-mode");
      document.body.classList.add("dark-mode");
      toggleBtn.textContent = "🌙";
      localStorage.setItem("theme", "dark");
    }
  });

  // 시스템 테마 변경 실시간 반영 (사용자가 수동 설정을 안 한 경우만)
  window.matchMedia("(prefers-color-scheme: dark)").addEventListener("change", (e) => {
    if (!localStorage.getItem("theme")) {
      if (e.matches) {
        document.body.classList.add("dark-mode");
        document.body.classList.remove("light-mode");
        toggleBtn.textContent = "🌙";
      } else {
        document.body.classList.add("light-mode");
        document.body.classList.remove("dark-mode");
        toggleBtn.textContent = "☀️";
      }
    }
  });
}

// ── 스크롤 진행 바 ──
function initScrollProgress() {
  const progressBar = document.getElementById("scrollProgress");
  if (!progressBar) return;

  window.addEventListener("scroll", () => {
    const winScroll = document.body.scrollTop || document.documentElement.scrollTop;
    const height = document.documentElement.scrollHeight - document.documentElement.clientHeight;
    const scrolled = height > 0 ? (winScroll / height) * 100 : 0;
    progressBar.style.width = scrolled + "%";
  });
}

// ── 인라인 라이트박스 뷰어 ──
function initLightbox() {
  const lightbox = document.getElementById("lightbox");
  const lightboxImg = document.getElementById("lightboxImg");
  const lightboxClose = document.getElementById("lightboxClose");
  if (!lightbox || !lightboxImg) return;

  // 본문 이미지 목록 추출 (라이트박스 자신 내부 이미지 제외)
  const images = document.querySelectorAll(".main img");
  
  images.forEach(img => {
    img.addEventListener("click", () => {
      lightboxImg.src = img.src;
      lightbox.classList.add("active");
      document.body.style.overflow = "hidden"; // 배경 스크롤 차단
    });
  });

  // 닫기 로직 (버튼 클릭, 배경 오버레이 클릭, ESC 키)
  const closeLightbox = () => {
    lightbox.classList.remove("active");
    document.body.style.overflow = ""; // 배경 스크롤 허용
    setTimeout(() => { lightboxImg.src = ""; }, 300); // 부드러운 페이드아웃 완료 후 소스 초기화
  };

  lightboxClose.addEventListener("click", closeLightbox);
  lightbox.addEventListener("click", (e) => {
    if (e.target === lightbox || e.target === lightboxClose) {
      closeLightbox();
    }
  });

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
