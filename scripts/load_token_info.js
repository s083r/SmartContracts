var Web3 = require('web3');

var web3 = new Web3(new Web3.providers.HttpProvider("https://mainnet.infura.io/TODO"));

const ABI =[{"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_spender","type":"address"},{"name":"_value","type":"uint256"}],"name":"approve","outputs":[{"name":"success","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"name":"supply","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_from","type":"address"},{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transferFrom","outputs":[{"name":"success","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"_owner","type":"address"}],"name":"balanceOf","outputs":[{"name":"balance","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"symbol","outputs":[{"name":"","type":"string"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transfer","outputs":[{"name":"success","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"_owner","type":"address"},{"name":"_spender","type":"address"}],"name":"allowance","outputs":[{"name":"remaining","type":"uint256"}],"payable":false,"type":"function"},{"anonymous":false,"inputs":[{"indexed":true,"name":"from","type":"address"},{"indexed":true,"name":"to","type":"address"},{"indexed":false,"name":"value","type":"uint256"}],"name":"Transfer","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"from","type":"address"},{"indexed":true,"name":"spender","type":"address"},{"indexed":false,"name":"value","type":"uint256"}],"name":"Approval","type":"event"}]

var Token = web3.eth.contract(ABI);

var infos = [
  {address:"0x86fa049857e0209aa7d9e616f7eb3b3b78ecfdb0", web:"https://eos.io/", icon:"https://etherscan.io/token/images/eos_28.png"},
  {address:"0x9a642d6b3368ddc662CA244bAdf32cDA716005BC", web:"https://qtum.org/", icon:"https://etherscan.io/token/images/qtum_28.png"},
  {address:"0x888666CA69E0f178DED6D75b5726Cee99A87D698", web:"https://ico.iconomi.net/", icon:"https://etherscan.io/token/images/ICONOMI.png"},
  {address:"0x6810e776880c02933d47db1b9fc05908e5386b96", web:"https://gnosis.pm/", icon:"https://etherscan.io/token/images/gnosis.png"},
  {address:"0xa74476443119A942dE498590Fe1f2454d7D4aC0d", web:"https://golem.network/", icon:"https://etherscan.io/token/images/golem.png"},
  {address:"0xe94327d07fc17907b4db788e5adf2ed424addff6", web:"https://www.augur.net/", icon:"https://etherscan.io/token/images/augur.png"},
  {address:"0x744d70fdbe2ba4cf95131626614a1763df805b9e", web:"https://status.im/", icon:"https://etherscan.io/token/images/status.png"},
  {address:"0xc66ea802717bfb9833400264dd12c2bceaa34a6d", web:"https://makerdao.com/", icon:"https://etherscan.io/token/images/mkr-etherscan-35.png"},
  {address:"0xe0b7927c4af23765cb51314a0e0521a9645f0e2a", web:"https://digix.io/", icon:"https://etherscan.io/token/images/digix-logo.png"},
  {address:"0xd26114cd6EE289AccF82350c8d8487fedB8A0C07", web:"https://omg.omise.co/", icon:"https://etherscan.io/token/images/omise.png"},
  {address:"0x0d8775f648430679a709e98d2b0cb6250d2887ef", web:"https://basicattentiontoken.org/", icon:"https://etherscan.io/token/images/bat.png"},
  {address:"0xB97048628DB6B661D4C2aA833e95Dbe1A905B280", web:"http://www.tenx.tech/", icon:"https://etherscan.io/token/images/tenx_28.png"},
  {address:"0x1f573d6fb3f13d689ff844b4ce37794d79a7ff1c", web:"https://bancor.network/", icon:"https://etherscan.io/token/images/bancor.png"},
  {address:"0xaec2e87e0a235266d9c5adc9deb4b2e29b54d009", web:"https://singulardtv.com/", icon:"https://etherscan.io/token/images/sngls.png"},
  {address:"0xaf30d2a7e90d7dc361c8c4585e9bb7d2f6f15bc7", web:"https://firstblood.io/", icon:"https://etherscan.io/token/images/firstblood.png"},
  {address:"0x960b236A07cf122663c4303350609A66A7B288C0", web:"https://aragon.network/", icon:"https://etherscan.io/token/images/aragon.png"},
  {address:"0x41e5560054824ea6b0732e656e3ad64e20e94e45", web:"https://www.civic.com/", icon:"https://etherscan.io/token/images/civic_28.png"},
  {address:"0x419d0d8bdd9af5e606ae2232ed285aff190e711b", web:"https://www.funfair.io/", icon:"https://etherscan.io/token/images/funfair.png"},
  {address:"0x08711d3b02c8758f2fb3ab4e80228418a7f8e39c", web:"https://edgeless.io/", icon:"https://etherscan.io/token/images/edgeless.png"},
  {address:"0x667088b212ce3d06a1b553a7221E1fD19000d9aF", web:"https://wings.ai/", icon:"https://etherscan.io/token/images/wingsdao.png"},
  {address:"0x607F4C5BB672230e8672085532f7e901544a7375", web:"http://iex.ec/", icon:"https://etherscan.io/token/images/iexec.png"},
  {address:"0x5c543e7AE0A1104f78406C340E9C64FD9fCE5170", web:"http://www.vslice.io/", icon:"https://etherscan.io/token/images/vslice.png"},
  {address:"0x4DF812F6064def1e5e029f1ca858777CC98D2D81", web:"https://www.xaurum.org/", icon:"https://etherscan.io/token/images/Xaurum30x30.png"},
  {address:"0xb64ef51c888972c908cfacf59b47c1afbc0ab8ac", web:"https://storj.io/", icon:"https://etherscan.io/token/images/storj2.png"},
  {address:"0xBEB9eF514a379B997e0798FDcC901Ee474B6D9A1", web:"https://melonport.com/", icon:"https://etherscan.io/token/images/melon.jpg"},
  {address:"0xcbcc0f036ed4788f63fc0fee32873d6a7487b908", web:"https://humaniq.co/", icon:"https://etherscan.io/token/images/humaniq.png"},
  {address:"0xe7775a6e9bcf904eb39da2b68c5efb4f9360e08c", web:"https://taas.fund/", icon:"https://etherscan.io/token/images/TAAS.png"},
  {address:"0xd0d6d6c5fe4a677d343cc433536bb717bae167dd", web:"https://adtoken.com/", icon:"https://etherscan.io/token/images/adtoken.png"},
  {address:"0xaaaf91d9b90df800df4f55c205fd6989c977e73a", web:"https://tokencard.io/#token", icon:"https://etherscan.io/token/images/tokencard.png"},
  {address:"0xcb94be6f13a1182e4a4b6140cb7bf2025d28e41b", web:"https://www.wetrust.io/", icon:"https://etherscan.io/token/images/wetrust.png"},
  {address:"0x7c5a0ce9267ed19b22f8cae653f198e3e8daf098", web:"https://santiment.net/", icon:"https://etherscan.io/token/images/san_28.png"},
  {address:"0xff3519eeeea3e76f1f699ccce5e23ee0bdda41ac", web:"http://blockchain.capital/", icon:"https://etherscan.io/token/images/bcap.png"},
  {address:"0x6531f133e6deebe7f2dce5a0441aa7ef330b4e53", web:"https://chronobank.io/", icon:"https://etherscan.io/token/images/Chronobank.png"},
  {address:"0xD8912C10681D8B21Fd3742244f44658dBA12264E", web:"https://plutus.it/", icon:"https://etherscan.io/token/images/Pluton.png"},
  {address:"0xcfb98637bcae43C13323EAa1731cED2B716962fD", web:"https://nimiq.com/", icon:"https://etherscan.io/token/images/nimiq_28.png"},
  {address:"0xf7b098298f7c69fc14610bf71d5e02c60792894c", web:"https://matchpool.co/", icon:"https://etherscan.io/token/images/Matchpool.png"},
  {address:"0xb63b606ac810a52cca15e44bb630fd42d8d1d83d", web:"http://www.mona.co/", icon:"https://etherscan.io/token/images/Monaco.png"},
  {address:"0xb9e7f8568e08d5659f5d29c4997173d84cdf2607", web:"https://swarm.city/", icon:"https://etherscan.io/token/images/SwarmCity.png"},
  {address:"0xfa05A73FfE78ef8f1a739473e462c54bae6567D9", web:"https://lunyr.com/", icon:"https://etherscan.io/token/images/lunyr.png"},
  {address:"0x0abdace70d3790235af448c88547603b945604ea", web:"https://district0x.io/", icon:"https://etherscan.io/token/images/district0x.png"}
]

var ipfsHashes = [
  {"Name":"Chronobank.png","Hash":"QmaiBJJLnuNtTcMzxJ3F3hEEok897UQt5s4jBGdVhZLXux"},
  {"Name":"ICONOMI.png","Hash":"QmPeuRT8W2UvCvzVkus2npTxERqA2VYDbUCjPB2W9AUpP3"},
  {"Name":"Matchpool.png","Hash":"Qmb2KfE3L7MgawaCFN5AKgWoAnQ5d14HDkxFeRWQwWPHcf"},
  {"Name":"Monaco.png","Hash":"QmPwDQqkTEm2f2hRATYJcrtwq1g2jRWELF99UsCfu2FeUv"},
  {"Name":"Pluton.png","Hash":"QmYRxGvYmt6r9PKk32vBu1ojW9UJ5AuJeaS43JuEZGfsbX"},
  {"Name":"SwarmCity.png","Hash":"QmbU3af2LUFLfYGPUu7vM9kxgpj2SKPwtmmGZa7ZVBy2oe"},
  {"Name":"TAAS.png","Hash":"QmYB7KR765hYD6WFxsMKERfRqA7B7QFbz8EdeBnjo6ADt7"},
  {"Name":"Xaurum30x30.png","Hash":"QmfCLVcwUnSZ2Wg7rgL5EEBvNFVMu3JyC22QH4e1sguDvR"},
  {"Name":"adtoken.png","Hash":"QmW4mmYJYZJuJG7gzZujFipKB9ozTY93rqaidpb4qHFBHN"},
  {"Name":"aragon.png","Hash":"Qma5hUgxYFjAGnDoXzP7gMEVhnJFh1TT9HpGtP6imPHnsH"},
  {"Name":"augur.png","Hash":"Qma5mhr5Qezdis1cSDmj8XbdhJB3m8H76v9AbAYvmyLMiK"},
  {"Name":"bancor.png","Hash":"QmTbSfV12hekL488iq1EKPbuw6pBSqjsc34FCvsvAXvyNH"},
  {"Name":"bat.png","Hash":"QmdLhnt488BTcagESeG85BA93z65jLZuNuXboLvCjSZxku"},
  {"Name":"bcap.png","Hash":"QmUSoj1ZQuPLkmhjmDjhZJdYyVtejG5fpYui3k2y9kj6r4"},
  {"Name":"civic_28.png","Hash":"QmU4sdTkPkXYfTXKVJR6UtneLJCPX7hyUYMvhR5EuJRM9G"},
  {"Name":"digix-logo.png","Hash":"QmaSbEPyQkg4MJXRRzgrXiuAWEj255MQcDcaJFYxfX69Vd"},
  {"Name":"district0x.png","Hash":"QmWh2rkhmAvMGzkXenW8zJkH7MJ4n1zvWBQHYHwko1VFHy"},
  {"Name":"edgeless.png","Hash":"QmUEu87mfHJkPXy8wzqzuiyjdJgb4voKtf7AR5Rm7YExee"},
  {"Name":"eos_28.png","Hash":"QmbCXCoA5jr8TqtpYpwYfGJAwghWkPJpbhA81Y6EF8rnJP"},
  {"Name":"firstblood.png","Hash":"QmWQNeJf9TFmRg4frLn8hgpMnESbX3qCDE8V3A4TZgCbgk"},
  {"Name":"funfair.png","Hash":"QmabGwMywTKdebpex3nrwG9bxJ4E1TL4FzN2tQPK5y5zXc"},
  {"Name":"gnosis.png","Hash":"Qma1wsChiLjjyrXbDaZMFjP6QvPnn4DUYFSDAadgmmtSPz"},
  {"Name":"golem.png","Hash":"QmeEMxTuZ6zNFCa7cnxaoerUG6WhB8XUWZFYB1tyoYYiGo"},
  {"Name":"humaniq.png","Hash":"QmbekxjcCQ3LadGnReb3tJhJ1SZaz4jBhA6rSWP5BVfPNF"},
  {"Name":"iexec.png","Hash":"QmProETnBnRZ464ey7H4Cg2ckgjPZ3DLY2GkJVbwV61quF"},
  {"Name":"lunyr.png","Hash":"QmcC8gm47XjoZZVky5ewLCRFrrGxNcwffyV6uiUaMLWRNr"},
  {"Name":"melon.jpg","Hash":"QmVjBKrYCpgqm65Dhm2hzNBYNq21VFPPsRQASwEgT1G3kY"},
  {"Name":"mkr-etherscan-35.png","Hash":"QmY3PgNy3GhhRFLDkUGYjpngZQ9ME8wQES7yn5RrEg5Mu6"},
  {"Name":"nimiq_28.png","Hash":"QmRJ88EhGoMhSdKmZfxxkk2FzwN4BC8usjQ8oQ3NAjuGRk"},
  {"Name":"omise.png","Hash":"Qmf7MWpxYj8MFsLrWQ62FoCu6YovBoAYMBGFpQEZtV2LKL"},
  {"Name":"qtum_28.png","Hash":"QmPHz5PyLpDC3y89TGR28raGBtoCWEtNj6ean4vLkgYWCf"},
  {"Name":"san_28.png","Hash":"QmbKQbg69ZKSGLWbWrZLh9fPRxFsYK4723hyTqNYcPvzcv"},
  {"Name":"sngls.png","Hash":"QmV2JKqKEEXSr6jhVwzavddfKgb42JijK8krcpLghJUbFT"},
  {"Name":"status.png","Hash":"QmbGdjHnhX1Y2ziR3xSoseC7APavjpKg6TW4M5xfWvCmcZ"},
  {"Name":"storj2.png","Hash":"QmYCkohKPM3VevVAr5ruRB1n7fj3GUKC3iw9gBbCP84NFz"},
  {"Name":"tenx_28.png","Hash":"QmWss8yxspqTD7HhCA2gcveg4g6aZtUufdiDkD6iHqmnsz"},
  {"Name":"tokencard.png","Hash":"QmSW6VXYYatRAZ9ak1KGPS9UX82tdeum32MnLHFxq9bQRw"},
  {"Name":"vslice.png","Hash":"QmSmGZZwwtmtva9ca6Mmh3a2weP4ZTzmAz4rh5ray9Nwko"},
  {"Name":"wetrust.png","Hash":"QmZWBaJe4RCNuAk7jP2UZa2esBuH3Y72ng4MTrmhxaQaXc"},
  {"Name":"wingsdao.png","Hash":"QmXKUw4CQHjg9zvEgu6XJkkygr9XzFE5eQMKcrTSkSL8tS"}
]

var validInfo = [];
for (info of infos) {
  try {
    var t = Token.at(info.address);

    info.name = t.name.call();
    info.symbol = t.symbol.call();
    info.decimals = t.decimals().toNumber();

    for (ipfs of ipfsHashes) {
      if (info.icon.includes(ipfs.Name)) {
        info.ipfshash = ipfs.Hash;
      }
    }

    validInfo.push(info);
  } catch(e) {
    console.error("Unable load info for ", info.address, "[", info.web, "]")
  }
}

console.log(validInfo);
