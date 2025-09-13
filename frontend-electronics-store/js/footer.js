const clockContainer = document.querySelector(".reward-line__clock");
function updateClock() {
    clockContainer.innerText = new Date().toLocaleTimeString("uk");
}

setInterval(updateClock, 1000);
