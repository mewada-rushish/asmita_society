const fs = require('fs');
const path = require('path');

const schemaPath = 'D:\\Projects\\NextJS Projects\\my_asmita_n\\prisma\\schema.prisma';
let content = fs.readFileSync(schemaPath, 'utf8');

if (!content.includes('contact_number')) {
  content = content.replace(
    /model family_members \{\s+id\s+Int\s+@id @default\(autoincrement\(\)\)\s+user_id\s+Int\s+name\s+String\s+@db\.VarChar\(100\)\s+relationship\s+String\s+@db\.VarChar\(50\)\s+is_emergency_contact/g,
    'model family_members {\n    id                   Int       @id @default(autoincrement())\n    user_id              Int       \n    name                 String    @db.VarChar(100)\n    relationship         String    @db.VarChar(50)\n    contact_number       String?   @db.VarChar(20)\n    is_emergency_contact'
  );
  fs.writeFileSync(schemaPath, content, 'utf8');
  console.log('Added contact_number to schema.prisma');
} else {
  console.log('contact_number already exists in schema');
}
