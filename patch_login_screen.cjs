const fs = require('fs');
const path = require('path');

const filePath = path.join(__dirname, 'ferfit_flutter', 'lib', 'screens', 'login_screen.dart');
let content = fs.readFileSync(filePath, 'utf8');

// Remove import
content = content.replace("import 'clerk_webview_login.dart';\n", '');

// Add password length check
content = content.replace(
  "    // No local password complexity checks per user request",
  "    if (password.length < 8) {\n      setState(() => _errorMessage = 'La contraseña debe tener mínimo 8 caracteres');\n      return;\n    }"
);

// Remove Google Button and Divider
// Specifically, everything from "// ─── Divider ───" (or similar) down to just before "// ─── Toggle Link ───"
// We can use a regex to replace from "Row(\n" with "Expanded(\n" child Divider... to the end of the Google button.
// Let's just look for the block containing 'o continuar con' up to 'Google'
const lines = content.split('\n');
const startIndex = lines.findIndex(l => l.includes('o continuar con'));
if (startIndex !== -1) {
  // Go up to find the start of the Row
  let rowStart = startIndex;
  while (rowStart > 0 && !lines[rowStart].includes('// ─── Divider ───') && !lines[rowStart].includes('Row(')) {
    rowStart--;
  }
  // The line above `Row(` is probably `// ─── Divider ───`
  if (lines[rowStart - 1].includes('Divider')) rowStart--;

  // Find the end of the Google button
  let btnEnd = startIndex;
  while (btnEnd < lines.length && !lines[btnEnd].includes('// ─── Toggle Link ───')) {
    btnEnd++;
  }
  // Remove the block
  lines.splice(rowStart, btnEnd - rowStart);
  content = lines.join('\n');
}

// Remove _handleGoogleSignIn function
const newLines = content.split('\n');
const funcStartIndex = newLines.findIndex(l => l.includes('Future<void> _handleGoogleSignIn() async {'));
if (funcStartIndex !== -1) {
  let funcEndIndex = funcStartIndex;
  while (funcEndIndex < newLines.length) {
    if (newLines[funcEndIndex].startsWith('}')) {
      // Find the second '}' or end of class
      if (newLines[funcEndIndex] === '}' && newLines[funcEndIndex-1] === '}') {
          funcEndIndex++; // include the class closing bracket? Wait, we don't want to remove the class closing bracket.
      }
    }
    funcEndIndex++;
  }
  // Just find the end of the file, minus the last closing bracket.
  // Actually, _handleGoogleSignIn is the last function in the class.
  // It starts with `Future<void> _handleGoogleSignIn() async {` and goes until the end of file minus one `}`
  const lastBraceIndex = newLines.lastIndexOf('}');
  newLines.splice(funcStartIndex, lastBraceIndex - funcStartIndex);
  content = newLines.join('\n');
}

fs.writeFileSync(filePath, content, 'utf8');
console.log('Success');
