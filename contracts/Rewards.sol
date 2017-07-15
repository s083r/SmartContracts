pragma solidity ^0.4.11;

import {TimeHolderInterface as TimeHolder} from "./TimeHolderInterface.sol";
import {ERC20Interface as Asset} from "./ERC20Interface.sol";
import "./AssetsManagerInterface.sol";
import "./Managed.sol";
import "./RewardsEmitter.sol";

/**
 * @title Universal decentralized ERC20 tokens rewards contract.
 *
 * One ERC20 token serves as a shares, and any number of other ERC20 tokens serve as rewards(assets).
 * Rewards distribution are divided in periods, the only thing that shareholder needs to do in
 * order to take part in distribution is prove to rewards contract that he possess certain amount
 * of shares before period closes. Prove is made through allowing rewards contract to take shares
 * from the shareholder, and then depositing it through a call to rewards contract. Proof is needed
 * for every period.
 *
 * When calculating rewards distribution, resulting amount is always rounded down.
 *
 * In order to be able to deposit shares, user needs to create allowance for this contract, using
 * standard ERC20 approve() function, so that contract can take shares from the user, when user
 * makes a dpeosit.
 *
 * Users can withdraw their shares at any moment, but only remaining shares will be used for
 * rewards distribution.
 * Users can withdraw their accumulated rewards at any moment.
 *
 * State flow:
 *   1. Period closed, next period started;
 *   2. Reward assets registered for last closed preiod;
 *   3. Rewards distributed for closed period;
 *   4. Shares deposited into current period;
 *   5. Repeat.
 *
 * Note: all the non constant functions return false instead of throwing in case if state change
 * didn't happen yet.
 */
