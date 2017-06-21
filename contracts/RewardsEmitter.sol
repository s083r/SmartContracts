pragma solidity ^0.4.8;

import './MultiEventsHistoryAdapter.sol';
import "./Errors.sol";

contract RewardsEmitter is MultiEventsHistoryAdapter {
    using Errors for Errors.E;

    event WithdrawnSuccess(address addr, uint amount, uint total);
    event WithdrawnRewardSuccess(address asset, address addr, uint amountReward);
    event DepositStored(uint _part);
    event AssetRegistered(address assetAddress);
    event Error(address indexed self, uint indexed errorCode);

    function emitWithdrawnReward(address asset, address addr, uint amount) {
        WithdrawnRewardSuccess(asset, addr, amount);
    }

    function emitWithdrawn(address addr, uint amount, uint total) {
        WithdrawnSuccess(addr, amount, total);
    }

    function emitDepositStored(uint _part) {
        DepositStored(_part);
    }

    function emitAssetRegistered(address assetAddress) {
        AssetRegistered(assetAddress);
    }

    function emitError(Errors.E e) {
        Error(_self(), e.code());
    }
}
