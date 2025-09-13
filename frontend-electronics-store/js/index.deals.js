// Halyna Fedkiv
function startCountdown(id, targetDate) {
  const countdownEl = document.getElementById(id);

  const daysEl = countdownEl.querySelector(".countdown-days");
  const hoursEl = countdownEl.querySelector(".countdown-hours");
  const minutesEl = countdownEl.querySelector(".countdown-minutes");
  const secondsEl = countdownEl.querySelector(".countdown-seconds");

  function updateCountdown() {
    const now = new Date();
    const diff = new Date(targetDate) - now;

    if (diff <= 0) {
      daysEl.textContent = "00";
      hoursEl.textContent = "00";
      minutesEl.textContent = "00";
      secondsEl.textContent = "00";
      return;
    }

    const days = Math.floor(diff / (1000 * 60 * 60 * 24));
    const hours = Math.floor((diff / (1000 * 60 * 60)) % 24);
    const minutes = Math.floor((diff / (1000 * 60)) % 60);
    const seconds = Math.floor((diff / 1000) % 60);

    daysEl.textContent = days.toString().padStart(2, "0");
    hoursEl.textContent = hours.toString().padStart(2, "0");
    minutesEl.textContent = minutes.toString().padStart(2, "0");
    secondsEl.textContent = seconds.toString().padStart(2, "0");
  }

  updateCountdown();
  setInterval(updateCountdown, 1000);
}

// Initialize multiple countdowns with different IDs and target dates
startCountdown("deals__countdown-headphones", "2025-01-31T23:59:59");
startCountdown("deals__countdown-keyboards", "2025-02-13T00:00:00");
startCountdown("filters__countdown", "2025-02-13T00:00:00");
