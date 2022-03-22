// An example of using Selenium to get the source of a web page
const webdriver = require('selenium-webdriver');
    let driver = new webdriver.Builder().forBrowser('firefox').build();
    driver.get('https://www.rightmove.co.uk').then(
        () => {
            driver.getPageSource().then(
                page => console.log(page))
        });
