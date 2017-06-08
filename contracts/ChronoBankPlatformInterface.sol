pragma solidity ^0.4.8;

contract ChronoBankPlatformInterface {
    mapping(bytes32 => address) public proxies;
    function name(bytes32 _symbol) returns(string);
    function setProxy(address _address, bytes32 _symbol);
    function isOwner(address _owner, bytes32 _symbol) returns(bool);
    function totalSupply(bytes32 _symbol) returns(uint);
    function balanceOf(address _holder, bytes32 _symbol) returns(uint);
    function allowance(address _from, address _spender, bytes32 _symbol) returns(uint);
    function baseUnit(bytes32 _symbol) returns(uint8);
    function proxyTransferWithReference(address _to, uint _value, bytes32 _symbol, string _reference, address _sender) returns(bool);
    function proxyTransferFromWithReference(address _from, address _to, uint _value, bytes32 _symbol, string _reference, address _sender) returns(bool);
    function proxyApprove(address _spender, uint _value, bytes32 _symbol, address _sender) returns(bool);
    function issueAsset(bytes32 _symbol, uint _value, string _name, string _description, uint8 _baseUnit, bool _isReissuable);
    function reissueAsset(bytes32 _symbol, uint _value) returns(bool);
    function revokeAsset(bytes32 _symbol, uint _value) returns(bool);
    function isReissuable(bytes32 _symbol) returns(bool);
}
