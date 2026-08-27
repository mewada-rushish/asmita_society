const fs = require('fs');
const path = require('path');

const controllerPath = 'D:\\Projects\\NextJS Projects\\my_asmita_n\\controllers\\familyController.js';
let content = fs.readFileSync(controllerPath, 'utf8');

// Update addFamilyMember
content = content.replace(
  'const { name, relationship, is_emergency_contact } = req.body;',
  'const { name, relationship, contact_number, is_emergency_contact } = req.body;'
);
content = content.replace(
  'data: { user_id: req.userId, name, relationship, is_emergency_contact: is_emergency_contact || false }',
  'data: { user_id: req.userId, name, relationship, contact_number, is_emergency_contact: is_emergency_contact || false }'
);

// Update updateFamilyMember
content = content.replace(
  'const { name, relationship, is_emergency_contact } = req.body;',
  'const { name, relationship, contact_number, is_emergency_contact } = req.body;'
);
content = content.replace(
  'data: { name, relationship, is_emergency_contact }',
  'data: { name, relationship, contact_number, is_emergency_contact }'
);

fs.writeFileSync(controllerPath, content, 'utf8');
console.log('Updated familyController.js to include contact_number');
