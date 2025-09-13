function init() {
  import('./header.js');
  import('./index.hero.js');
  import('./index.deals.js');
  import('./footer.js');
  import('./index.categories.js');
  import('./scroll-to-top.js');
  import('./swiper.js');
}

const totalPartials = document.querySelectorAll(
  '[hx-trigger="load"], [data-hx-trigger="load"]'
).length;
let loadedPartialsCount = 0;

document.body.addEventListener('htmx:afterOnLoad', () => {
  loadedPartialsCount++;
  if (loadedPartialsCount === totalPartials) init();
});
