pragma solidity ^0.4.8;

import "./TimeHolder.sol";
import "./Owned.sol";

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
contract Rewards is Owned {
// Structure of a particular period.
    struct Period {
    uint startDate;                                           // Period starting date, also
    uint totalShares;
    uint shareholdersCount;
    bool isClosed;
    mapping(address => uint) shares;                          // Shareholder shares in period.
    mapping(uint => address) shareholders;
    mapping(address => uint) shareholdersId;
    mapping(address => uint) assetBalances;                   // Rewards for distribution.
    mapping(address => mapping(address => bool)) calculated;  // Flag that indicates that rewards
    // already distributed for holder.
    }

    address public timeHolder;

    address[] public assets;
    mapping(address => uint) assetsId;
    uint[] deletedIds;

// Minimum period length, in days.
    uint public closeInterval;

// Maximum shares which can be transfered in on TX
    uint public maxSharesTransfer = 30;

// Asset rewards accumulated for shareholder.
    mapping(address => mapping(address => uint)) rewards;

// Asset rewards available for withdrawal from all previous periods.
    mapping(address => uint) public rewardsLeft;

// Periods list. Last one is always active.
    Period[] public periods;

// Period closed/started.
    event PeriodClosed();

// Rewards asset registered to distribute accumulated balance.
    event AssetRegistration(address indexed assetAddress, uint balance);

// Rewards from a period distributed for a shareholder.
    event CalculateReward(address indexed assetAddress, address indexed who, uint reward);

// Reward withdrawn for a shareholder.
    event WithdrawReward(address indexed assetAddress, address indexed who, uint amount);

// Something went wrong.
    event Error(bytes32 message);

/**
 * Sets TimeHolder contract and period minimum length.
 * Starts the first period.
 *
 * Can be set only once.
 *
 * @param _timeHolder TIME deposit contract address.
 * @param _closeIntervalDays period minimum length, in days.
 *
 * @return success.
 */
    function init(address _timeHolder, uint _closeIntervalDays) returns(bool) {
        if (periods.length > 0) {
            return false;
        }

        timeHolder = _timeHolder;
        closeInterval = _closeIntervalDays;
        periods.length++;
        periods[0].shareholdersCount = 1;
        periods[0].startDate = now;
        assets.push(0);

        return true;
    }

    function setCloseInterval(uint _closeInterval) onlyContractOwner returns(bool) {
        closeInterval = _closeInterval;
        return true;
    }

    function setMaxSharesTransfer(uint _maxSharesTransfer) onlyContractOwner returns(bool) {
        maxSharesTransfer = _maxSharesTransfer;
        return true;
    }

    function periodsLength() constant returns(uint) {
        return periods.length;
    }

    function periodUnique(uint _period) constant returns(uint) {
        if(_period == lastPeriod())
            return TimeHolder(timeHolder).shareholdersCount() - 1;
        else
            return periods[_period].shareholdersCount - 1;
    }

    modifier onlyTimeHolder() {
        if (msg.sender == timeHolder) {
            _;
        }
    }
/**
 * Close current active period and start the new period.
 *
 * Can only be done if period was active longer than minimum length.
 *
 * @return success.
 */
    function closePeriod() returns(bool) {
        Period period = periods[lastPeriod()];

        if ((period.startDate + (closeInterval * 1 days)) > now) {
            Error("Cannot close period yet");
            return false;
        }

    // Add new period.
        periods.length++;
        periods[lastPeriod()].startDate = now;
        periods[lastClosedPeriod()].shareholdersCount = TimeHolder(timeHolder).shareholdersCount();
        //periods[lastClosedPeriod()].totalShares = TimeHolder(timeHolder).totalShares();
        if(assets.length != 0) {
            for(uint i = 1;i<assets.length;i++) {
                registerAsset(Asset(assets[i]));
            }
        }

        return storeDeposits(0);
    }

    function getPartsCount() constant returns(uint) {
        Period period = periods[lastClosedPeriod()];
        if(!period.isClosed && period.shareholdersCount > maxSharesTransfer) {
            if(period.shareholdersCount % maxSharesTransfer == 0)
                return period.shareholdersCount / maxSharesTransfer;
            else
                return period.shareholdersCount / maxSharesTransfer + 1;
        }
        return 0;
    }

    function storeDeposits(uint _part) returns(bool) {
        uint first = _part * maxSharesTransfer + 1;
        if(first > periods[lastClosedPeriod()].shareholdersCount)
            throw;
        uint last = first + maxSharesTransfer;
        if(last >= periods[lastClosedPeriod()].shareholdersCount)
            last = periods[lastClosedPeriod()].shareholdersCount;
        address holder;
        for(;first < last;first++) {
            holder = TimeHolder(timeHolder).shareholders(first);
            if(periods[lastClosedPeriod()].shares[holder] == 0) {
                    periods[lastClosedPeriod()].shares[holder] = TimeHolder(timeHolder).shares(holder);
                    periods[lastClosedPeriod()].totalShares += periods[lastClosedPeriod()].shares[holder];
            }
        }
        first = _part * maxSharesTransfer + 1;
        for(;first < last;first++) {
            holder = TimeHolder(timeHolder).shareholders(first);
            for(uint i = 1;i<assets.length;i++) {
                calculateRewardFor(Asset(assets[i]),holder);
            }
        }
        if(periods[lastClosedPeriod()].totalShares == TimeHolder(timeHolder).totalShares()) {
            periods[lastClosedPeriod()].isClosed = true;
            PeriodClosed();
            return true;
        }
        return false;
    }

    function addAsset(address _asset) onlyContractOwner returns(bool) {
        if(_asset != 0x0 && assetsId[_asset] == 0) {
            assetsId[_asset] = assets.length;
            assets.push(_asset);
            return true;
        }
        return false;
    }

    function registerAsset(Asset _asset) returns(bool) {
        if (TimeHolder(timeHolder).sharesContract() == _asset) {
            Error("Asset is already registered");
            return false;
        }
        Period period = periods[lastClosedPeriod()];
        if (period.assetBalances[_asset] != 0) {
            Error("Asset is already registered");
            return false;
        }

        period.assetBalances[_asset] = _asset.balanceOf(this) - rewardsLeft[_asset];
        rewardsLeft[_asset] += period.assetBalances[_asset];

        AssetRegistration(_asset, period.assetBalances[_asset]);
        return true;
    }

    function deposit(address _address, uint _amount, uint _total) onlyTimeHolder returns(bool) {
        if (periods.length == 1) {
            return false;
        }
        Period period = periods[lastClosedPeriod()];
        if(!period.isClosed) {
            period.totalShares += _amount;
            if(period.shareholdersId[_address] > 0) {
                period.shares[_address] = _total;
            }
            return true;
        }
        return false;
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
    function calculateReward(address _assetAddress) internal returns(bool) {
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
    function calculateRewardFor(address _assetAddress, address _address) internal returns(bool) {
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
    function calculateRewardForPeriod(address _assetAddress, uint _period) internal returns(bool) {
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
    function calculateRewardForAddressAndPeriod(address _assetAddress, address _address, uint _period) internal returns(bool) {
        Period period = periods[_period];
        //if(period.isClosed) {
            if (period.assetBalances[_assetAddress] == 0) {
                Error("Reward calculation failed");
                return false;
            }

            if (period.calculated[_assetAddress][_address]) {
                Error("Reward is already calculated");
                return false;
            }

            uint reward = period.assetBalances[_assetAddress] * period.shares[_address] / period.totalShares;
            rewards[_assetAddress][_address] += reward;
            period.calculated[_assetAddress][_address] = true;

            CalculateReward(_assetAddress, _address, reward);
            return true;
        //}
        return false;
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
    function withdrawRewardTotal(Asset _asset) returns(bool) {
        return withdrawRewardFor(_asset, msg.sender, rewardsFor(_asset, msg.sender));
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
    function withdrawRewardTotalFor(Asset _asset, address _address) returns(bool) {
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
    function withdrawReward(Asset _asset, uint _amount) returns(bool) {
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
    function withdrawRewardFor(Asset _asset, address _address, uint _amount) returns(bool) {
        if (rewardsLeft[_asset] == 0) {
            Error("No rewards left");
            return false;
        }

    // Assuming that transfer(amount) of unknown asset may not result in exactly
    // amount being taken from rewards contract(i. e. fees taken) we check contracts
    // balance before and after transfer, and proceed with the difference.
        uint startBalance = _asset.balanceOf(this);
        if (!_asset.transfer(_address, _amount)) {
            Error("Asset transfer failed");
            return false;
        }

        uint endBalance = _asset.balanceOf(this);
        uint diff = startBalance - endBalance;
        if (rewardsFor(_asset, _address) < diff) {
            throw;
        }

        rewards[_asset][_address] -= diff;
        rewardsLeft[_asset] -= diff;

        WithdrawReward(_asset, _address, _amount);
        return true;
    }

    function withdrawn(address _address, uint _amount, uint _total) onlyTimeHolder returns(bool) {

        if (periods.length == 1) {
            return false;
        }
        Period period = periods[lastClosedPeriod()];
        if(!period.isClosed) {

            period.totalShares -= _amount;
            if(period.shareholdersId[_address] > 0) {
                period.shares[_address] = _total;
            }
            return true;
        }
        return false;
    }


/**
 * Returns proven amount of shares possessed by a shareholder in a period.
 *
 * @param _address shareholder address.
 * @param _period period.
 *
 * @return shares amount.
 */
    function depositBalanceInPeriod(address _address, uint _period) constant returns(uint) {
        if(_period == lastPeriod())
            return TimeHolder(timeHolder).shares(_address);
        else
            return periods[_period].shares[_address];
    }

/**
 * Returns total proven amount of shares possessed by shareholders in a period.
 *
 * @param _period period.
 *
 * @return shares amount.
 */
    function totalDepositInPeriod(uint _period) constant returns(uint) {
        if(_period == lastPeriod())
            return TimeHolder(timeHolder).totalShares();
        else
            return periods[_period].totalShares;
    }

/**
 * Returns current active period.
 *
 * @return period.
 */
    function lastPeriod() constant returns(uint) {
        return periods.length - 1;
    }

/**
 * Returns last closed period.
 *
 * @dev throws in case if there is no closed periods yet.
 *
 * @return period.
 */
    function lastClosedPeriod() constant returns(uint) {
        if (periods.length == 1) {
            throw;
        }
        return periods.length - 2;
    }

/**
 * Check if period is closed or not.
 *
 * @param _period period.
 *
 * @return period closing state.
 */
    function isClosed(uint _period) constant returns(bool) {
        return lastClosedPeriod() >= _period;
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
        return periods[_period].assetBalances[_assetAddress];
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
        return periods[_period].calculated[_assetAddress][_address];
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
        return rewards[_assetAddress][_address];
    }

    function()
    {
        throw;
    }
}
