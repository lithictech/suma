const { networkInterfaces } = require("os");

const results = {};
for (const [name, nets] of Object.entries(networkInterfaces())) {
  for (const net of nets) {
    // Skip over non-IPv4 and internal (i.e. 127.0.0.1) addresses
    // 'IPv4' is in Node <= 17, from 18 it's a number 4 or 6
    const familyV4Value = typeof net.family === "string" ? "IPv4" : 4;
    if (net.family === familyV4Value && !net.internal) {
      if (!results[name]) {
        results[name] = [];
      }
      results[name].push(net.address);
    }
  }
}
const message =
  results["en0"] ||
  results["eth0"] ||
  `<could not locate en0 or eth0 in interfaces: ${Object.keys(results)}>`;
console.log(message);
