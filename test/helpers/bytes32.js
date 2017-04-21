const Web3 = require('../../node_modules/web3')
const web3Location = `http://localhost:8545`
const web3 = new Web3(new Web3.providers.HttpProvider(web3Location))
function bytes32(stringOrNumber) {
  var zeros = '000000000000000000000000000000000000000000000000000000000000000';
  if (typeof stringOrNumber === "string") {
    return (web3.toHex(stringOrNumber) + zeros).substr(0, 66);
  }
  var hexNumber = stringOrNumber.toString(16);
  return '0x' + (zeros + hexNumber).substring(hexNumber.length - 1);
}

module.exports = bytes32;
