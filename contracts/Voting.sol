// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract Voting is Ownable {

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }
    struct Proposal {
        string description;
        uint voteCount;
    }
    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    WorkflowStatus public workflowStatus;
    uint private winningProposalId;

    mapping(address => Voter) voters;

    Proposal[] public proposals;

    event VoterRegistered(address voterAddress);
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted (address voter, uint proposalId);

    modifier flowStatus(WorkflowStatus _status) {
        require(workflowStatus == _status, "You are not able to do this action right now");
        _;
    }

    function registerVoters(address _voterAddress) public flowStatus(WorkflowStatus.RegisteringVoters) onlyOwner {
        require(!voters[_voterAddress].isRegistered, "This address is already in voters");

        voters[_voterAddress].isRegistered = true;

        emit VoterRegistered(_voterAddress);
    }

    function startProposalsRegistration() public flowStatus(WorkflowStatus.RegisteringVoters) onlyOwner {
        workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
    }

    function registerProposals(string memory proposalDescription) public flowStatus(WorkflowStatus.ProposalsRegistrationStarted) {
        require(voters[msg.sender].isRegistered, "You are not allowed to make a proposal");

        proposals.push(Proposal(proposalDescription, 0));
        voters[msg.sender].votedProposalId = proposals.length + 1;
    }
   
    function endProposalsRegistration() public flowStatus(WorkflowStatus.ProposalsRegistrationStarted) onlyOwner {
        workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
    }

    function startVotingSession() public flowStatus(WorkflowStatus.ProposalsRegistrationEnded) onlyOwner {
        workflowStatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
    }

    function vote(uint proposalId) public flowStatus(WorkflowStatus.VotingSessionStarted) {
        require(voters[msg.sender].isRegistered, "You are not allowed to vote");
        require(!voters[msg.sender].hasVoted, "You have already voted");
        proposals[proposalId].voteCount += 1;
        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedProposalId = proposalId;

        emit Voted(msg.sender, proposalId);
    }


    function vote(uint proposalId) public flowStatus(WorkflowStatus.VotingSessionStarted) {
        require(voters[msg.sender].isRegistered, "You are not allowed to vote");
        require(!voters[msg.sender].hasVoted, "You have already voted");
        proposals[proposalId].voteCount += 1;
        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedProposalId = proposalId;
 
        if (proposals[proposalId].voteCount > proposals[winningProposalId].voteCount) {
            winningProposalId = proposalId;
        }
 
        emit Voted(msg.sender, proposalId);
    }


    function endVotingSession() public flowStatus(WorkflowStatus.VotingSessionStarted) onlyOwner {
        workflowStatus = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
    }


    function getWinner() public flowStatus(WorkflowStatus.VotingSessionEnded) view returns (Proposal memory) {
        return proposals[winningProposalId];
    }
}
