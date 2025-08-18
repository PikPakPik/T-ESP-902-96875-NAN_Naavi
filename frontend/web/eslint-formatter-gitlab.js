import { createHash } from 'node:crypto';
import { writeFileSync, existsSync, readFileSync } from 'node:fs';
import { relative } from 'node:path';
import { EOL } from 'os';
import chalk from 'chalk';

const { CI_PROJECT_DIR = process.cwd() } = process.env;

const NB_SPACE = 2;

/**
 * @returns {string} The fingerprint for the ESLint report message.
 */
function createFingerprint() {
  const md5 = createHash(`md5`);
  md5.update((Math.random() * 100).toString());
  return md5.digest(`hex`);
}

/**
 * @param {object[]} results The ESLint report results.
 * @returns {object[]} The ESLint messages in the form of a GitLab code quality report.
 */
function convert(results) {
  const messages = [];
  for (const result of results) {
    for (const message of result.messages) {
      const relativePath = relative(CI_PROJECT_DIR, result.filePath);
      //https://github.com/codeclimate/platform/blob/master/spec/analyzers/SPEC.md#data-types
      messages.push({
        description: message.message,
        fingerprint: createFingerprint(),
        severity: message.severity === 2 ? `major` : `minor`,
        location: {
          path: relativePath,
          lines: {
            begin: message.line,
          },
        },
      });
    }
  }

  return messages;
}

function messageIsLevelError(message) {
  return message.fatal || message.severity === 2;
}

function calculateResultsStats(results) {
  const stats = {
    total: 0,
    errors: 0,
    warnings: 0,
    maxRuleIdLength: 0,
    maxMsgLength: 0,
    maxPosition: 0,
  };

  for (const result of results) {
    for (const message of result.messages) {
      const isError = messageIsLevelError(message);
      stats.errors += isError ? 1 : 0;
      stats.warnings += isError ? 0 : 1;
      stats.maxRuleIdLength = message.ruleId
        ? Math.max(stats.maxRuleIdLength, message.ruleId.length)
        : stats.maxRuleIdLength;
      stats.maxMsgLength = Math.max(stats.maxMsgLength, message.message.length);
      stats.maxPosition = Math.max(
        stats.maxPosition,
        `${message.line}:${message.column}`.length
      );
    }
  }

  stats.total = stats.warnings + stats.errors;

  return stats;
}

const plural = (count, text) => `${count} ${text}${count === 1 ? `` : `s`}`;

function formatResultForConsole(results) {
  const labelError = `${chalk.red(`error`)}`;
  const labelWarn = `${chalk.yellow(`warn`)}`;

  const lines = [];
  const stats = calculateResultsStats(results);

  for (const result of results) {
    const { filePath, messages } = result;
    if (messages.length === 0) continue;
    let line = `${chalk.underline(
      `${relative(CI_PROJECT_DIR, filePath)} (${messages.length})`
    )} ${EOL}`;

    for (const message of messages) {
      const levelError = messageIsLevelError(message) ? labelError : labelWarn;
      const position = `${message.line}:${message.column}`;
      const rule = chalk.grey(message.ruleId);
      line += `  `;
      line += chalk.grey(position.padEnd(stats.maxPosition + NB_SPACE));
      line += levelError.padEnd(labelError.length + NB_SPACE);
      line += message.message.padEnd(stats.maxMsgLength + NB_SPACE);
      line += `${rule}${EOL}`;
    }
    lines.push(line);
  }

  if (stats.total > 0) {
    const details = `(${plural(stats.errors, `error`)}, ${plural(
      stats.warnings,
      `warning`
    )})`;
    lines.push(
      ``,
      `${chalk.bold.red(`✖ ${plural(stats.total, `problem`)} ${details}`)}`
    );
  } else {
    lines.push(`${chalk.bold.green(`✔ No problems found`)}`);
  }

  lines.push(``);
  return lines.join(EOL);
}

export default (results) => {
  let convertedData = convert(results);

  if (existsSync('./gl-code-quality-report.json')) {
    const content = readFileSync('./gl-code-quality-report.json', {
      encoding: 'utf-8',
    });
    const data = JSON.parse(content.toString());
    convertedData = [...convertedData, ...data];
  }

  writeFileSync(
    `./gl-code-quality-report.json`,
    JSON.stringify(convertedData, null, 2)
  );

  return formatResultForConsole(results);
};
