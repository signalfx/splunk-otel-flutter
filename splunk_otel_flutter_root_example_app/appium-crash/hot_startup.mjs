import { mkdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { remote } from 'webdriverio';

const packageName = 'com.splunk.rum.flutter.root.exampleapp.root_example_app';

const username = requiredEnv('SAUCE_USERNAME');
const accessKey = requiredEnv('SAUCE_ACCESS_KEY');
const region = process.env.SAUCE_REGION || 'us-west-1';
const app = process.env.SAUCE_APP || `storage:filename=${process.env.SAUCE_APP_NAME || 'smart-cinema-hot-startup.apk'}`;
const startupSettleSeconds = numberEnv('STARTUP_SETTLE_SECONDS', 30);
const backgroundSeconds = numberEnv('HOT_START_BACKGROUND_SECONDS', 10);
const hotStartSettleSeconds = numberEnv('HOT_START_SETTLE_SECONDS', 20);
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
        name: process.env.SAUCE_JOB_NAME || 'SmartCinema hot startup telemetry',
        build: process.env.SAUCE_BUILD_NAME || `smart-cinema-hot-startup-${new Date().toISOString()}`,
        appiumVersion: process.env.SAUCE_APPIUM_VERSION || '2.11.0',
        extendedDebugging: true,
      },
    },
  });

  await sauceContext('App installed and launched. Waiting for cold-start initialization.');
  await delaySeconds(startupSettleSeconds);

  await sauceContext(`Backgrounding app for ${backgroundSeconds} seconds.`);
  await driver.background(backgroundSeconds);

  await sauceContext('App returned to foreground. Waiting for hot-start telemetry creation.');
  await delaySeconds(hotStartSettleSeconds);

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

async function saveLogcat() {
  const assetsDir = join(process.cwd(), '__assets__');
  mkdirSync(assetsDir, { recursive: true });

  const logcat = await shell('logcat', ['-d'], 60000);
  writeFileSync(join(assetsDir, 'hot_startup_logcat.txt'), String(logcat));
}

async function shell(command, args, timeout) {
  return driver.execute('mobile: shell', {
    command,
    args,
    includeStderr: true,
    timeout,
  });
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
