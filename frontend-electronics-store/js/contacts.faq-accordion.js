const faqQuestions = document.querySelectorAll(".faq__question");

faqQuestions.forEach((question) => {
  question.addEventListener("click", function () {
    this.classList.toggle("active");
    const answer = this.nextElementSibling;

    if (answer.style.maxHeight) {
      answer.style.maxHeight = null;
    } else {
      answer.style.maxHeight = answer.scrollHeight + "px"; 
    }

    faqQuestions.forEach((otherQuestion) => {
      if (otherQuestion !== question) {
        otherQuestion.classList.remove("active");
        otherQuestion.nextElementSibling.style.maxHeight = null;
      }
    });
  });
});

