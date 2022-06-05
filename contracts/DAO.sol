//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Staking.sol";
import "hardhat/console.sol";


error approvalForDAOreq();
error waitforProposalEnd(uint);
error amountGreaterthanBalance(uint, uint);
error proposalClosed();
error insufficentVotingPower();
error alreadyVoted();
error needtoendProposal(uint);
error waitforProposalEndTime(uint);
error errorCalling(string);
error proposalIDdoesnotexist();
error onlyChairPerson();
error noVotes();
error nostaking();
error onlystakingcontract();
 

contract DAOProject is ReentrancyGuard {
    using Counters for Counters.Counter;

    address public chairPerson;
    address public stakingContract;
    uint public minimumQuorum;
    uint public debatingPeriodDuration;
    uint public totalVotingPower;

    Counters.Counter public proposalID; 

    struct proposal {
        uint id;
        proposalStatus status;
        uint FORvotes;
        uint AGAINSTvotes;
        uint startTime;
        bytes callData;
        address recipient;
        string description;
    }

    struct voter {
        uint votingPower;
        uint endTime;
        uint endingProposalID;
        mapping(uint => bool)voted;
    }

    enum proposalStatus {
        NONE,
        INPROGRESS,
        APPROVED,
        REJECTED
    }

    mapping(uint => proposal) public Proposal;
    mapping(address => voter) public Voter;

    event percentage (uint _percentq, uint _percentfor); 


    constructor (address _chairPerson, address _stakecontract, uint _minimumQuorum, uint _debatingPeriodDuration) {
        chairPerson = _chairPerson;
        stakingContract = _stakecontract;
        minimumQuorum = _minimumQuorum;
        debatingPeriodDuration = _debatingPeriodDuration;
    }


    function unstaking(address _address) public nonReentrant returns (uint){
        if(msg.sender != stakingContract)
            revert onlystakingcontract();
        if(Voter[_address].votingPower == 0)
        return 20;
        if(block.timestamp< Voter[_address].endTime)
            revert waitforProposalEnd (Voter[_address].endingProposalID);
        if(Proposal[Voter[_address].endingProposalID].status == proposalStatus.INPROGRESS)
            revert needtoendProposal(Voter[_address].endingProposalID);
        totalVotingPower -= Voter[_address].votingPower;
        Voter[_address].votingPower = 0;
        return 5;
    }

    function newProposal(bytes calldata _callData, address _recipient, string calldata _description) public {
        if(msg.sender != chairPerson)
            revert onlyChairPerson();
        proposalID.increment();
        Proposal[proposalID.current()] = proposal(
        proposalID.current(),
        proposalStatus.INPROGRESS,
        0,
        0,
        block.timestamp,
        _callData,
        _recipient,
        _description
        );
    }

    function voting(uint _proposalID, bool _votefor) nonReentrant public {
        if(_proposalID > proposalID.current())
            revert proposalIDdoesnotexist();
        if(Proposal[_proposalID].status != proposalStatus.INPROGRESS)
            revert proposalClosed();
        if(Voter[msg.sender].voted[_proposalID])
            revert alreadyVoted();
        
        (uint _balance) = Staking(stakingContract).balance(msg.sender);
        if (_balance == 0)
        revert nostaking();
        if (Voter[msg.sender].votingPower != 0){
            totalVotingPower -= Voter[msg.sender].votingPower;
        }
        Voter[msg.sender].votingPower = _balance;
        totalVotingPower += _balance;

        Voter[msg.sender].endingProposalID = _proposalID;
        Voter[msg.sender].endTime = Proposal[_proposalID].startTime + debatingPeriodDuration;
        Voter[msg.sender].voted[_proposalID] = true;
        if(_votefor)
        Proposal[_proposalID].FORvotes += _balance;
        else{
            Proposal[_proposalID].AGAINSTvotes += _balance;
        }
    }

    function endProposal(uint _proposalID) public {
        if(_proposalID > proposalID.current())
            revert proposalIDdoesnotexist();
        if(Proposal[_proposalID].status != proposalStatus.INPROGRESS)
            revert proposalClosed();
        if(block.timestamp < (Proposal[_proposalID].startTime + debatingPeriodDuration))
            revert waitforProposalEndTime(Proposal[_proposalID].startTime + debatingPeriodDuration);
        if((Proposal[_proposalID].FORvotes + Proposal[_proposalID].AGAINSTvotes) != 0)
        {
        uint percentQ = ((Proposal[_proposalID].FORvotes + Proposal[_proposalID].AGAINSTvotes)*100)/(totalVotingPower);
        uint percentFor = ((Proposal[_proposalID].FORvotes)*100)/(Proposal[_proposalID].FORvotes + Proposal[_proposalID].AGAINSTvotes);
        emit percentage (percentQ, percentFor);
        if((percentQ >= minimumQuorum) && (percentFor > 50)){
            Proposal[_proposalID].status = proposalStatus.APPROVED;
            (bool success, ) = (Proposal[_proposalID].recipient).call(Proposal[_proposalID].callData);
            if(!success)
            revert errorCalling(Proposal[_proposalID].description);
        }
        else
            Proposal[_proposalID].status = proposalStatus.REJECTED;
        }
        else
            Proposal[_proposalID].status = proposalStatus.REJECTED;
    }
}

