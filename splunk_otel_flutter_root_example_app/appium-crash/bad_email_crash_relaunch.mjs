import { mkdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { remote } from 'webdriverio';

const packageName = 'com.splunk.rum.flutter.root.exampleapp.root_example_app';
const mainActivity = `${packageName}/.MainActivity`;
const badEmailCrashAction = `${packageName}.BAD_EMAIL_CRASH`;

const username = requiredEnv('SAUCE_USERNAME');
const accessKey = requiredEnv('SAUCE_ACCESS_KEY');
const region = process.env.SAUCE_REGION || 'us-west-1';
const app = process.env.SAUCE_APP || `storage:filename=${process.env.SAUCE_APP_NAME || 'smart-cinema-crash.apk'}`;
const startupSettleSeconds = numberEnv('STARTUP_SETTLE_SECONDS', 30);
const crashSettleSeconds = numberEnv('CRASH_SETTLE_SECONDS', 20);
const telemetrySettleSeconds = numberEnv('TELEMETRY_SETTLE_SECONDS', 180);

let driver;
let passed = false;

try {
  driver = await remote({
    protocol: 'https',
    hostname: `ondemand.${region}.saucelabs.com`,
    port: 443,
    path: '/wd/hub',
    user: username,
    key: accessKey,
    logLevel: process.env.WDIO_LOG_LEVEL || 'info',
    connectionRetryTimeout: 180000,
    capabilities: {
      platformName: 'Android',
      'appium:automationName': 'UiAutomator2',
      'appium:deviceName': process.env.SAUCE_DEVICE_NAME || 'Google Pixel 7 Pro GoogleAPI Emulator',
      'appium:platformVersion': process.env.SAUCE_PLATFORM_VERSION || '15.0',
      'appium:app': app,
      'appium:appPackage': packageName,
      'appium:appActivity': '.MainActivity',
      'appium:autoGrantPermissions': true,
      'appium:newCommandTimeout': 600,
      'sauce:options': {
        name: process.env.SAUCE_JOB_NAME || 'SmartCinema bad-email crash telemetry',
        build: process.env.SAUCE_BUILD_NAME || `smart-cinema-crash-${new Date().toISOString()}`,
        appiumVersion: process.env.SAUCE_APPIUM_VERSION || '2.11.0',
        extendedDebugging: true,
      },
    },
  });

  await sauceContext('App installed and launched. Waiting for Splunk RUM initialization.');
  await delaySeconds(startupSettleSeconds);

  await sauceContext('Triggering bad-email native crash through Android intent.');
  try {
    await shell('am', ['start', '-n', mainActivity, '-a', badEmailCrashAction], 30000);
  } catch (error) {
    await sauceContext(`Android shell crash intent failed, falling back to UI flow: ${error.message}`);
    await triggerCrashThroughUi();
  }

  await sauceContext('Crash command sent. Waiting for crash capture and process shutdown.');
  await delaySeconds(crashSettleSeconds);

  await sauceContext('Relaunching app so the stored crash can upload.');
  await relaunchApp();

  await sauceContext(`Keeping app open for ${telemetrySettleSeconds} seconds for Olly upload.`);
  await delaySeconds(telemetrySettleSeconds);

  await saveLogcat();

  passed = true;
  await setSauceResult('passed');
} catch (error) {
  if (driver) {
    await saveLogcat().catch(() => {});
    await setSauceResult('failed').catch(() => {});
  }

  throw error;
} finally {
  if (driver) {
    await driver.deleteSession();
  }
}

if (!passed) {
  process.exitCode = 1;
}

async function relaunchApp() {
  try {
    await driver.activateApp(packageName);
  } catch {
    await shell('am', ['start', '-n', mainActivity], 30000);
  }
}

async function triggerCrashThroughUi() {
  await clickText('Get started');

  const emailFields = await waitForElements('android.widget.EditText', 2, 30000);
  await emailFields[0].setValue('invalid-email');
  await emailFields[1].setValue('test-password');
  await driver.hideKeyboard().catch(() => {});

  const loginButtons = await waitForTextElements('Login', 1, 30000);
  await loginButtons[loginButtons.length - 1].click();
}

async function saveLogcat() {
  const assetsDir = join(process.cwd(), '__assets__');
  mkdirSync(assetsDir, { recursive: true });

  const logcat = await shell('logcat', ['-d'], 60000);
  writeFileSync(join(assetsDir, 'bad_email_crash_logcat.txt'), String(logcat));
}

async function clickText(text) {
  const element = await waitForText(text, 30000);
  await element.click();
}

async function waitForText(text, timeout) {
  const selector = `android=new UiSelector().text("${escapeUiSelectorText(text)}")`;
  const element = await driver.$(selector);
  await element.waitForExist({ timeout });

  return element;
}

async function waitForTextElements(text, minCount, timeout) {
  const selector = `android=new UiSelector().text("${escapeUiSelectorText(text)}")`;
  return waitForElements(selector, minCount, timeout);
}

async function waitForElements(selector, minCount, timeout) {
  const end = Date.now() + timeout;

  while (Date.now() < end) {
    const elements = selector.startsWith('android=')
      ? await driver.$$(selector)
      : await driver.$$(`android=new UiSelector().className("${selector}")`);

    if (elements.length >= minCount) {
      return elements;
    }

    await delaySeconds(1);
  }

  throw new Error(`Timed out waiting for at least ${minCount} elements matching ${selector}.`);
}

async function shell(command, args, timeout) {
  return driver.execute('mobile: shell', {
    command,
    args,
    includeStderr: true,
    timeout,
  });
}

function escapeUiSelectorText(text) {
  return text.replace(/\\/g, '\\\\').replace(/"/g, '\\"');
}

async function sauceContext(message) {
  console.log(message);
  if (driver) {
    await driver.execute(`sauce:context=${message}`);
  }
}

async function setSauceResult(result) {
  await driver.execute(`sauce:job-result=${result}`);
}

function delaySeconds(seconds) {
  return new Promise((resolve) => {
    setTimeout(resolve, seconds * 1000);
  });
}

function requiredEnv(name) {
  const value = process.env[name];
  if (!value) {
    throw new Error(`${name} is required.`);
  }

  return value;
}

function numberEnv(name, defaultValue) {
  const value = process.env[name];
  if (!value) {
    return defaultValue;
  }

  const parsed = Number.parseInt(value, 10);
  if (Number.isNaN(parsed)) {
    throw new Error(`${name} must be a number.`);
  }

  return parsed;
}
