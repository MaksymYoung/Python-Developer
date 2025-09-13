const form = document.querySelector(".faq__form"); 
const result = document.createElement("div"); 
result.id = "contact-form-result"; 
form.parentNode.insertBefore(result, form.nextSibling); 

form.addEventListener("submit", async function (e) {
  e.preventDefault(); 
  const formData = new FormData(form); 
  const object = Object.fromEntries(formData); 
  const json = JSON.stringify(object); 

//   result.innerHTML = "Please wait..."; 
//   result.style.display = "block"; 
//   try {
    const response = await fetch("https://api.web3forms.com/submit", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
      },
      body: json, 
    });

//     if (response.status === 200) {
//       result.innerHTML = "Form submitted successfully"; 
//     } else {
//       result.innerHTML = "Error submitting the form"; 
//     }
//   } catch (error) {
//     result.innerHTML = "An error occurred. Please try again."; 
//   }

//   form.reset(); 
//   setTimeout(() => (result.style.display = "none"), 3000); 
});