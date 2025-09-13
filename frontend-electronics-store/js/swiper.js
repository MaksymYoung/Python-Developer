// Ініціалізація Swiper
document.addEventListener("DOMContentLoaded", function () {
  var swiper = new Swiper('.swiper', {
      slidesPerView: getSlidesPerView(),
      spaceBetween: 15,
      loop: true,
      navigation: {
          nextEl: '.swiper-button-next',
          prevEl: '.swiper-button-prev',
      },
      breakpoints: {
          1470: { slidesPerView: 7, spaceBetween: 10 },
          1150: { slidesPerView: 5, spaceBetween: 10 },
          900: { slidesPerView: 4, spaceBetween: 10 },
          700: { slidesPerView: 3, spaceBetween: 10 },
          500: { slidesPerView: 2, spaceBetween: 10 },
          0: { slidesPerView: 1, spaceBetween: 10 }
      }
  });

  // Функція для визначення кількості слайдів
  function getSlidesPerView() {
      let width = window.innerWidth;
      if (width >= 1470) return 7;
      if (width >= 1150) return 5;
      if (width >= 900) return 4;
      if (width >= 700) return 3;
      if (width >= 500) return 2;
      return 1;
  }

  // Оновлення параметрів при зміні розміру екрану
  window.addEventListener('resize', function () {
      swiper.params.slidesPerView = getSlidesPerView();
      swiper.update();
  });
});
