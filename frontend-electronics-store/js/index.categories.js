/* Максим Зимин */

/* Об'єкт стану фільтрації товарів */
const filterState = {
  category: "all",
  priceRange: { min: 32.0, max: 225.99 },
  colors: new Set(),
  connections: new Set(),
  screenSizes: new Set(),
};

/* Функція для отримання товарів з JSON-файлу */
async function fetchcards() {
  try {
    const response = await fetch("./api/cards.json");
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    const data = await response.json();
    return data.cards;
  } catch (error) {
    console.error("Error loading cards:", error);
    return [];
  }
}

/* Функція для відображення товарів на сторінці */
function rendercards(cards) {
  // Знаходимо контейнер, де будуть відображатись картки товарів
  const cardsContainer = document.querySelector(".cards");

  // Очищаємо контейнер, щоб уникнути дублювання карток при повторному виклику функції
  cardsContainer.innerHTML = "";

  // Перебираємо кожну картку з масиву "cards"
  cards.forEach((card) => {
    // Створюємо новий елемент <article> для кожної картки
    const cardElement = document.createElement("article");

    // Додаємо клас "card" до кожної картки, якщо картка має промо-мітку (promoLabel), додаємо ще клас "card--promo"
    cardElement.className = `card${
      card.promoLabel ? " card--promo" : "" // Перевірка на наявність промо-мітки
    }`;

    // Встановлюємо внутрішній HTML для кожної картки
    // Якщо картка має промо-мітку, показуємо її
    cardElement.innerHTML = `
        <div class="card__image-container">          
          ${
            card.promoLabel
              ? `<span class="card__label">${card.promoLabel}</span>` 
              : "" 
          }          
          <img
            src="${card.image}" 
            alt="${card.name}"   
            class="card__image" 
          />
        </div>
        
        <div class="card__info">
          <h2 class="card__name">
            <a href="#" class="card__name-link">${
              card.name
            }</a> 
          </h2>
          
          <div class="card__price-container">
            ${
              card.oldPrice
                ? `<p class="card__price card__price--old">$${card.oldPrice.toFixed(
                    2
                  )} USD</p>` 
                : "" 
            }
            
            <!-- Поточна ціна товару -->
            <p class="card__price">$${card.price.toFixed(
              2
            )} USD</p> 
          </div>
          <button class="card__button card__button--cart">Buy Now</button>
        </div>
    `;

    // Додаємо створену картку в контейнер карток на сторінці
    cardsContainer.appendChild(cardElement);
  });
}

/* Отримати відфільтровані картки на основі поточного стану фільтрації */
function getFilteredcards() {
  // Викликаємо функцію filtercards, передаючи масив карток, які зберігаються в window.cards або порожній масив, якщо їх немає
  // Масив карток (cards) зберігається в глобальному об'єкті window.
  // Це дозволяє зробити ці картки доступними з будь-якої точки на сторінці,
  // навіть якщо вони були завантажені асинхронно
  return filtercards(window.cards || []);
}

/* Фільтрує картки за поточним станом фільтрів */
function filtercards(cards) {
  return cards.filter((card) => {
    // Перевірка категорії картки. Якщо категорія не "all" (усі), то перевіряємо 
    // чи співпадає категорія картки з поточною
    if (
      filterState.category !== "all" &&
      card.category.toLowerCase() !== filterState.category.toLowerCase()
    ) {
      return false; // Якщо категорії не співпадають, виключаємо картку
    }

    // Перевірка ціни картки. Якщо ціна картки поза діапазоном встановлених меж, виключаємо картку
    if (
      card.price < filterState.priceRange.min ||
      card.price > filterState.priceRange.max
    ) {
      return false; // Якщо ціна картки не в межах фільтрації, виключаємо її
    }

    // Перевірка кольорів картки. Якщо фільтри містять кольори, то перевіряємо, 
    // чи є хоча б один колір картки в фільтрі
    if (
      filterState.colors.size > 0 &&
      !card.colors.some((color) => filterState.colors.has(color.toLowerCase()))
    ) {
      return false; // Якщо немає жодного кольору, який є в фільтрі, виключаємо картку
    }

    // Перевірка з'єднань картки. Якщо фільтри містять з'єднання, то перевіряємо, 
    // чи є хоча б одне з'єднання картки в фільтрі
    if (
      filterState.connections.size > 0 &&
      !card.connections.some((conn) =>
        filterState.connections.has(conn.toLowerCase())
      )
    ) {
      return false; // Якщо немає жодного з'єднання, яке є в фільтрі, виключаємо картку
    }

    // Перевірка розміру екрану картки. Якщо фільтри містять певні розміри екрана, перевіряємо 
    // чи містить картка необхідний розмір
    if (
      filterState.screenSizes.size > 0 &&
      !filterState.screenSizes.has(String(card.screenSize))
    ) {
      return false; // Якщо розмір екрану картки не підходить під фільтри, виключаємо її
    }

    // Якщо жоден з фільтрів не виключив картку, повертаємо її
    return true;
  });
}

