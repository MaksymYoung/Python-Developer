const response = await fetch('api/vacancies.json');
const vacancies = await response.json();

function renderVacanciesCards(){
    let htmlCards = '';
    for(const vacancy of vacancies){
        htmlCards += `
        <article class="job-opportunities__card">
        <div class="job-opportunities__card-header">
          <div class="job-opportunities__title-container">
            <h3 class="job-opportunities__card-title">
                ${vacancy.jobTitle}
            </h3>
          </div>
          <div class="job-opportunities__meta-container">
            <p class="job-opportunities__meta">
              ${vacancy.employmentType} | ${vacancy.experienceRequired}
            </p>
          </div>
          <div class="job-opportunities__logo-block">
            <img
              id="job-opportunities__logo"
              src=${vacancy.companyLogo}
              alt=${vacancy.logoDescription}
              ,
              width="70"
            />
            <div class="job-opportunities__sallary">
              <strong class="job-opportunities__sallary-amount">${vacancy.salary}</strong>
              / ${vacancy.salaryPeriod}
              <p class="job-opportunities__office-location">
                ${vacancy.officeLocation}
              </p>
            </div>
          </div>
        </div>
        <div class="job-opportunities__card-middle-section">
          <div class="job-opportunities__description">
            <p>
              ${vacancy.vacancieDescription}
            </p>
          </div>
          <ul class="job-opportunities__responsibilities">
            <li class="job-opportunities__responsibility">
              ${vacancy.responsibilities[0]};
            </li>
            <li class="job-opportunities__responsibility">
              ${vacancy.responsibilities[1]};
            </li>
            <li class="job-opportunities__responsibility">
              ${vacancy.responsibilities[2]};
            </li>
            <li class="job-opportunities__responsibility">
              ${vacancy.responsibilities[3]};
            </li>
          </ul>
        </div>
        <div class="job-opportunities__benefits-lists">
          <ul class="job-opportunities__benefits-list">
            <li class="job-opportunities__benefit">
              <img
                src=${vacancy.benefitIcon}
                alt="checked box"
                height="20"
                width="24"
              />
              <p>${vacancy.benefits[0]};</p>
            </li>
            <li class="job-opportunities__benefit">
              <img
                src=${vacancy.benefitIcon}
                alt="checked box"
                height="20"
                width="24"
              />
              <p>${vacancy.benefits[1]};</p>
            </li>
            <li class="job-opportunities__benefit">
              <img
                src=${vacancy.benefitIcon}
                alt="checked box"
                height="20"
                width="24"
              />
              <p>${vacancy.benefits[2]};</p>
            </li>
            <li class="job-opportunities__benefit">
              <img
                src=${vacancy.benefitIcon}
                alt="checked box"
                height="20"
                width="24"
              />
              <p>${vacancy.benefits[3]};</p>
            </li>
            <li class="job-opportunities__benefit">
              <img
                src=${vacancy.benefitIcon}
                alt="checked box"
                height="20"
                width="24"
              />
              <p>${vacancy.benefits[4]}.</p>
            </li>
          </ul>
        </div>
      </article>
        `
    }
    const vacanciesContainer = document.querySelector('.job-opportunities__vacancies');
    vacanciesContainer.innerHTML = htmlCards;
}

renderVacanciesCards(vacancies);