const fs = require("node:fs");
const path = require("node:path");
const Handlebars = require("handlebars");

const config = {
  baseImage: "ubuntu:resolute-20260421",
  maintainer: "https://github.com/lwmacct",
  source: "https://github.com/lwmacct/260629-cr-nginx",
};

const templatePath = path.join(__dirname, "Dockerfile.hbs");
const outputPath = path.join(__dirname, "Dockerfile");

const template = fs.readFileSync(templatePath, "utf8");
const dockerfile = Handlebars.compile(template, { noEscape: true })(config);

fs.writeFileSync(outputPath, dockerfile);
console.log(`Generated ${path.relative(process.cwd(), outputPath)}`);