/* Оновлює відображення карток на основі поточного стану фільтрів */
function updatecards(cards) {
  // Отримуємо відфільтровані картки за допомогою функції filtercards
  const filteredcards = filtercards(cards);

  // Відображаємо відфільтровані картки на сторінці
  rendercards(filteredcards);

  // Знаходимо кнопку "Apply filters" для оновлення тексту
  const applyButton = document.querySelector(".filters__apply-button");
  if (applyButton) {
    // Оновлюємо текст кнопки, вказуючи кількість карток після фільтрації
    applyButton.textContent = `Apply filters: ${filteredcards.length}`;
  }
}

/* Скидає всі фільтри до початкового стану */
function resetFilters() {
  // Відновлюємо значення фільтрів до їх початкових значень
  filterState.category = "all";

  // Очищаємо вибір кольорів, з'єднань і розмірів екранів
  filterState.colors.clear();
  filterState.connections.clear();
  filterState.screenSizes.clear();

  // Визначаємо мінімальні і максимальні ціни на основі карток у window.cards
  const prices = window.cards.map((p) => p.price);
  filterState.priceRange = {
    min: Math.min(...prices), // Мінімальна ціна
    max: Math.max(...prices), // Максимальна ціна
  };

  // Скидаємо всі чекбокси фільтрів до значення "unchecked"
  document
    .querySelectorAll('.filters__option input[type="checkbox"]')
    .forEach((checkbox) => (checkbox.checked = false));

  // Оновлюємо значення інпутів для цінового діапазону
  const rangeInputs = document.querySelectorAll(".filters__range-input");
  if (rangeInputs.length >= 2) {
    // Встановлюємо мінімальну і максимальну ціни в інпути
    rangeInputs[0].value = filterState.priceRange.min;
    rangeInputs[1].value = filterState.priceRange.max;

    // Оновлюємо відображення значень діапазону ціни на сторінці
    const rangeValues = document.querySelectorAll(".filters__range-value");
    if (rangeValues.length >= 2) {
      // Встановлюємо відображення мінімальної і максимальної ціни
      rangeValues[0].textContent = filterState.priceRange.min.toFixed(2);
      rangeValues[1].textContent = filterState.priceRange.max.toFixed(2);
    }
  }

  // Скидаємо всі активні опції фільтрів категорії
  document
    .querySelectorAll('.filters__option[data-filter="category"]')
    .forEach((option) => option.classList.remove("filters__option--active"));

  // Знаходимо опцію "всі категорії" і додаємо клас для позначення активної
  const allCategoryOption = document.querySelector(
    '.filters__option[data-value="all"]'
  );
  if (allCategoryOption) {
    // Додаємо клас активної опції для "всі категорії"
    allCategoryOption.classList.add("filters__option--active");
  }

  // Оновлюємо відображення карток після скидання фільтрів
  updatecards(window.cards);
}

/**
 * Створює HTML-код для групи фільтрів
 * @param {string} title - Назва групи фільтрів
 * @param {string} content - Контент для групи фільтрів
 * @returns {string} - HTML-код для групи фільтрів
 */
function createFilterGroup(title, content) {
  // Формуємо HTML для групи фільтрів з вказаною назвою і контентом
  return `
    <div class="filters__group">
      <div class="accordion__button">
        <span class="accordion__button-text">${title}</span>
        <img src="./img/categories-aside/arrow.svg" alt="Arrow" class="accordion__arrow" />
      </div>
      <div class="accordion__content">
        ${content}
      </div>
    </div>
  `;
}

