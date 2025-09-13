const burgerIcon = document.querySelector('.burger');
const mobileMenuBox = document.querySelector('.header__mobile-menu');
const mobileMenuLinks = mobileMenuBox.querySelectorAll("a");

function toggleMenuElements() {
  document.body.classList.toggle('overflow-hidden');
  document.querySelector('html').classList.toggle('overflow-hidden');
  burgerIcon.classList.toggle('burger--open');
  mobileMenuBox.classList.toggle('header__mobile-menu--open');
}

burgerIcon.addEventListener('click', () => {
  toggleMenuElements();
});

mobileMenuLinks.forEach((link) => {
  link.addEventListener('click', () => {
    toggleMenuElements();
  });
});