contract Rewards is Managed, RewardsEmitter {

    uint constant ERROR_REWARD_NOT_FOUND = 9000;
    uint constant ERROR_REWARD_INVALID_PARAMETER = 90001;
    uint constant ERROR_REWARD_INVALID_INVOCATION = 9002;
    uint constant ERROR_REWARD_INVALID_STATE = 9003;
    uint constant ERROR_REWARD_INVALID_PERIOD = 9004;
    uint constant ERROR_REWARD_NO_REWARDS_LEFT = 9005;
    uint constant ERROR_REWARD_ASSET_TRANSFER_FAILED = 9006;
    uint constant ERROR_REWARD_ALREADY_CALCULATED = 9007;
    uint constant ERROR_REWARD_CALCULATION_FAILED = 9008;
    uint constant ERROR_REWARD_CANNOT_CLOSE_PERIOD = 9009;
    uint constant ERROR_REWARD_ASSET_ALREADY_REGISTERED = 9010;

    StorageInterface.UInt closeInterval;
    StorageInterface.UInt maxSharesTransfer;
    StorageInterface.AddressAddressUIntMapping rewards;
    StorageInterface.AddressUIntMapping rewardsLeft;
    StorageInterface.UInt periods;
    StorageInterface.UIntBoolMapping closed;
    StorageInterface.UIntUIntMapping startDate;
    StorageInterface.UIntUIntMapping totalShares;
    StorageInterface.UIntUIntMapping shareholdersCount;
    StorageInterface.UIntUIntAddressMapping shareholders;
    StorageInterface.UIntAddressUIntMapping shares;
    StorageInterface.UIntAddressUIntMapping shareholdersId;
    StorageInterface.UIntAddressUIntMapping assetBalances;
    StorageInterface.UIntAddressAddressBoolMapping calculated;

    function Rewards(Storage _store, bytes32 _crate) StorageAdapter(_store, _crate) {
        closeInterval.init('closeInterval');
        maxSharesTransfer.init('maxSharesTransfer');
        rewards.init('rewards');
        rewardsLeft.init('rewardsLeft');
        periods.init('periods');
        closed.init('closed');
        startDate.init('startDate');
        totalShares.init('totalShares');
        shareholdersCount.init('shareholdersCount');
        shareholders.init('shareholders');
        shares.init('shares');
        shareholdersId.init('shareholdersId');
        assetBalances.init('assetBalances');
        calculated.init('calculated');
    }

    /**
     * Sets ContractManager contract and period minimum length.
     * Starts the first period.
     *
     * Can be set only once.
     *
     * @param _contractsManager contracts Manager contract address.
     * @param _closeIntervalDays period minimum length, in days.
     *
     * @return result code, @see Errors
     */
    function init(address _contractsManager, uint _closeIntervalDays) returns (uint) {
        if (store.get(periods) > 0) {
            return ERROR_REWARD_INVALID_STATE;
        }

        if(store.get(contractsManager) != 0x0) {
            return ERROR_REWARD_INVALID_STATE;
        }

        uint e = ContractsManagerInterface(_contractsManager).addContract(this, bytes32("Rewards"));
        if(OK != e) {
            return e;
        }

        store.set(periods,store.get(periods)+1);
        store.set(contractsManager,_contractsManager);
        store.set(closeInterval,_closeIntervalDays);
        store.set(shareholdersCount,0,1);
        store.set(startDate,0,now);
        store.set(maxSharesTransfer,30);

        return OK;
    }

    function setupEventsHistory(address _eventsHistory) onlyAuthorized returns (uint) {
        if (getEventsHistory() != 0x0) {
            return ERROR_REWARD_INVALID_STATE;
        }

        _setEventsHistory(_eventsHistory);
        return OK;
    }

    function getCloseInterval() constant returns(uint) {
        return store.get(closeInterval);
    }

    function setCloseInterval(uint _closeInterval) onlyAuthorized returns(uint) {
        store.set(closeInterval,_closeInterval);
        return OK;
    }

    function getMaxSharesTransfer() constant returns(uint) {
        return store.get(maxSharesTransfer);
    }

    function setMaxSharesTransfer(uint _maxSharesTransfer) onlyAuthorized returns (uint) {
        store.set(maxSharesTransfer,_maxSharesTransfer);
        return OK;
    }

    function getRewardsLeft(address shareholder) constant returns(uint) {
        return store.get(rewardsLeft,shareholder);
    }

    function periodsLength() constant returns(uint) {
        return store.get(periods);
    }

    function periodUnique(uint _period) constant returns(uint) {
        if(_period == lastPeriod()) {
            address timeHolder = ContractsManagerInterface(store.get(contractsManager)).getContractAddressByType(bytes32("TimeHolder"));
            return TimeHolder(timeHolder).shareholdersCount() - 1;
        }
        else {
            return store.get(shareholdersCount,_period) - 1;
        }
    }

    modifier onlyTimeHolder() {
        address timeHolder = ContractsManagerInterface(store.get(contractsManager)).getContractAddressByType(bytes32("TimeHolder"));
        if (msg.sender == timeHolder) {
            _;
        }
    }

    function getAssets() constant returns(address[] result) {
        address assetsManager = ContractsManagerInterface(store.get(contractsManager)).getContractAddressByType(bytes32("AssetsManager"));
        address chronoMint = ContractsManagerInterface(store.get(contractsManager)).getContractAddressByType(bytes32("LOCManager"));
        uint counter;
        uint i;
        uint assetsCount = AssetsManagerInterface(assetsManager).getAssetsCount();
        for(i=0;i<assetsCount;i++) {
            if(AssetsManagerInterface(assetsManager).isAssetOwner(AssetsManagerInterface(assetsManager).getSymbolById(i),chronoMint))
            counter++;
        }
        result = new address[](counter);
        counter = 0;
        for(i=0;i<assetsCount;i++) {
            if(AssetsManagerInterface(assetsManager).isAssetOwner(AssetsManagerInterface(assetsManager).getSymbolById(i),chronoMint)) {
                bytes32 symbol = AssetsManagerInterface(assetsManager).getSymbolById(i);
                result[counter] = AssetsManagerInterface(assetsManager).getAssetBySymbol(symbol);
                counter++;
            }
        }
        return result;
    }
    /**
     * Close current active period and start the new period.
     *
     * Can only be done if period was active longer than minimum length.
     *
     * @return success.
     */
    function closePeriod() returns (uint) {
        uint period = lastPeriod();
        if ((store.get(startDate,period) + (store.get(closeInterval) * 1 days)) > now) {
            return _emitError(ERROR_REWARD_CANNOT_CLOSE_PERIOD);
        }

        address timeHolder = ContractsManagerInterface(store.get(contractsManager)).getContractAddressByType(bytes32("TimeHolder"));
        // Add new period.
        store.set(periods,store.get(periods)+1);
        store.set(startDate,lastPeriod(),now);
        store.set(shareholdersCount,lastClosedPeriod(),TimeHolder(timeHolder).shareholdersCount());
        address[] memory assets = getAssets();
        if(assets.length != 0) {
            for(uint i = 0;i<assets.length;i++) {
                registerAsset(Asset(assets[i]));
            }
        }

        uint resultCode = storeDeposits(0);
        if (resultCode == OK) {
            _emitPeriodClosed();
        }

        return resultCode;
    }

    function getPartsCount() constant returns(uint) {
        uint period = lastClosedPeriod();
        uint _shareholdersCount = store.get(shareholdersCount,period);
        uint _maxSharesTransfer = store.get(maxSharesTransfer);
        if(!store.get(closed,period) && _shareholdersCount > _maxSharesTransfer) {
            if(_shareholdersCount % _maxSharesTransfer == 0)
                return _shareholdersCount / _maxSharesTransfer;
            else
                return _shareholdersCount / _maxSharesTransfer + 1;
        }
        return 0;
    }

    function getPeriodStartDate(uint _period) constant returns (uint) {
        return store.get(startDate, _period);
    }

    function storeDeposits(uint _part) returns (uint) {
        uint period = lastClosedPeriod();
        uint _maxSharesTransfer = store.get(maxSharesTransfer);
        uint _shareholdersCount = store.get(shareholdersCount,period);
        uint first = _part * _maxSharesTransfer + 1;
        if(first > _shareholdersCount) {
            return ERROR_REWARD_INVALID_INVOCATION;
        }

        uint last = first + _maxSharesTransfer;
        if(last >= _shareholdersCount) {
            last = _shareholdersCount;
        }

        address holder;
        address timeHolder = ContractsManagerInterface(store.get(contractsManager)).getContractAddressByType(bytes32("TimeHolder"));
        for(;first < last;first++) {
            holder = TimeHolder(timeHolder).shareholders(first);
            if(store.get(shares,period,holder) == 0) {
                uint holderShares = TimeHolder(timeHolder).shares(holder);
                store.set(shares,period,holder,holderShares);
                store.set(totalShares,period,store.get(totalShares,period)+holderShares);
            }
        }
        first = _part * _maxSharesTransfer + 1;
        address[] memory assets = getAssets();
        for(;first < last;first++) {
            holder = TimeHolder(timeHolder).shareholders(first);
            for(uint i = 0;i<assets.length;i++) {
                if(OK != calculateRewardFor(Asset(assets[i]),holder)) {
                    // TODO: AG (16-06-2017) cant use origin error code due to
                    // "Stack too deep, try removing local variables"
                    // Refatoring needed
                    _emitError(ERROR_REWARD_CALCULATION_FAILED);
                }
            }
        }
        if(store.get(totalShares,period) != TimeHolder(timeHolder).totalShares()) {
            return _emitError(ERROR_REWARD_INVALID_STATE);
        }

        store.set(closed,period,true);
        _emitDepositStored(_part);
        return OK;
    }

    function registerAsset(Asset _asset) returns (uint) {
        address timeHolder = ContractsManagerInterface(store.get(contractsManager)).getContractAddressByType(bytes32("TimeHolder"));
        if (TimeHolder(timeHolder).sharesContract() == _asset) {
            return _emitError(ERROR_REWARD_ASSET_ALREADY_REGISTERED);
        }

        uint period = lastClosedPeriod();
        if (store.get(assetBalances,period,_asset) != 0) {
            return _emitError(ERROR_REWARD_ASSET_ALREADY_REGISTERED);
        }

        store.set(assetBalances,period,_asset,_asset.balanceOf(this) - store.get(rewardsLeft,_asset));
        store.set(rewardsLeft,_asset,store.get(rewardsLeft,_asset) + store.get(assetBalances,period,_asset));

        _emitAssetRegistered(address(_asset));
        return OK;
    }

    function deposit(address _address, uint _amount, uint _total) onlyTimeHolder returns(uint) {
        if (store.get(periods) == 1) {
            return ERROR_REWARD_INVALID_PERIOD;
        }

        uint period = lastClosedPeriod();
        if(!store.get(closed,period)) {
            store.set(totalShares,period,store.get(totalShares,period) + _amount);
            if(store.get(shareholdersId,period,_address) > 0) {
                store.set(shares,period,_address,_total);
            }
            return OK;
        }
        return ERROR_REWARD_INVALID_PERIOD;
    }

    /**
     * Calculate and distribute reward of a specified registered rewards asset.
     *
     * Distribution is made for caller and last closed period.
     *
     * Can only be done once per asset per closed period.
     *
     * @param _assetAddress registered rewards asset contract address.
     *
     * @return success.
     */

    function calculateReward(address _assetAddress) internal returns (uint) {
        return calculateRewardForAddressAndPeriod(_assetAddress, msg.sender, lastClosedPeriod());
    }


    /**
     * Calculate and distribute reward of a specified registered rewards asset.
     *
     * Distribution is made for specified shareholder and last closed period.
     *
     * Can only be done once per asset per shareholder per closed period.
     *
     * This function meant to be used by some backend application to calculate rewards
     * for arbitrary shareholders.
     *
     * @param _assetAddress registered rewards asset contract address.
     * @param _address shareholder address.
     *
     * @return success.
     */

    function calculateRewardFor(address _assetAddress, address _address) internal returns (uint) {
        return calculateRewardForAddressAndPeriod(_assetAddress, _address, lastClosedPeriod());
    }

    /**
     * Calculate and distribute reward of a specified registered rewards asset.
     *
     * Distribution is made for caller and specified closed period.
     *
     * Can only be done once per asset per closed period.
     *
     * @param _assetAddress registered rewards asset contract address.
     * @param _period closed period to calculate.
     *
     * @return success.
     */

    function calculateRewardForPeriod(address _assetAddress, uint _period) internal returns (uint) {
        return calculateRewardForAddressAndPeriod(_assetAddress, msg.sender, _period);
    }


    /**
     * Calculate and distribute reward of a specified registered rewards asset.
     *
     * Distribution is made for specified shareholder and closed period.
     *
     * Can only be done once per asset per shareholder per closed period.
     *
     * @param _assetAddress registered rewards asset contract address.
     * @param _address shareholder address.
     * @param _period closed period to calculate.
     *
     * @return success.
     */
    function calculateRewardForAddressAndPeriod(address _assetAddress, address _address, uint _period) internal returns (uint e) {
        if (store.get(assetBalances,_period,_assetAddress) == 0) {
            return ERROR_REWARD_CALCULATION_FAILED;
        }

        if (store.get(calculated,_period,_assetAddress,_address)) {
            return ERROR_REWARD_ALREADY_CALCULATED;
        }

        uint reward = store.get(assetBalances,_period,_assetAddress) * store.get(shares,_period,_address) / store.get(totalShares,_period);
        store.set(rewards,_assetAddress,_address,store.get(rewards,_assetAddress,_address) + reward);
        store.set(calculated,_period,_assetAddress,_address,true);

        return OK;
    }

    /**
     * Withdraw accumulated reward of a specified rewards asset.
     *
     * Withdrawal is made for caller and total amount.
     *
     * @param _asset registered rewards asset contract address.
     *
     * @return success.
     */
    function withdrawRewardTotal(Asset _asset) returns (uint) {
        return withdrawRewardFor(_asset, msg.sender, rewardsFor(_asset, msg.sender));
    }

    /**
     * Withdraw all accumulated rewards.
     *
     * Withdrawals are made for caller and total amount.
     *
     * @return result code.
     */
    function withdrawAllRewardsTotal() returns (uint) {
        address[] memory assets = getAssets();
        for (uint i=0; i < assets.length; i++) {
            Asset asset = Asset(assets[i]);
            uint rewards = rewardsFor(asset, msg.sender);
            if (rewards > 0) {
                uint result = withdrawRewardFor(asset, msg.sender, rewards);
                if (OK != result) {
                    return result;
                }
            }
        }

        return OK;
    }

    /**
     * Withdraw accumulated reward of a specified rewards asset.
     *
     * Withdrawal is made for specified shareholder and total amount.
     *
     * This function meant to be used by some backend application to send rewards
     * for arbitrary shareholders.
     *
     * @param _asset registered rewards asset contract address.
     * @param _address shareholder address to withdraw for.
     *
     * @return success.
     */
    function withdrawRewardTotalFor(Asset _asset, address _address) returns (uint) {
        return withdrawRewardFor(_asset, _address, rewardsFor(_asset, _address));
    }

    /**
     * Withdraw accumulated reward of a specified rewards asset.
     *
     * Withdrawal is made for caller and specified amount.
     *
     * @param _asset registered rewards asset contract address.
     * @param _amount amount to withdraw.
     *
     * @return success.
     */
    function withdrawReward(Asset _asset, uint _amount) returns (uint) {
        return withdrawRewardFor(_asset, msg.sender, _amount);
    }

    /**
     * Withdraw accumulated reward of a specified rewards asset.
     *
     * Withdrawal is made for specified shareholder and specified amount.
     *
     * @param _asset registered rewards asset contract address.
     * @param _address shareholder address to withdraw for.
     * @param _amount amount to withdraw.
     *
     * @return success.
     */
    function withdrawRewardFor(Asset _asset, address _address, uint _amount) returns (uint) {
        if (store.get(rewardsLeft,_asset) == 0) {
            return _emitError(ERROR_REWARD_NO_REWARDS_LEFT);
        }

        // Assuming that transfer(amount) of unknown asset may not result in exactly
        // amount being taken from rewards contract(i. e. fees taken) we check contracts
        // balance before and after transfer, and proceed with the difference.
        uint startBalance = _asset.balanceOf(this);
        if (!_asset.transfer(_address, _amount)) {
            return _emitError(ERROR_REWARD_ASSET_TRANSFER_FAILED);
        }

        uint endBalance = _asset.balanceOf(this);
        uint diff = startBalance - endBalance;
        if (rewardsFor(_asset, _address) < diff) {
            throw;
        }

        store.set(rewards,_asset,_address,store.get(rewards,_asset,_address) - diff);
        store.set(rewardsLeft,_asset, store.get(rewardsLeft,_asset) - diff);

        _emitWithdrawnReward(address(_asset), _address, _amount);
        return OK;
    }

    function withdrawn(address _address, uint _amount, uint _total)  returns (uint) {
        if (store.get(periods) == 1) {
            return ERROR_REWARD_INVALID_PERIOD;
        }

        uint period = lastClosedPeriod();
        if(store.get(closed,period)) {
            return ERROR_REWARD_INVALID_PERIOD;
        }

        store.set(totalShares,period,store.get(totalShares,period) - _amount);
        if(store.get(shareholdersId,period,_address) > 0) {
            store.set(shares,period,_address,_total);
        }

        return OK;
    }

    /**
     * Returns proven amount of shares possessed by a shareholder in a period.
     *
     * @param _address shareholder address.
     * @param _period period.
     *
     * @return shares amount.
     */
    function depositBalanceInPeriod(address _address, uint _period) constant returns (uint) {
        if(_period == lastPeriod()) {
            address timeHolder = ContractsManagerInterface(store.get(contractsManager)).getContractAddressByType(bytes32("TimeHolder"));
            return TimeHolder(timeHolder).shares(_address);
        }
        return store.get(shares,_period,_address);
    }

    /**
     * Returns total proven amount of shares possessed by shareholders in a period.
     *
     * @param _period period.
     *
     * @return shares amount.
     */
    function totalDepositInPeriod(uint _period) constant returns(uint) {
        if(_period == lastPeriod()) {
            address timeHolder = ContractsManagerInterface(store.get(contractsManager)).getContractAddressByType(bytes32("TimeHolder"));
            return TimeHolder(timeHolder).totalShares();
        }
        return store.get(totalShares,_period);
    }

    /**
     * Returns current active period.
     *
     * @return period.
     */
    function lastPeriod() constant returns(uint) {
        return store.get(periods) - 1;
    }

    /**
     * Returns last closed period.
     *
     * @dev throws in case if there is no closed periods yet.
     *
     * @return period.
     */
    function lastClosedPeriod() constant returns(uint) {
        if (store.get(periods) == 1) {
            throw;
        }
        return store.get(periods) - 2;
    }

    /**
     * Check if period is closed or not.
     *
     * @param _period period.
     *
     * @return period closing state.
     */
    function isClosed(uint _period) constant returns(bool) {
        return store.get(closed,_period);
    }

    /**
     * Returns amount of accumulated rewards assets in a period.
     * Always 0 for active period.
     *
     * @param _assetAddress rewards asset contract address.
     * @param _period period.
     *
     * @return assets amount.
     */
    function assetBalanceInPeriod(address _assetAddress, uint _period) constant returns(uint) {
        return store.get(assetBalances,_period,_assetAddress);
    }

    /**
     * Check if shareholder have calculated rewards in a period.
     *
     * @param _assetAddress rewards asset contract address.
     * @param _address shareholder address.
     * @param _period period.
     *
     * @return reward calculation state.
     */
    function isCalculatedFor(address _assetAddress, address _address, uint _period) constant returns(bool) {
        return store.get(calculated,_period,_assetAddress,_address);
    }

    /**
     * Returns accumulated asset rewards available for withdrawal for shareholder.
     *
     * @param _assetAddress rewards asset contract address.
     * @param _address shareholder address.
     *
     * @return rewards amount.
     */
    function rewardsFor(address _assetAddress, address _address) constant returns(uint) {
        return store.get(rewards, _assetAddress, _address);
    }

    // Even emitter util functions

    function _emitWithdrawnReward(address asset, address addr, uint amount) {
        Rewards(getEventsHistory()).emitWithdrawnReward(asset, addr, amount);
    }

    function _emitWithdrawn(address addr, uint amount, uint total) {
        Rewards(getEventsHistory()).emitWithdrawn(addr, amount, total);
    }

    function _emitDepositStored(uint _part) {
        Rewards(getEventsHistory()).emitDepositStored(_part);
    }

    function _emitAssetRegistered(address assetAddress) {
        Rewards(getEventsHistory()).emitAssetRegistered(assetAddress);
    }

    function _emitPeriodClosed() {
        Rewards(getEventsHistory()).emitPeriodClosed();
    }

    function _emitError(uint e) returns (uint) {
        Rewards(getEventsHistory()).emitError(e);
        return e;
    }

    function() {
        throw;
    }
}