/**
 * Створює HTML-код для групи опцій фільтра
 * @param {Array} options - Масив опцій для фільтра
 * @param {string} filterType - Тип фільтра
 * @param {boolean} isCheckbox - Чи використовувати чекбокси (за замовчуванням true)
 * @returns {string} - HTML-код для групи опцій фільтра
 */
function createOptionsGroup(options, filterType, isCheckbox = true) {
  // Перетворюємо масив опцій на HTML-код
  const optionsHTML = options
    .map((option) => {
      // Якщо isCheckbox true, створюємо чекбокс для кожної опції
      if (isCheckbox) {
        return ` 
        <div class="filters__option">
          <label class="filters__option-label">
            <input type="checkbox" data-filter="${filterType}" value="${option.toLowerCase()}" /> ${option}
          </label>
        </div>
      `;
      }

      // Якщо isCheckbox false, створюємо інший тип елементу (наприклад, <p>) для опції
      return ` 
      <div class="filters__option" data-filter="${filterType}" data-value="${option.toLowerCase()}">
        <p class="filters__option-label">${option}</p>
      </div>
    `;
    })
    .join(""); // Об'єднуємо всі елементи в одну строку

  // Повертаємо HTML для групи опцій
  return `<div class="filters__option-group">${optionsHTML}</div>`;
}

/**
 * Створює HTML-код для діапазону цін
 * @param {number} minPrice - Мінімальна ціна
 * @param {number} maxPrice - Максимальна ціна
 * @returns {string} - HTML-код для діапазону цін
 */
function createPriceRange(minPrice, maxPrice) {
  // Формуємо HTML для діапазону цін
  return `
    <div class="filters__range">
      <div class="filters__range-slider">
        <div class="filters__range-progress"></div>
        
        <div class="filters__range-inputs">
          <input
            type="range"
            class="filters__range-input filters__range-input--min"
            min="${minPrice}"   
            max="${maxPrice}"  
            value="${minPrice}" 
            step="1"      
          />

          <input
            type="range"
            class="filters__range-input filters__range-input--max"
            min="${minPrice}"  
            max="${maxPrice}"
            value="${maxPrice}"
            step="1"         
          />
        </div>
      </div>

      <div class="filters__range-values">
        <div class="filters__range-value">$${minPrice.toFixed(
          2
        )}</div>   
        <div class="filters__range-dash">-</div>                         
        <div class="filters__range-value">$${maxPrice.toFixed(
          2
        )}</div>  
      </div>
    </div>
  `;
}

/**
 * Ініціалізує функціональність слайдера діапазону цін
 */
function initializeRangeSlider() {
  // Отримуємо елементи слайдерів мінімальної і максимальної ціни
  const rangeMin = document.querySelector(".filters__range-input--min");
  const rangeMax = document.querySelector(".filters__range-input--max");
  // Отримуємо елемент для прогресу між слайдерами
  const progress = document.querySelector(".filters__range-progress");
  // Отримуємо елементи для відображення мінімального і максимального значення
  const valueMin = document.querySelector(
    ".filters__range-values .filters__range-value:first-child"
  );
  const valueMax = document.querySelector(
    ".filters__range-values .filters__range-value:last-child"
  );

  // Якщо не вдалося знайти всі елементи, виводимо повідомлення про помилку
  if (!rangeMin || !rangeMax || !progress || !valueMin || !valueMax) {
    console.log("Range slider elements not found");
    return;
  }

  // Функція для оновлення прогресу слайдера і відображення значень
  function updateProgress() {
    // Отримуємо значення слайдерів
    const min = parseInt(rangeMin.value);
    const max = parseInt(rangeMax.value);

    // Обчислюємо відсоткове значення для мінімального і максимального слайдера
    const minPercent =
      ((min - rangeMin.min) / (rangeMin.max - rangeMin.min)) * 100;
    const maxPercent =
      ((max - rangeMax.min) / (rangeMax.max - rangeMax.min)) * 100;

    // Оновлюємо стилі прогресу між слайдерами
    progress.style.left = `${minPercent}%`;
    progress.style.width = `${maxPercent - minPercent}%`;

    // Оновлюємо текстові значення мінімальної і максимальної ціни
    valueMin.textContent = `$${min.toFixed(2)}`;
    valueMax.textContent = `$${max.toFixed(2)}`;

    // Оновлюємо стан фільтру з новими значеннями діапазону цін
    filterState.priceRange.min = min;
    filterState.priceRange.max = max;
  }

  // Слухач події для мінімального слайдера
  rangeMin.addEventListener("input", (e) => {
    const minVal = parseInt(rangeMin.value);
    const maxVal = parseInt(rangeMax.value);

    // Перевірка: якщо мінімальна ціна більша за максимальну, обмежуємо мінімальну ціну
    if (maxVal - minVal < 0) {
      rangeMin.value = maxVal;
    }
    // Оновлюємо слайдер та картки
    updateProgress();
    updatecards(window.cards);
  });

  // Слухач події для максимального слайдера
  rangeMax.addEventListener("input", (e) => {
    const minVal = parseInt(rangeMin.value);
    const maxVal = parseInt(rangeMax.value);

    // Перевірка: якщо максимальна ціна менша за мінімальну, обмежуємо максимальну ціну
    if (maxVal - minVal < 0) {
      rangeMax.value = minVal;
    }
    // Оновлюємо слайдер та картки
    updateProgress();
    updatecards(window.cards);
  });

  // Ініціалізація прогресу слайдера при завантаженні
  updateProgress();
}

