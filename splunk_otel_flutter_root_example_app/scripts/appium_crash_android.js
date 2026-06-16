#!/usr/bin/env node
/*
 * Copyright 2026 Splunk Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

'use strict';

const fs = require('fs');
const http = require('http');
const https = require('https');
const path = require('path');

const ELEMENT_KEY = 'element-6066-11e4-a52e-4f735466cecf';
const APP_STATE_FOREGROUND = 4;

const config = {
  username: requiredEnv('SAUCE_USERNAME'),
  accessKey: requiredEnv('SAUCE_ACCESS_KEY'),
  app: requiredEnv('SAUCE_APP'),
  webDriverUrl: stripTrailingSlash(
    process.env.SAUCE_WEBDRIVER_URL || 'https://ondemand.us-west-1.saucelabs.com/wd/hub',
  ),
  deviceName: process.env.SAUCE_DEVICE_NAME || 'Samsung Galaxy S26 Ultra',
  platformVersion: process.env.SAUCE_PLATFORM_VERSION || '16',
  appiumVersion: process.env.SAUCE_APPIUM_VERSION || 'appium2-20250901',
  privateDevicesOnly: envBool('SAUCE_PRIVATE_DEVICES_ONLY', true),
  resigningEnabled: envBool('SAUCE_RESIGNING_ENABLED', false),
  appPackageId:
    process.env.APP_PACKAGE_ID ||
    'com.splunk.rum.flutter.root.exampleapp.root_example_app',
  invalidEmail: process.env.CRASH_TEST_EMAIL || 'invalid-email',
  validEmail: process.env.CRASH_TEST_VALID_EMAIL || 'jan@smartlook.com',
  validPassword: process.env.CRASH_TEST_VALID_PASSWORD || 'test-password',
  initialWaitSeconds: envNumber('INITIAL_WAIT_SECONDS', 10),
  relaunchPauseSeconds: envNumber('RELAUNCH_PAUSE_SECONDS', 3),
  flowStepWaitSeconds: envNumber('FLOW_STEP_WAIT_SECONDS', 2),
  crashWaitSeconds: envNumber('CRASH_WAIT_SECONDS', 30),
  telemetrySettleSeconds: envNumber('TELEMETRY_SETTLE_SECONDS', 120),
  telemetryKeepaliveIntervalSeconds: envNumber(
    'TELEMETRY_KEEPALIVE_INTERVAL_SECONDS',
    30,
  ),
  newCommandTimeoutSeconds: envNumber(
    'APPIUM_NEW_COMMAND_TIMEOUT_SECONDS',
    Math.max(envNumber('TELEMETRY_SETTLE_SECONDS', 120) + 60, 180),
  ),
  artifactDir: process.env.ARTIFACT_DIR || 'artifacts',
  localAppium: envBool('LOCAL_APPIUM', false),
  sessionName: `rum-crash-flow-android-${process.env.CI_PIPELINE_ID || 'local'}`,
  buildName: `rum-appium-crash-flow-${process.env.CI_PIPELINE_ID || 'local'}`,
};

const locators = {
  getStarted: ['Get started', 'GET STARTED'],
  emailHint: 'Email',
  passwordHint: 'Password',
  login: ['Login', 'LOGIN'],
  movieSpidermanNoWayHome: [
    'Movie Spiderman: No Way Home',
    'Movie Spiderman: No Way Home\nSpiderman: No Way Home\n8.3/10 IMDb',
  ],
};

let sessionId = '';
fs.mkdirSync(config.artifactDir, { recursive: true });

function requiredEnv(name) {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Set ${name} before running this script.`);
  }
  return value;
}

function stripTrailingSlash(value) {
  return value.replace(/\/+$/, '');
}

function envBool(name, fallback) {
  const value = process.env[name];
  if (value === undefined || value === '') {
    return fallback;
  }
  return value.toLowerCase() === 'true';
}

function envNumber(name, fallback) {
  const value = Number(process.env[name]);
  return Number.isFinite(value) ? value : fallback;
}

function artifactPath(name) {
  return path.join(config.artifactDir, name);
}

function writeArtifact(name, content) {
  fs.writeFileSync(artifactPath(name), content);
}

function sleep(seconds) {
  return new Promise((resolve) => setTimeout(resolve, seconds * 1000));
}

function endpointUrl(endpoint) {
  const base = new URL(config.webDriverUrl);
  const basePath = base.pathname.replace(/\/$/, '');
  const requestPath = endpoint.startsWith('/') ? endpoint : `/${endpoint}`;
  base.pathname = `${basePath}${requestPath}`;
  base.search = '';
  return base;
}

function request(method, endpoint, body) {
  const url = endpointUrl(endpoint);
  const bodyText = body === undefined ? '' : JSON.stringify(body);
  const headers = {
    Authorization: `Basic ${Buffer.from(`${config.username}:${config.accessKey}`).toString('base64')}`,
  };

  if (body !== undefined) {
    headers['Content-Type'] = 'application/json';
    headers['Content-Length'] = Buffer.byteLength(bodyText);
  }

  const client = url.protocol === 'https:' ? https : http;

  return new Promise((resolve, reject) => {
    const req = client.request(
      url,
      {
        method,
        headers,
      },
      (res) => {
        const chunks = [];
        res.on('data', (chunk) => chunks.push(chunk));
        res.on('end', () => {
          const text = Buffer.concat(chunks).toString('utf8');
          let json = null;
          try {
            json = text ? JSON.parse(text) : null;
          } catch {
            json = null;
          }

          resolve({
            statusCode: res.statusCode || 0,
            text,
            json,
          });
        });
      },
    );

    req.on('error', reject);

    if (body !== undefined) {
      req.write(bodyText);
    }
    req.end();
  });
}

function sessionEndpoint(endpoint) {
  return `/session/${sessionId}/${endpoint}`;
}

async function postCommand(artifactName, endpoint, body) {
  const response = await request('POST', sessionEndpoint(endpoint), body);
  writeArtifact(`appium-${artifactName}.json`, response.text);

  if (response.statusCode < 200 || response.statusCode > 299) {
    throw new Error(
      `Appium command '${artifactName}' failed with HTTP ${response.statusCode}: ${response.text}`,
    );
  }

  return response.json;
}

async function createSession() {
  const payload = {
    capabilities: {
      alwaysMatch: {
        platformName: 'Android',
        browserName: '',
        'appium:automationName': 'UiAutomator2',
        'appium:app': config.app,
        'appium:deviceName': config.deviceName,
        'appium:platformVersion': config.platformVersion,
        'appium:enforceAppInstall': true,
        'appium:autoGrantPermissions': true,
        'appium:newCommandTimeout': config.newCommandTimeoutSeconds,
        'sauce:options': {
          name: config.sessionName,
          build: config.buildName,
          appiumVersion: config.appiumVersion,
          tags: ['rum', 'crash-flow', 'android', 'gitlab'],
          privateDevicesOnly: config.privateDevicesOnly,
          resigningEnabled: config.resigningEnabled,
        },
      },
    },
  };

  console.log(
    `Creating Sauce Appium session on ${config.deviceName} Android ${config.platformVersion}`,
  );

  const response = await request('POST', '/session', payload);
  writeArtifact('appium-session-create.json', response.text);

  if (response.statusCode < 200 || response.statusCode > 299) {
    throw new Error(
      `Sauce Appium session creation failed with HTTP ${response.statusCode}: ${response.text}`,
    );
  }

  sessionId =
    (response.json &&
      (response.json.sessionId ||
        (response.json.value && response.json.value.sessionId))) ||
    '';
  if (!sessionId) {
    throw new Error(`Sauce Appium session creation did not return a session ID: ${response.text}`);
  }

  console.log(`Sauce Appium session ID: ${sessionId}`);
}

function elementIdFromResponse(json) {
  const value = json && json.value;
  if (!value) {
    return '';
  }
  return value[ELEMENT_KEY] || value.ELEMENT || '';
}

async function findElement(using, value) {
  const response = await request('POST', sessionEndpoint('element'), {
    using,
    value,
  });

  if (response.statusCode < 200 || response.statusCode > 299) {
    return '';
  }

  return elementIdFromResponse(response.json);
}

function accessibilityLabels(locator) {
  return Array.isArray(locator) ? locator : [locator];
}

function describeAccessibilityLocator(locator) {
  const labels = accessibilityLabels(locator);
  if (labels.length === 1) {
    return `'${labels[0]}'`;
  }

  return `one of ${labels.map((label) => `'${label}'`).join(', ')}`;
}

async function waitForAccessibilityId(locator, timeoutSeconds = 30) {
  const labels = accessibilityLabels(locator);
  const endAt = Date.now() + timeoutSeconds * 1000;

  while (Date.now() < endAt) {
    for (const label of labels) {
      const elementId = await findElement('accessibility id', label);
      if (elementId) {
        if (labels.length > 1) {
          console.log(`Matched accessibility id '${label}'`);
        }
        return elementId;
      }
    }
    await sleep(2);
  }

  return '';
}

async function clickElement(elementId) {
  await postCommand(`click-${elementId}`, `element/${elementId}/click`, {});
}

async function clickAccessibilityId(locator) {
  console.log(`Clicking ${describeAccessibilityLocator(locator)}`);

  const elementId = await waitForAccessibilityId(locator, 25);
  if (!elementId) {
    await collectSource();
    throw new Error(
      `Could not find ${describeAccessibilityLocator(locator)} through Appium selectors.`,
    );
  }

  await clickElement(elementId);
  await sleep(config.flowStepWaitSeconds);
}

function xpathLiteral(value) {
  if (!value.includes("'")) {
    return `'${value}'`;
  }
  if (!value.includes('"')) {
    return `"${value}"`;
  }
  return `concat('${value.replace(/'/g, "',\"'\",'")}')`;
}

async function enterTextField(hint, text) {
  console.log(`Entering ${hint} field`);

  const elementId = await findElement(
    'xpath',
    `//*[@class='android.widget.EditText' and @hint=${xpathLiteral(hint)}]`,
  );

  if (!elementId) {
    await collectSource();
    throw new Error(`Could not find '${hint}' field through Appium selectors.`);
  }

  await clickElement(elementId);
  await sleep(1);
  await clearElement(elementId);

  try {
    await postCommand(`set-value-${elementId}`, `element/${elementId}/value`, {
      text,
    });
  } catch (error) {
    console.log(`Standard setValue failed for ${hint} field. Trying replaceValue.`);
    await postCommand(`replace-value-${elementId}`, `appium/element/${elementId}/replace_value`, {
      text,
    });
  }

  await hideKeyboard();
  await sleep(config.flowStepWaitSeconds);
}

async function clearElement(elementId) {
  try {
    await postCommand(`clear-${elementId}`, `element/${elementId}/clear`, {});
  } catch {
    // Some Flutter-backed fields do not need/allow clear before setting text.
  }
}

async function hideKeyboard() {
  try {
    await postCommand('hide-keyboard', 'appium/device/hide_keyboard', {});
  } catch {
    // The keyboard may already be hidden.
  }
}

async function queryAppState() {
  const response = await postCommand('query-app-state', 'appium/device/app_state', {
    appId: config.appPackageId,
  });
  return response && typeof response.value === 'number' ? response.value : -1;
}

async function waitForAppToLeaveForeground() {
  const endAt = Date.now() + config.crashWaitSeconds * 1000;
  let lastState = APP_STATE_FOREGROUND;

  while (Date.now() < endAt) {
    try {
      lastState = await queryAppState();
      if (lastState !== APP_STATE_FOREGROUND) {
        console.log(`App left foreground after invalid email. Appium app state: ${lastState}`);
        return;
      }
    } catch (error) {
      console.log('App state query failed after invalid email; treating app as no longer foreground.');
      return;
    }

    await sleep(2);
  }

  throw new Error(
    `App did not leave foreground within ${config.crashWaitSeconds}s after invalid email. Last app state: ${lastState}`,
  );
}

async function collectSource() {
  if (!sessionId) {
    return;
  }

  try {
    const response = await request('GET', sessionEndpoint('source'));
    writeArtifact('appium-source.xml', response.text);
  } catch {
    // Keep cleanup best-effort.
  }
}

async function collectLogcat() {
  if (!sessionId) {
    return;
  }

  try {
    await postCommand('logcat', 'log', { type: 'logcat' });
  } catch {
    // Keep cleanup best-effort.
  }
}

async function markJobResult(result) {
  if (config.localAppium || !sessionId) {
    return;
  }

  try {
    await postCommand(`mark-${result}`, 'execute/sync', {
      script: `sauce:job-result=${result}`,
      args: [],
    });
  } catch {
    // Sauce job marking should not hide the real test result.
  }
}

async function deleteSession() {
  if (!sessionId) {
    return;
  }

  try {
    const response = await request('DELETE', sessionEndpoint(''));
    writeArtifact('appium-session-delete.json', response.text);
  } catch {
    // Keep cleanup best-effort.
  }
}

async function runValidLoginAfterRelaunch() {
  await clickAccessibilityId(locators.getStarted);
  await enterTextField(locators.emailHint, config.validEmail);
  await enterTextField(locators.passwordHint, config.validPassword);
  await clickAccessibilityId(locators.login);

  const movieElement = await waitForAccessibilityId(locators.movieSpidermanNoWayHome, 45);
  if (!movieElement) {
    await collectSource();
    throw new Error('Valid login after crash did not reach the home screen.');
  }

  console.log('Valid login after crash reached the home screen.');
}

async function waitForTelemetryFlush() {
  console.log(`Waiting ${config.telemetrySettleSeconds}s for RUM telemetry to flush.`);

  const endAt = Date.now() + config.telemetrySettleSeconds * 1000;
  while (Date.now() < endAt) {
    const remainingSeconds = Math.ceil((endAt - Date.now()) / 1000);
    const waitSeconds = Math.min(
      config.telemetryKeepaliveIntervalSeconds,
      remainingSeconds,
    );

    await sleep(waitSeconds);

    if (Date.now() < endAt) {
      const appState = await queryAppState();
      console.log(`Telemetry wait keep-alive sent. Appium app state: ${appState}`);
    }
  }
}

async function runCrashFlow() {
  await createSession();

  console.log(`Initial app launch is running. Waiting ${config.initialWaitSeconds}s.`);
  await sleep(config.initialWaitSeconds);

  console.log(`Terminating ${config.appPackageId} to force a fresh launch.`);
  await postCommand('terminate-app', 'appium/device/terminate_app', {
    appId: config.appPackageId,
  });

  console.log(`Waiting ${config.relaunchPauseSeconds}s before relaunch.`);
  await sleep(config.relaunchPauseSeconds);

  console.log(`Activating ${config.appPackageId} like a user launch.`);
  await postCommand('activate-app', 'appium/device/activate_app', {
    appId: config.appPackageId,
  });
  await sleep(config.initialWaitSeconds);

  await clickAccessibilityId(locators.getStarted);
  await enterTextField(locators.emailHint, config.invalidEmail);
  await clickAccessibilityId(locators.login);

  console.log('Invalid email submitted. Waiting for the app to exit.');
  await waitForAppToLeaveForeground();

  console.log(`Waiting ${config.relaunchPauseSeconds}s before relaunch.`);
  await sleep(config.relaunchPauseSeconds);

  console.log(`Relaunching ${config.appPackageId} after expected crash/exit.`);
  await postCommand('activate-app-after-crash', 'appium/device/activate_app', {
    appId: config.appPackageId,
  });
  await sleep(config.initialWaitSeconds);

  const getStartedElement = await waitForAccessibilityId(locators.getStarted, 30);
  if (!getStartedElement) {
    await collectSource();
    throw new Error('App did not relaunch to the welcome screen after invalid-email crash.');
  }

  console.log('App relaunched successfully after invalid-email crash.');
  await runValidLoginAfterRelaunch();

  await waitForTelemetryFlush();

  console.log('Sauce Appium crash-flow run completed.');
}

(async () => {
  let status = 'passed';

  try {
    await runCrashFlow();
  } catch (error) {
    status = 'failed';
    console.error(error instanceof Error ? error.message : error);
    process.exitCode = 1;
  } finally {
    await collectSource();
    await collectLogcat();
    await markJobResult(status);
    await deleteSession();
  }
})();
