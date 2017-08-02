pragma solidity ^0.4.10;

// interface contract for multisig proxy contracts; see below for docs.
contract WalletInterface {

    // FUNCTIONS

    // TODO: document
    function changeOwner(address _from, address _to) external;
    function execute(address _to, uint _value, bytes _data) external returns (bytes32);
    function confirm(bytes32 _h) returns (bool);
}