function initializeAccordion() {
  // Отримуємо всі кнопки акардіону
  const accordionButtons = document.querySelectorAll(".accordion__button");

  // Для кожної кнопки додаємо обробник події
  accordionButtons.forEach((button) => {
    button.addEventListener("click", function () {
      // Перемикаємо клас для активного елементу
      this.classList.toggle("accordion__button--active");

      // Отримуємо наступний елемент (вміст)
      const content = this.nextElementSibling;

      // Змінюємо maxHeight для анімації відкриття/закриття вмісту
      content.style.maxHeight = content.style.maxHeight
        ? null // Якщо maxHeight вже встановлений, видаляємо його
        : content.scrollHeight + "px"; // Встановлюємо висоту для показу вмісту
    });
  });
}

/**
 * Ініціалізація обробників фільтрів
 * @param {Array} cards - Масив карток, які відображаються
 */
function initializeFilterHandlers(cards) {
  // Отримуємо всі опції фільтрації за категорією
  const categoryOptions = document.querySelectorAll(
    '.filters__option[data-filter="category"]'
  );

  // Додаємо обробник події на кожну категорію
  categoryOptions.forEach((option) => {
    option.addEventListener("click", () => {
      // Видаляємо активний клас з усіх категорій
      categoryOptions.forEach((opt) =>
        opt.classList.remove("filters__option--active")
      );

      // Додаємо активний клас до вибраної категорії
      option.classList.add("filters__option--active");

      // Оновлюємо стан фільтра
      filterState.category = option.dataset.value;

      // Оновлюємо картки за новими фільтрами
      updatecards(cards);
    });
  });

  // Ініціалізація обробників для ползунків діапазону (ціна)
  const rangeInputs = document.querySelectorAll(".filters__range-input");
  rangeInputs.forEach((input) => {
    input.addEventListener("input", (e) => {
      const type = e.target.dataset.rangeType; // Тип діапазону (min або max)
      const value = parseFloat(e.target.value); // Значення діапазону
      filterState.priceRange[type] = value; // Оновлюємо значення в стані фільтра
      updatecards(cards); // Оновлюємо картки за новими фільтрами
    });
  });

  // Ініціалізація обробників для чекбоксів
  const checkboxes = document.querySelectorAll('input[type="checkbox"]');
  checkboxes.forEach((checkbox) => {
    checkbox.addEventListener("change", (e) => {
      const filterType = e.target.dataset.filter; // Тип фільтра
      const value = e.target.value; // Значення, яке вибрано в чекбоксі
      // Якщо чекбокс вибраний, додаємо значення в множину, якщо знятий - видаляємо
      if (e.target.checked) {
        filterState[filterType].add(value);
      } else {
        filterState[filterType].delete(value);
      }
      updatecards(cards); // Оновлюємо картки за новими фільтрами
    });
  });
}

/**
 * Генерація фільтрів на основі карток
 * @param {Array} cards - Масив карток
 */
