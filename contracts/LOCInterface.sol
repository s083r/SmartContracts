pragma solidity ^0.4.8;

contract LOCInterface {
  function getContractOwner() returns(address);
  function getIssued() returns(uint);
  function getIssueLimit() returns(uint);
}
