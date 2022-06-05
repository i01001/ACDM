//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Staking.sol";
import "hardhat/console.sol";

/// @dev All error codes generated within the contract
error approvalForDAOreq();
error waitforProposalEnd(uint256);
error amountGreaterthanBalance(uint256, uint256);
error proposalClosed();
error insufficentVotingPower();
error alreadyVoted();
error needtoendProposal(uint256);
error waitforProposalEndTime(uint256);
error errorCalling(string);
error proposalIDdoesnotexist();
error onlyChairPerson();
error noVotes();
error nostaking();
error onlystakingcontract();

/// @title DAO Project Contract for submitting proposals, voting it and executing functions within other contract based on proposals
/// @author Ikhlas
/// @notice The contract does not have the front end implemented
/// @dev All function calls are currently implemented without side effects
/// @custom:experimental This is an experimental contract.
contract DAOProject is ReentrancyGuard {
    using Counters for Counters.Counter;

    /// @notice Variables for the contract
    /// @notice chairPerson - person who can initate proposals
    /// @notice StakingContract - address of the Staking Token
    /// @notice minimumQuorum - percentage minimum with respect to totalVotingPower
    /// @notice debatingPeriodDuration - minimum duration for the proposal
    /// @notice totalVotingPower - total amount of tokens deposited in the DAO
    address public chairPerson;
    address public stakingContract;
    uint256 public minimumQuorum;
    uint256 public debatingPeriodDuration;
    uint256 public totalVotingPower;

    /// @notice proposalID - counter for the proposals
    Counters.Counter public proposalID;

    /// @notice proposal struct to store information
    /// @param id - proposal id
    /// @param status - status of the proposal
    /// @param FORvotes - votes in favour of
    /// @param AGAINSTvotes - votes against
    /// @param startTime - block time stamp at the time of creating proposal
    /// @param callData - the function signature to be executed if proposal approved
    /// @param recipient - the Contract address where the callData function is
    /// @param description - brief information about the proposal
    struct proposal {
        uint256 id;
        proposalStatus status;
        uint256 FORvotes;
        uint256 AGAINSTvotes;
        uint256 startTime;
        bytes callData;
        address recipient;
        string description;
    }

    /// @notice voter struct to store information
    /// @param votingPower - amount of tokens deposited
    /// @param endTime - time when last proposal voted / funds frozed until it
    /// @param endingProposalID - id of the last proposal
    /// @param voted - mapping of the proposal id with the bool that voting has been done or not
    struct voter {
        uint256 votingPower;
        uint256 endTime;
        uint256 endingProposalID;
        mapping(uint256 => bool) voted;
    }

    /// @notice proposal status - initally none; while in progress it in progress and when completed it
    /// @notice is either approved or rejected.
    enum proposalStatus {
        NONE,
        INPROGRESS,
        APPROVED,
        REJECTED
    }

    /// @notice Proposal mapping - proposal ID with the proposal struct
    /// @notice Voter mapping - user aaddress to voter struct
    mapping(uint256 => proposal) public Proposal;
    mapping(address => voter) public Voter;

    event percentage(uint256 _percentq, uint256 _percentfor);

    /// @notice Constructor with inputs
    constructor(
        address _chairPerson,
        address _stakecontract,
        uint256 _minimumQuorum,
        uint256 _debatingPeriodDuration
    ) {
        chairPerson = _chairPerson;
        stakingContract = _stakecontract;
        minimumQuorum = _minimumQuorum;
        debatingPeriodDuration = _debatingPeriodDuration;
    }

    /// @notice ustaking; funds are frozed until voted proposals have not been closed
    function unstaking(address _address) public nonReentrant returns (uint256) {
        if (msg.sender != stakingContract) revert onlystakingcontract();
        if (Voter[_address].votingPower == 0) return 20;
        if (block.timestamp < Voter[_address].endTime)
            revert waitforProposalEnd(Voter[_address].endingProposalID);
        if (
            Proposal[Voter[_address].endingProposalID].status ==
            proposalStatus.INPROGRESS
        ) revert needtoendProposal(Voter[_address].endingProposalID);
        totalVotingPower -= Voter[_address].votingPower;
        Voter[_address].votingPower = 0;
        return 5;
    }

    /// @notice newProposal iniation can be done by Chair person only. Need to provide the call data, recipient and also a description.
    function newProposal(
        bytes calldata _callData,
        address _recipient,
        string calldata _description
    ) public {
        if (msg.sender != chairPerson) revert onlyChairPerson();
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

    /// @notice voting on proposals that are open; can only vote one time in each proposal
    function voting(uint256 _proposalID, bool _votefor) public nonReentrant {
        if (_proposalID > proposalID.current()) revert proposalIDdoesnotexist();
        if (Proposal[_proposalID].status != proposalStatus.INPROGRESS)
            revert proposalClosed();
        if (Voter[msg.sender].voted[_proposalID]) revert alreadyVoted();

        uint256 _balance = Staking(stakingContract).balance(msg.sender);
        if (_balance == 0) revert nostaking();
        if (Voter[msg.sender].votingPower != 0) {
            totalVotingPower -= Voter[msg.sender].votingPower;
        }
        Voter[msg.sender].votingPower = _balance;
        totalVotingPower += _balance;

        Voter[msg.sender].endingProposalID = _proposalID;
        Voter[msg.sender].endTime =
            Proposal[_proposalID].startTime +
            debatingPeriodDuration;
        Voter[msg.sender].voted[_proposalID] = true;
        if (_votefor) Proposal[_proposalID].FORvotes += _balance;
        else {
            Proposal[_proposalID].AGAINSTvotes += _balance;
        }
    }

    /// @notice endProposal finishes of the proposal provided the predifined time has been completed. Decision of acceptance of
    /// @notice proposal requires the minimum minimumQuorum and majority of FOR votes is required. If approved the calldata is executed
    function endProposal(uint256 _proposalID) public {
        if (_proposalID > proposalID.current()) revert proposalIDdoesnotexist();
        if (Proposal[_proposalID].status != proposalStatus.INPROGRESS)
            revert proposalClosed();
        if (
            block.timestamp <
            (Proposal[_proposalID].startTime + debatingPeriodDuration)
        )
            revert waitforProposalEndTime(
                Proposal[_proposalID].startTime + debatingPeriodDuration
            );
        if (
            (Proposal[_proposalID].FORvotes +
                Proposal[_proposalID].AGAINSTvotes) != 0
        ) {
            uint256 percentQ = ((Proposal[_proposalID].FORvotes +
                Proposal[_proposalID].AGAINSTvotes) * 100) / (totalVotingPower);
            uint256 percentFor = ((Proposal[_proposalID].FORvotes) * 100) /
                (Proposal[_proposalID].FORvotes +
                    Proposal[_proposalID].AGAINSTvotes);
            emit percentage(percentQ, percentFor);
            if ((percentQ >= minimumQuorum) && (percentFor > 50)) {
                Proposal[_proposalID].status = proposalStatus.APPROVED;
                (bool success, ) = (Proposal[_proposalID].recipient).call(
                    Proposal[_proposalID].callData
                );
                if (!success)
                    revert errorCalling(Proposal[_proposalID].description);
            } else Proposal[_proposalID].status = proposalStatus.REJECTED;
        } else Proposal[_proposalID].status = proposalStatus.REJECTED;
    }
}