function generateFilters(cards) {
  // Отримуємо контейнер для фільтрів
  const filtersContainer = document.querySelector(".filters__content");

  // Визначаємо мінімальну та максимальну ціну для фільтра ціни
  const prices = cards.map((p) => p.price);
  filterState.priceRange = {
    min: Math.min(...prices),
    max: Math.max(...prices),
  };

  // Визначаємо доступні категорії та кольори
  const categories = ["All", ...new Set(cards.map((p) => p.category))];
  const colors = [...new Set(cards.flatMap((p) => p.colors))];
  const connections = [...new Set(cards.flatMap((p) => p.connections))];

  // Генерація фільтру за категоріями
  const categoriesFilter = createFilterGroup(
    "Category",
    createOptionsGroup(
      categories.map((c) => c.charAt(0).toUpperCase() + c.slice(1)),
      "category",
      false
    )
  );

  // Генерація фільтру за ціною
  const priceFilter = createFilterGroup(
    "Price",
    createPriceRange(filterState.priceRange.min, filterState.priceRange.max)
  );

  // Генерація фільтру за кольором
  const colorsFilter = createFilterGroup(
    "Color",
    createOptionsGroup(
      colors.map((c) => c.charAt(0).toUpperCase() + c.slice(1)),
      "colors"
    )
  );

  // Генерація фільтру за з'єднаннями
  const connectionsFilter = createFilterGroup(
    "Connection",
    createOptionsGroup(
      connections.map((c) => c.charAt(0).toUpperCase() + c.slice(1)),
      "connections"
    )
  );

  // Генерація фільтру за розміром екрану для моніторів
  let screenSizesFilter = "";
  const monitors = cards.filter((p) => p.category === "monitors");
  if (monitors.length > 0) {
    const screenSizes = [...new Set(monitors.map((p) => p.screenSize))].sort(
      (a, b) => a - b
    );
    screenSizesFilter = createFilterGroup(
      "Screen Size",
      createOptionsGroup(
        screenSizes.map((size) => `${size}"`),
        "screenSizes"
      )
    );
  }

  // Додаємо всі фільтри в контейнер
  filtersContainer.innerHTML =
    categoriesFilter +
    priceFilter +
    colorsFilter +
    connectionsFilter +
    screenSizesFilter;

  // Ініціалізуємо додаткові елементи (повзунок, акардіон)
  initializeRangeSlider();
  initializeAccordion();
  initializeFilterHandlers(cards);
}

/**
 * Ініціалізація обробників для мобільної бічної панелі фільтрів
 */
function initializeMobileSidebar() {
  // Отримуємо елементи для мобільної панелі
  const filterToggle = document.getElementById("filtersToggle");
  const filtersSidebar = document.getElementById("filtersSidebar");
  const filtersClose = document.getElementById("filtersClose");
  const applyButton = document.querySelector(".filters__apply-button");
  const clearButton = document.querySelector(".filters__clear-button");

  // Обробник для кнопки відкриття бічної панелі
  if (filterToggle && filtersSidebar) {
    filterToggle.addEventListener("click", function () {
      filtersSidebar.classList.add("filters--open");
      document.body.classList.add("no-scroll");
    });
  }

  // Обробник для кнопки закриття бічної панелі
  if (filtersClose) {
    filtersClose.addEventListener("click", function () {
      filtersSidebar.classList.remove("filters--open");
      document.body.classList.remove("no-scroll");
    });
  }

  // Обробник для кнопки застосування фільтрів
  if (applyButton) {
    applyButton.addEventListener("click", () => {
      filtersSidebar.classList.remove("filters--open");
      document.body.classList.remove("no-scroll");
    });
  }

  // Обробник для кнопки очищення фільтрів
  if (clearButton) {
    clearButton.addEventListener("click", resetFilters);
  }
}

/**
 * Ініціалізація всього
 */
async function initialize() {
  // Отримуємо картки з даними
  const cards = await fetchcards();

  // Зберігаємо картки в глобальній змінній
  window.cards = cards;

  // Відображаємо картки
  rendercards(cards);

  // Генеруємо фільтри на основі карток
  generateFilters(cards);

  // Ініціалізуємо мобільну панель
  initializeMobileSidebar();

  // Оновлюємо текст кнопки застосування фільтрів
  const applyButton = document.querySelector(".filters__apply-button");
  if (applyButton) {
    applyButton.textContent = `Apply filters: ${cards.length}`;
  }
}

// Викликаємо ініціалізацію
initialize();
