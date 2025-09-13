const scrollToTopBtn = document.querySelector('.scroll-to-top');

window.addEventListener('scroll', () => {
  if (window.scrollY > 1500) {
    scrollToTopBtn.classList.add('scroll-to-top--visible');
  } else {
    scrollToTopBtn.classList.remove('scroll-to-top--visible');
  }
});

scrollToTopBtn.addEventListener('click', () => {
  window.scrollTo({
    top: 0,
    behavior: 'smooth',
  });
});
