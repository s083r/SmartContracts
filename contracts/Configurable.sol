pragma solidity ^0.4.8;

import "./Owned.sol";

contract Configurable is Owned {
  enum Setting {name,website,controller,issueLimit,issued,redeemed,publishedHash1,expDate,timeProxyContract,rewardsContract,exchangeContract,proxyContract,securityPercentage,liquidityPercentage,insurancePercentage,insuranceDuration,lhProxyContract}
  enum Status {maintenance, active, suspended, bankrupt}
  mapping(uint => bytes32) internal settings;
  mapping(uint => uint) internal values;

  function getValue(uint name) constant returns(uint) {
    return values[name];
  }

  function getString(uint name) constant returns(bytes32) {
    return settings[name];
  }

  function setString(uint name, bytes32 value) onlyContractOwner {
    settings[name] = value;
  }

  function setValue(uint name, uint value) onlyContractOwner {
    values[name] = value;
  }

}
