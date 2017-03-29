pragma solidity ^0.4.8;

contract ChronoMintInterface {
  function setLOCIssued(address _LOCaddr, uint _issued) returns(bool);
}
