// https://www.codewars.com/kata/convert-a-string-to-an-array/train/javascript
function stringToArray(string) {
  // Розбити рядок на масив по роздільнику
  return string.split(" ");
}

// https://www.codewars.com/kata/dna-to-rna-conversion/train/javascript
function DNAtoRNA(dna) {
  // Заміна всіх символів "T" у рядку dna на "U"
  return dna.replaceAll("T", "U");
}

// Або
function DNAtoRNA(dna) {
  // Заміна всіх символів "T" у рядку dna на "U"
  return dna.replace(/T/g, "U");
}

// Додатковий варіант
function DNAtoRNA(dna) {
  // Розбиваємо рядок на масив частин, використовуючи символ "T" як роздільник -
  // замість "T" не буде нічого, замість "TТ" буде "" і так далі.
  // Об'єднуємо елементи масиву назад у рядок -
  // у місці з'єднання частин з'явиться "U", замість "" буде "UU" і так далі.
  return dna.split("T").join("U");
}

// Додатковий варіант
function DNAtoRNA(dna) {
  // Розбити рядок на масив символів
  // const dnaArray = dna.split("");
  // Повернути новий масив, замінивши "T" на "U"
  // const dnaReplace = dnaArray.map((el) => el.replace("T", "U"));
  // Масив символів об'єднати в рядок
  // return dnaReplace.join("");

  // Короткий запис
  return dna
    .split("")
    .map((el) => el.replace("T", "U"))
    .join("");
}

// Або
function DNAtoRNA(dna) {
  const result = [];
  for (char of dna) {
    result.push(char.replace("T", "U"));
  }
  return result.join("");
}

// https://www.codewars.com/kata/577a98a6ae28071780000989/train/javascript
// Find Maximum and Minimum Values of a List
var min = function (list) {
  return Math.min(...list);
};

var max = function (list) {
  return Math.max(...list);
};

// Додатковий варіант
var min = function (list) {
  return list.reduce((a, b) => (a < b ? a : b));
};

var max = function (list) {
  return list.reduce((a, b) => (a > b ? a : b));
};

// Або
var min = function (list) {
  return list.sort((a, b) => a - b)[0];
};

var max = function (list) {
  return list.sort((a, b) => b - a)[0];
  // Або
  // return list.sort((a, b) => a - b)[list.length-1];
};

// https://www.codewars.com/kata/544a54fd18b8e06d240005c0/train/javascript
function min(arr, toReturn) {
  const minValue = Math.min(...arr);
  return toReturn === "value" ? minValue : arr.indexOf(minValue);
}

// Або
function min(arr, toReturn) {
  return toReturn === "value"
    ? minValue = Math.min(...arr)
    : arr.indexOf(minValue);
}

// Double Integer    https://www.codewars.com/kata/53ee5429ba190077850011d4/train/javascript
function doubleInteger(i) {
  return i * 2;
}

// Twice as old    https://www.codewars.com/kata/5b853229cfde412a470000d0/train/javascript
function twiceAsOld(dadYearsOld, sonYearsOld) {
  // Math.abs гарантує, що відповідь буде завжди додатною
  return Math.abs(dadYearsOld - sonYearsOld * 2);
}

// Додатковий варіант
function twiceAsOld(dadYearsOld, sonYearsOld) {
  return dadYearsOld > 2 * sonYearsOld
    ? dadYearsOld - 2 * sonYearsOld
    : 2 * sonYearsOld - dadYearsOld;
}

// Return n-th even number    https://www.codewars.com/kata/5933a1f8552bc2750a0000ed/train/javascript
function nthEven(n) {
  return (n - 1) * 2;
}

// What's the real floor     https://www.codewars.com/kata/574b3b1599d8f897470018f6/train/javascript
function getRealFloor(n) {
  if (n <= 0) {
    return n;
  } else if (n < 13) {
    return n - 1;
  } 
  return n - 2;
}

// Додатковий варіант
function getRealFloor(n) {
  return n > 13 ? n - 2 : n - (n >= 1);
}

// Або
function getRealFloor(n) {
  if (n <= 0) {
    return n;
  }
  return n - (n >= 13 ? 2 : 1);
}

// Або
function getRealFloor(n) {
  return n > 13 ? n - 2 : n > 0 ? n - 1 : n;
}

// Clock    https://www.codewars.com/kata/55f9bca8ecaa9eac7100004a/train/javascript
function past(h, m, s) {
  return (h * 3600 + m * 60 + s) * 1000;
}

// Додатковий варіант 
function past(h, m, s) {
  return new Date(0).setHours(h, m, s) - new Date(0);
}

// Або
function past(h, m, s) {
  return new Date().setHours(h, m, s) - new Date().setHours(0, 0, 0);
}

// Is n divisible by x and y    https://www.codewars.com/kata/5545f109004975ea66000086/train/javascript
function isDivisible(n, x, y) {
  return n % x === 0 && n % y === 0;
}

// Або
function isDivisible(n, x, y) {
  return (n % x) + (n % y) === 0;
}
