document
  .querySelector(".hero__button-shop-now")
  .addEventListener("click", function (event) {
    event.preventDefault();
    const target = document.querySelector("#product-gallery");
    target.scrollIntoView({ behavior: "smooth" });
  });

document
  .querySelector(".hero__button-secondary")
  .addEventListener("click", function (event) {
    event.preventDefault();
    const target = document.querySelector("#latest_products");
    target.scrollIntoView({ behavior: "smooth" });
  });
