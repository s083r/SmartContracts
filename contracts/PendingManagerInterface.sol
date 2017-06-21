pragma solidity ^0.4.8;
import "./Errors.sol";

contract PendingManagerInterface {
    function addTx(bytes32 _hash, bytes _data, address _to, address _sender) returns (Errors.E);
}
