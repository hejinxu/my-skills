import fs from 'fs';
import path from 'path';
import os from 'os';

const CONFIG_DIR_NAME = path.join('.config', 'gs-skills');
const CONFIG_FILE_NAME = 'config.json';

function readJson(filePath) {
  try {
    if (fs.existsSync(filePath)) {
      const content = fs.readFileSync(filePath, 'utf8');
      return JSON.parse(content);
    }
  } catch (e) {
    // Ignore invalid config files
  }
  return null;
}

function findProjectConfig(startDir) {
  let dir = startDir;
  const root = path.parse(dir).root;

  while (dir !== root) {
    const configPath = path.join(dir, CONFIG_DIR_NAME, CONFIG_FILE_NAME);
    if (fs.existsSync(configPath)) {
      return readJson(configPath);
    }
    dir = path.dirname(dir);
  }
  return null;
}

function getGlobalConfigPath() {
  return path.join(os.homedir(), CONFIG_DIR_NAME, CONFIG_FILE_NAME);
}

function mergeConfig(namespace, envMapping, globalConfig, projectConfig) {
  const nsConfig = {};
  const globalNs = globalConfig[namespace] || {};
  const projectNs = projectConfig[namespace] || {};

  for (const [key, envVar] of Object.entries(envMapping)) {
    nsConfig[key] = process.env[envVar] || projectNs[key] || globalNs[key] || '';
  }

  return nsConfig;
}

export function loadConfig(namespace, envMapping, cwd = process.cwd()) {
  const globalConfig = readJson(getGlobalConfigPath()) || {};
  const projectConfig = findProjectConfig(cwd) || {};

  return mergeConfig(namespace, envMapping, globalConfig, projectConfig);
}

export function saveGlobalConfig(config, namespace) {
  const configDir = path.join(os.homedir(), CONFIG_DIR_NAME);
  if (!fs.existsSync(configDir)) {
    fs.mkdirSync(configDir, { recursive: true });
  }
  const configPath = path.join(configDir, CONFIG_FILE_NAME);
  const existingConfig = readJson(configPath) || {};
  existingConfig[namespace] = config;
  fs.writeFileSync(configPath, JSON.stringify(existingConfig, null, 2), 'utf8');
  return configPath;
}

export function getGlobalConfigDir() {
  return path.join(os.homedir(), CONFIG_DIR_NAME);
}
