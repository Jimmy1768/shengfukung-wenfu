const parseValue = (raw) => {
  const value = raw.trim();
  if (!value) {
    return '';
  }
  if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
    return value.slice(1, -1);
  }
  return value;
};

const peekNextLine = (lines, start) => {
  for (let i = start; i < lines.length; i += 1) {
    const trimmed = lines[i].trim();
    if (!trimmed) continue;
    return { index: i, indent: lines[i].match(/^ */)[0].length, trimmed };
  }
  return null;
};

const parseSimpleYaml = (text) => {
  const lines = text.split(/\r?\n/);
  const root = {};
  const stack = [{ indent: -1, value: root, type: 'object' }];

  for (let idx = 0; idx < lines.length; idx += 1) {
    const rawLine = lines[idx];
    if (!rawLine.trim() || rawLine.trim().startsWith('#')) {
      continue;
    }
    const indent = rawLine.match(/^ */)[0].length;
    const trimmed = rawLine.trim();

    while (stack.length && indent <= stack[stack.length - 1].indent) {
      stack.pop();
    }
    const parentEntry = stack[stack.length - 1];
    if (!parentEntry) {
      continue;
    }

    if (trimmed.startsWith('- ')) {
      if (parentEntry.type !== 'array') {
        parentEntry.value = [];
        parentEntry.type = 'array';
      }
      const rest = trimmed.slice(2).trim();
      if (!rest) {
        const newItem = {};
        parentEntry.value.push(newItem);
        stack.push({ indent, value: newItem, type: 'object' });
        continue;
      }

      const colonIndex = rest.indexOf(':');
      if (colonIndex === -1) {
        parentEntry.value.push(parseValue(rest));
        continue;
      }
      const key = rest.slice(0, colonIndex).trim();
      const value = rest.slice(colonIndex + 1).trim();
      const newItem = { [key]: parseValue(value) };
      parentEntry.value.push(newItem);
      stack.push({ indent, value: newItem, type: 'object' });
      continue;
    }

    const colonIndex = trimmed.indexOf(':');
    const key = trimmed.slice(0, colonIndex).trim();
    const rawValue = trimmed.slice(colonIndex + 1).trim();
    if (rawValue === '') {
      const nextLine = peekNextLine(lines, idx + 1);
      const nextIsArray = nextLine && nextLine.trimmed.startsWith('-') && nextLine.indent > indent;
      const container = nextIsArray ? [] : {};
      parentEntry.value[key] = container;
      stack.push({ indent, value: container, type: Array.isArray(container) ? 'array' : 'object' });
      continue;
    }

    parentEntry.value[key] = parseValue(rawValue);
  }

  return root;
};

export default parseSimpleYaml;
