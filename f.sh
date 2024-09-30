#!/bin/bash

# Update and upgrade the system
echo "Updating system..."
sudo apt-get update -y
sudo apt-get upgrade -y

# Install desktop environment (Xfce)
echo "Installing Xfce desktop environment..."
sudo apt-get install -y xfce4 xfce4-goodies

# Install xrdp for RDP access
echo "Installing xrdp for RDP..."
sudo apt-get install -y xrdp
sudo systemctl enable xrdp
sudo systemctl start xrdp

# Configure xrdp to use Xfce
echo "Configuring xrdp to use Xfce..."
echo xfce4-session > ~/.xsession
sudo sed -i 's/console/anybody/g' /etc/X11/Xwrapper.config
sudo systemctl restart xrdp

# Add your user to the ssl-cert group (required for xrdp)
echo "Adding user to ssl-cert group..."
sudo adduser $(whoami) ssl-cert

# Install Google Chrome and its dependencies
echo "Installing Chrome dependencies..."
sudo apt-get install -y wget libxss1 libappindicator1 libindicator7 gconf-service libnss3-1d libx11-xcb1 libxcomposite1 libxcursor1 libxdamage1 libxi6 libxtst6 libpango1.0-0 fonts-liberation libasound2 libatk1.0-0 libgtk-3-0 libpangocairo-1.0-0 libxrandr2 xdg-utils

echo "Installing Google Chrome..."
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt install -y ./google-chrome-stable_current_amd64.deb
rm google-chrome-stable_current_amd64.deb

# Install ChromeDriver (Ensure it matches Chrome version)
echo "Installing ChromeDriver..."
CHROME_VERSION=$(google-chrome --version | awk '{print $3}' | cut -d '.' -f 1)
DRIVER_VERSION=$(wget -qO- https://chromedriver.storage.googleapis.com/LATEST_RELEASE_$CHROME_VERSION)
wget https://chromedriver.storage.googleapis.com/$DRIVER_VERSION/chromedriver_linux64.zip
unzip chromedriver_linux64.zip
sudo mv chromedriver /usr/local/bin/
rm chromedriver_linux64.zip

# Install Python 3 and pip
echo "Installing Python 3 and pip..."
sudo apt-get install -y python3 python3-pip

# Install required Python libraries
echo "Installing Python libraries..."
sudo pip3 install undetected-chromedriver selenium psutil

# Install Xvfb (optional: used for headless mode, not activated here)
echo "Installing Xvfb for headless browsing (optional)..."
sudo apt-get install -y xvfb

# Add swap memory to avoid memory issues (optional but recommended)
SWAPFILE="/swapfile"
if [ ! -f $SWAPFILE ]; then
    echo "Adding swap memory..."
    sudo fallocate -l 4G $SWAPFILE
    sudo chmod 600 $SWAPFILE
    sudo mkswap $SWAPFILE
    sudo swapon $SWAPFILE
    echo "$SWAPFILE swap swap defaults 0 0" | sudo tee -a /etc/fstab
else
    echo "Swap memory already exists."
fi

# Ensure accounts.txt exists
if [ ! -f accounts.txt ]; then
    echo "Creating a sample accounts.txt file..."
    echo "user1:password1" > accounts.txt
    echo "user2:password2" >> accounts.txt
fi

# Creating the Python script from the provided code
echo "Creating the PokemonGo login Python script..."
cat <<EOF > pokemongo_script.py
import undetected_chromedriver as uc
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from time import sleep
import random
import psutil
from datetime import datetime

def random_delay(min_delay=1, max_delay=3):
    """ Introduce a random delay between actions to mimic human behavior. """
    sleep(random.uniform(min_delay, max_delay))
        
def process_account(username, password, output_file):
    options = uc.ChromeOptions()
    user_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.5735.199 Safari/537.36"
    options.add_argument(f"user-agent={user_agent}")
    options.add_argument("--disable-blink-features=AutomationControlled")
    options.add_argument("--disable-infobars")
    options.add_argument("--disable-popup-blocking")
    options.add_argument("--incognito")
    options.add_argument("--disable-search-engine-choice-screen")
    options.add_argument("--no-sandbox")

    driver = uc.Chrome(options=options)
    try:
        driver.get("https://store.pokemongolive.com/offer-redemption")
        random_delay()

        first_element = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable((By.XPATH, "/html/body/div[2]/div/main/section/div/div/anchor-button/a"))
        )
        first_element.click()
        random_delay()

        second_element = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable((By.XPATH, "/html/body/div[1]/main/div/div/button[5]"))
        )
        second_element.click()
        random_delay()

        driver.switch_to.window(driver.window_handles[-1])

        username_field = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.ID, "email"))
        )
        username_field.send_keys(username)
        random_delay()

        password_field = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.ID, "password"))
        )
        password_field.send_keys(password)
        random_delay()

        accept_button = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable((By.ID, "accept"))
        )
        accept_button.click()
        random_delay()

        driver.switch_to.window(driver.window_handles[0])

        level_element = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.CSS_SELECTOR, "p[data-testid='label-user-snapshot-level']"))
        )
        level_text = level_element.text
        level = level_text.split()[-1]

        with open(output_file, "a") as file:
            file.write(f"{username}:{password}:{level}\n")

        print(f"Successfully logged in and recorded data for {username} with level {level}.")

    except Exception as e:
        print(f"Could not log in for {username}. Error: {str(e).split(':')[0]}")
        return False

    finally:
        driver.quit()
    return True

def main():
    try:
        current_date = datetime.now().strftime("%Y-%m-%d")
        output_file = f"successful_{current_date}.txt"

        with open("accounts.txt", "r") as file:
            for line in file:
                line = line.strip()
                if line:
                    username, password = line.split(":")
                    process_account(username, password, output_file)
                    random_delay()

    except FileNotFoundError:
        print("accounts.txt not found. Please ensure the file exists.")
    except Exception as e:
        print(f"Unexpected error: {e}")

if __name__ == "__main__":
    main()
EOF

# Display message about how to connect via RDP
echo "Setup complete! You can now connect to this server using RDP."
echo "Use the following command to run the script:"
echo "python3 pokemongo_script.py"
