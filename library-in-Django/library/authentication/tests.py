import os
import time
import logging
import django
from selenium import webdriver
from selenium.common.exceptions import TimeoutException
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait
from django.test import LiveServerTestCase

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "library.settings")
django.setup()

from .models import CustomUser

logger = logging.getLogger("LoginTests")
logger.setLevel(logging.INFO)
handler = logging.StreamHandler()
formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
handler.setFormatter(formatter)
if not logger.hasHandlers():
    logger.addHandler(handler)


class WaitSeconds:
    def __init__(self, seconds):
        self.seconds = seconds

    def __call__(self, driver):
        time.sleep(self.seconds)
        return True

class SeleniumLoginTests(LiveServerTestCase):
    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        cls.driver = webdriver.Chrome()
        cls.driver.maximize_window()
        cls.wait = WebDriverWait(cls.driver, 10)

    @classmethod
    def tearDownClass(cls):
        cls.driver.quit()
        super().tearDownClass()

    def setUp(self):
        self.valid_email = "testmax@example.com"
        self.valid_password = "testpass123"
        self.user, created = CustomUser.objects.get_or_create(
            email=self.valid_email,
            defaults={
                "first_name": "Test",
                "last_name": "User",
                "is_active": True,
            }
        )
        if created:
            self.user.set_password(self.valid_password)
            self.user.save()

    def test_login_and_logout(self):
        self.driver.get(self.live_server_url + "/login")

        email_input = self.wait.until(EC.presence_of_element_located((By.NAME, "email")))
        password_input = self.wait.until(EC.presence_of_element_located((By.NAME, "password")))

        email_input.clear()
        password_input.clear()

        email_input.send_keys(self.valid_email)
        password_input.send_keys(self.valid_password)

        login_submit = self.wait.until(EC.element_to_be_clickable((By.CSS_SELECTOR, "button[type='submit']")))
        login_submit.click()

        try:
            self.wait.until(EC.presence_of_element_located((By.XPATH, "//a[contains(text(),'Log Out')]")))
            logger.info("✅ Login successful with valid credentials.")
            WebDriverWait(self.driver, 3).until(WaitSeconds(3))
        except TimeoutException:
            self.fail("Failed to login with valid credentials")

        try:
            logout_link = self.wait.until(EC.presence_of_element_located((By.XPATH, "//a[contains(text(),'Log Out')]")))
            logout_link.click()
            self.wait.until(EC.presence_of_element_located((By.NAME, "email")))
            logger.info("✅ Logout successful.")
            WebDriverWait(self.driver, 3).until(WaitSeconds(3))
        except TimeoutException:
            self.fail("Failed to logout")

    def test_invalid_login(self):
        self.driver.get(self.live_server_url + "/login")

        email_input = self.wait.until(EC.presence_of_element_located((By.NAME, "email")))
        password_input = self.wait.until(EC.presence_of_element_located((By.NAME, "password")))

        email_input.clear()
        password_input.clear()

        email_input.send_keys("wrongemail@example.com")
        password_input.send_keys("wrongpassword")

        login_submit = self.wait.until(EC.element_to_be_clickable((By.CSS_SELECTOR, "button[type='submit']")))
        login_submit.click()

        try:
            error = self.wait.until(EC.presence_of_element_located((By.CLASS_NAME, "alert-danger")))
            error_text = error.text.lower()
            self.assertTrue(any(word in error_text for word in ["invalid", "incorrect", "error"]),
                            "Error message does not contain expected words")
            logger.info("✅ Correctly failed to login with invalid credentials.")
            WebDriverWait(self.driver, 3).until(WaitSeconds(3))
        except TimeoutException:
            self.fail("Did not show correct error message on invalid login")
