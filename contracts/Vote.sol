pragma solidity ^0.4.8;

import "./Managed.sol";
import {TimeHolderInterface as TimeHolder} from "./TimeHolderInterface.sol";
import "./VoteEmitter.sol";

contract Vote is Managed, VoteEmitter {

    StorageInterface.UInt polls;
    StorageInterface.UInt activePolls;
    StorageInterface.AddressUIntMapping memberPollsCount;
    StorageInterface.AddressUIntUIntMapping memberPolls;
    StorageInterface.UInt sharesPercent;
    StorageInterface.UIntAddressMapping owner;
    StorageInterface.UIntBytes32Mapping title;
    StorageInterface.UIntBytes32Mapping description;
    StorageInterface.UIntUIntMapping votelimit;
    StorageInterface.UIntUIntMapping optionsCount;
    StorageInterface.UIntUIntMapping memberCount;
    StorageInterface.UIntUIntMapping deadline;
    StorageInterface.UIntUIntMapping ipfsHashesCount;
    StorageInterface.UIntBoolMapping status;
    StorageInterface.UIntBoolMapping active;
    StorageInterface.UIntUIntAddressMapping members;
    StorageInterface.UIntAddressUIntMapping memberOption;
    StorageInterface.UIntAddressUIntMapping memberVotes;
    StorageInterface.UIntUIntBytes32Mapping ipfsHashes;
    StorageInterface.UIntUIntBytes32Mapping optionsId;
    StorageInterface.UIntUIntUIntMapping options;

    // event tracking new Polls
    event New_Poll(uint _pollId);

    // event tracking of all votes
    event NewVote(uint _choice, uint _pollId);

    // Something went wrong.
    event Error(bytes32 message);

    function Vote(Storage _store, bytes32 _crate) StorageAdapter(_store, _crate) {
        polls.init('polls');
        activePolls.init('activePolls');
        memberPolls.init('memberPolls');
        memberPollsCount.init('memberPollsCount');
        memberCount.init('memberCount');
        members.init('members');
        memberVotes.init('memberVotes');
        sharesPercent.init('sharesPercent');
        owner.init('owner');
        title.init('title');
        description.init('description');
        votelimit.init('votelimit');
        optionsCount.init('optionsCount');
        deadline.init('deadline');
        ipfsHashesCount.init('ipfsHashesCount');
        status.init('status');
        active.init('active');
        memberOption.init('memberOption');
        ipfsHashes.init('ipfsHashes');
        optionsId.init('optionsId');
        options.init('options');
    }

    function init(address _contractsManager) returns(bool) {
        if(store.get(contractsManager) != 0x0)
            return false;
        if(!ContractsManagerInterface(_contractsManager).addContract(this,ContractsManagerInterface.ContractType.Voting))
            return false;
        store.set(contractsManager, _contractsManager);
        store.set(sharesPercent,1);
        return true;
    }

    function setupEventsHistory(address _eventsHistory) onlyAuthorized returns(bool) {
        if (getEventsHistory() != 0x0) {
            return false;
        }
        _setEventsHistory(_eventsHistory);
        return true;
    }

    //initiator function that stores the necessary poll information
    function NewPoll(bytes32[16] _options, bytes32[4] _ipfsHashes, bytes32 _title, bytes32 _description, uint _votelimit, uint _deadline) returns (uint) {
        if(_votelimit > getVoteLimit()) {
            Error(bytes32("Vote limit exceeded"));
            throw;
        }
        uint id = store.get(polls);
        uint i;
        store.set(owner,id,msg.sender);
        store.set(title,id,_title);
        store.set(description,id,_description);
        store.set(votelimit,id,_votelimit);
        store.set(deadline,id,_deadline);
        store.set(status,id,true);
        store.set(active,id,false);
        for(i = 0; i < _options.length; i++) {
            if(_options[i] != bytes32(0)) {
                store.set(optionsId,id,i+1,_options[i]);
                store.set(optionsCount,id,i+1);
            }
        }
        for(i = 0; i < _ipfsHashes.length; i++) {
            if(_ipfsHashes[i] != bytes32(0)) {
                store.set(ipfsHashes,id,i,_ipfsHashes[i]);
                store.set(ipfsHashesCount,id,i+1);
            }
        }
        store.set(polls,store.get(polls)+1);
        New_Poll(id);
        return id;
    }

    function pollsCount() constant returns (uint) {
        return store.get(polls);
    }

    function getVoteLimit() constant returns (uint) {
        address timeHolder = ContractsManagerInterface(store.get(contractsManager)).getContractAddressByType(ContractsManagerInterface.ContractType.TimeHolder);
        return TimeHolder(timeHolder).totalSupply() / 10000 * store.get(sharesPercent);
    }

    function getPollTitles() constant returns (bytes32[] result) {
        uint pollsCount = store.get(polls);
        result = new bytes32[](pollsCount);
        for(uint i = 0; i<pollsCount; i++)
        {
            result[i] = store.get(title,i);
        }
        return (result);
    }

    function getActivePollsCount() constant returns (uint result) {
        uint pollsCount = store.get(polls);
        for(uint i = 0; i < pollsCount; i++) {
            if(store.get(active,i))
                result++;
        }
        return result;
    }

    function getActivePolls() constant returns (uint[] result) {
        uint pollsCount = store.get(polls);
        uint activePollsCount = getActivePollsCount();
        uint j;
        result = new uint[](activePollsCount);
        for(uint i = 0; i < pollsCount; i++) {
            if(store.get(active,i)) {
                result[j] = i;
                j++;
            }
        }
        return result;
    }

    function checkPollIsActive(uint _pollId) constant returns (bool) {
        if(store.get(active,_pollId))
            return true;
        return false;
    }

    function getInactivePollsCount() constant returns (uint result) {
        uint pollsCount = store.get(polls);
        for(uint i = 0; i < pollsCount; i++) {
            if(!store.get(active,i) && store.get(status,i))
                result++;
        }
        return result;
    }

    function getInactivePolls() constant returns (uint[] result) {
        uint pollsCount = store.get(polls);
        uint inactivePollsCount = getInactivePollsCount();
        uint j;
        result = new uint[](inactivePollsCount);
        for(uint i = 0; i < pollsCount; i++) {
            if(!store.get(active,i) && store.get(status,i)) {
                result[j] = i;
                j++;
            }
        }
        return result;
    }

    function getMemberPolls() constant returns (uint[] result) {
        uint _memberPollsCount = store.get(memberPollsCount,msg.sender);
        result = new uint[](_memberPollsCount);
        for(uint i = 0; i < _memberPollsCount; i++) {
            result[i] = store.get(memberPolls,msg.sender,i);
        }
        return result;
    }

    function getMemberVotesForPoll(uint _id) constant returns (uint result) {
        result = store.get(memberOption,_id,msg.sender);
        return (result);
    }

    function getOptionsForPoll(uint _id) constant returns (bytes32[] result) {
        uint _optionsCount = store.get(optionsCount,_id);
        result = new bytes32[](_optionsCount);
        for(uint i = 0; i < _optionsCount; i++)
        {
            result[i] = store.get(optionsId,_id,i+1);
        }
        return result;
    }

    function getOptionsVotesForPoll(uint _id) constant returns (uint[] result) {
        uint _optionsCount = store.get(optionsCount,_id);
        result = new uint[](_optionsCount);
        for(uint i = 0; i < _optionsCount; i++)
        {
            result[i] = store.get(options,_id,i+1);
        }
        return result;
    }

    modifier onlyCreator(uint _id) {
        if(isPollOwner(_id))
        {
            _;
        }
    }

    function isPollOwner(uint _id) constant returns(bool) {
        if(store.get(owner,_id) == msg.sender) {
            return true;
        }
        return false;
    }

    function addIpfsHashToPoll(uint _id, bytes32 _hash) onlyCreator(_id) returns(bool) {
        uint _ipfsHashesCount = store.get(ipfsHashesCount,_id);
        if(_ipfsHashesCount < 5) {
            store.set(ipfsHashes,_id,_ipfsHashesCount++,_hash);
            store.set(ipfsHashesCount,_id,_ipfsHashesCount);
            return true;
        }
        return false;
    }

    function getIpfsHashesFromPoll(uint _id) constant returns (bytes32[] result) {
        uint _ipfsHashesCount = store.get(ipfsHashesCount,_id);
        result = new bytes32[](_ipfsHashesCount);
        for(uint i = 0; i < _ipfsHashesCount; i++)
        {
            result[i] = store.get(ipfsHashes,_id,i);
        }
        return result;
    }

    //function for user vote. input is a string choice
    function vote(uint _pollId, uint _choice) returns (bool) {
        address timeHolder = ContractsManagerInterface(store.get(contractsManager)).getContractAddressByType(ContractsManagerInterface.ContractType.TimeHolder);
        if (!store.get(status,_pollId) || !store.get(active,_pollId) || TimeHolder(timeHolder).shares(msg.sender) == 0 || store.get(memberOption,_pollId,msg.sender) != 0) {
            return false;
        }
        store.set(options,_pollId,_choice,store.get(options,_pollId,_choice) + TimeHolder(timeHolder).shares(msg.sender));
        store.set(memberVotes,_pollId,msg.sender,TimeHolder(timeHolder).shares(msg.sender));
        uint _membersCount = store.get(memberCount,_pollId);
        store.set(members,_pollId,_membersCount,msg.sender);
        store.set(memberCount,_pollId,_membersCount+1);
        store.set(memberOption,_pollId,msg.sender,_choice);
        uint _memberPollsCount = store.get(memberPollsCount,msg.sender);
        store.set(memberPolls,msg.sender,_memberPollsCount++,_pollId);
        store.set(memberPollsCount,msg.sender,_memberPollsCount);
        NewVote(_choice, _pollId);
        // if votelimit reached, end poll
        if (store.get(votelimit,_pollId) > 0 || store.get(deadline,_pollId) <= now) {
            if (store.get(options,_pollId,_choice) >= store.get(votelimit,_pollId)) {
                endPoll(_pollId);
            }
        }
        return true;
    }

    function getPoll(uint _pollId) constant returns (address _owner,
    bytes32 _title,
    bytes32 _description,
    uint _votelimit,
    uint _deadline,
    bool _status,
    bool _active,
    bytes32[] _options,
    bytes32[] _hashes) {
        _owner = store.get(owner,_pollId);
        _title = store.get(title,_pollId);
        _description = store.get(description,_pollId);
        _votelimit = store.get(votelimit,_pollId);
        _deadline = store.get(deadline,_pollId);
        _status = store.get(status,_pollId);
        _active = store.get(active,_pollId);
        _options = new bytes32[](store.get(optionsCount,_pollId));
        _hashes = new bytes32[](store.get(ipfsHashesCount,_pollId));
        uint i;
        for(i=0;i<store.get(optionsCount,_pollId);i++) {
            _options[i] = store.get(optionsId,_pollId,i+1);
        }
        for(i=0;i<store.get(ipfsHashesCount,_pollId);i++) {
            _hashes[i] = store.get(ipfsHashes,_pollId,i);
        }
        return (_owner,_title,_description,_votelimit,_deadline,_status,_active,_options,_hashes);
    }

    function setVotesPercent(uint _percent) multisig returns(bool) {
        if(_percent > 0 && _percent < 100) {
            store.set(sharesPercent,_percent);
        }
    }

    function removePoll(uint _pollId) onlyAuthorized returns(bool) {
        if(!store.get(active,_pollId) && store.get(status,_pollId)) {
            deletePoll(_pollId);
            return true;
        }
        return false;
    }

    function cleanInactivePolls() onlyAuthorized returns(bool) {
        uint[] memory result = getInactivePolls();
        for(uint i = 0; i < result.length; i++) {
                deletePoll(result[i]);
        }
        return true;
    }

    function deletePoll(uint _pollId) internal returns(bool) {
        uint pollsCount = store.get(polls);
        if(_pollId >= pollsCount)
            return false;
        store.set(polls,pollsCount-1);
        return true;
    }

    //when time or vote limit is reached, set the poll status to false
    function endPoll(uint _pollId) internal returns (bool) {
        store.set(status,_pollId,false);
        store.set(active,_pollId,false);
        uint _activePollsCount = store.get(activePolls);
        store.set(activePolls,_activePollsCount-1);
        return true;
    }

    function activatePoll(uint _pollId) multisig returns (bool) {
        uint _activePollsCount = store.get(activePolls);
        if(_activePollsCount <= 20) {
            if(store.get(status,_pollId)) {
                store.set(active,_pollId,true);
                store.set(activePolls,_activePollsCount+1);
                return true;
            }
        }
        return false;
    }

    function adminEndPoll(uint _pollId) multisig returns (bool) {
        return endPoll(_pollId);
    }

    //TimeHolder interface implementation
    modifier onlyTimeHolder() {
        address timeHolder = ContractsManagerInterface(store.get(contractsManager)).getContractAddressByType(ContractsManagerInterface.ContractType.TimeHolder);
        if (msg.sender == timeHolder) {
            _;
        }
    }

    function deposit(address _address, uint _amount, uint _total) onlyTimeHolder returns(bool) {
        for(uint i=0;i<store.get(memberPollsCount,_address);i++){
            uint _pollId = store.get(memberPolls,_address,i);
            if(store.get(status,_pollId) && store.get(active,_pollId)) {
                uint choice = store.get(memberOption,_pollId,_address);
                uint value = store.get(options,_pollId,choice);
                value = value + _amount;
                store.set(memberVotes,_pollId,_address,_total);
                store.set(options,_pollId,choice,value);
            }
            if (store.get(votelimit,_pollId) > 0 || store.get(votelimit,_pollId) <= now) {
                if (value >= store.get(votelimit,_pollId)) {
                    endPoll(_pollId);
                }
            }
        }
        return true;
    }

    function withdrawn(address _address, uint _amount, uint _total) onlyTimeHolder returns(bool) {
        uint _memberPollsCount = store.get(memberPollsCount,_address);
        for(uint i=0;i<_memberPollsCount;i++){
            uint _pollId = store.get(memberPolls,_address,i);
            if(store.get(status,_pollId) && store.get(active,_pollId)) {
                uint choice = store.get(memberOption,_pollId,_address);
                uint value = store.get(options,_pollId,choice);
                value = value - _amount;
                store.set(memberVotes,_pollId,_address,_total);
                store.set(options,_pollId,choice,value);
                if(_total == 0) {
                    if(i == _memberPollsCount - 1) {
                        store.set(memberPollsCount,_address,_memberPollsCount-1);
                    }
                    else {
                        store.set(memberPolls,_address,i,store.get(memberPolls,_address,_memberPollsCount - 1));
                        store.set(memberPollsCount,_address,_memberPollsCount-1);
                    }
                    removeMember(_pollId, _address);
                }
            }
        }
        return true;
    }

    function removeMember(uint _pollId, address _address) {
        store.set(memberOption,_pollId,_address,0);
        store.set(memberVotes,_pollId,_address,0);
        uint _membersCount = store.get(memberCount,_pollId);
        for(uint i=0;i<_membersCount;i++) {
            address _member = store.get(members,_pollId,i);
            if(_member == _address) {
                if(i != _membersCount - 1)
                    store.set(members,_pollId,i,store.get(members,_pollId,_membersCount-1));
                store.set(memberCount,_pollId,store.get(memberCount,_pollId)-1);
            }
        }
    }

    function()
    {
        throw;
    }
}
