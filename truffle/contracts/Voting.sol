// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

/** @title A voting system smart contract
  * @author Alyra Web3 training school
  * @notice You can use this contract to create a voting process supervised by an administrator
  * @dev Owner has the ability to change workflow status and go deeper in the voting process after adding new addresses as potential voters
  * @custom:experimental This is an experimental contract used in a teachable environment
  */
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

    event VoterRegistered(address _voterAddress);
    event WorkflowStatusChange(WorkflowStatus _previousStatus, WorkflowStatus _newStatus);
    event ProposalRegistered(uint _proposalId);
    event Voted (address _voter, uint _proposalId);

    modifier flowStatus(WorkflowStatus _status) {
        require(workflowStatus == _status, "You are not able to do this action right now");
        _;
    }

    /** @notice Give the owner the ability to register new voters allowing them to make proposals and to vote
      * @param _voterAddress The address of the user you want to add to the voters list
      * @dev This function allow owner to modify the boolean isRegistered to true inside struct Voter in the the mapping Voters
      * @custom:requirement WorkflowStatus must be on RegisteringVoters to be able to add new voters
      */
    function registerVoters(address _voterAddress) public flowStatus(WorkflowStatus.RegisteringVoters) onlyOwner {
        require(!voters[_voterAddress].isRegistered, "This address is already in voters");
        voters[_voterAddress].isRegistered = true;
        emit VoterRegistered(_voterAddress);
    }

    /** @notice Give the owner the ability to start the proposals registering process for eligible voters
      * @dev Change enum WorkflowStatus to ProposalsRegistrationStarted 
      * @custom:requirement WorkflowStatus must be on RegisteringVoters to be able to change WorkflowStatus to ProposalsRegistrationStarted
      */
    function startProposalsRegistration() public flowStatus(WorkflowStatus.RegisteringVoters) onlyOwner {
        workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
    }

    /** @notice Give the registered voters the ability to add new proposal 
      * @param _proposalDescription The description (string) of the Proposal you want to add to voting choice
      * @dev Add a new struct Proposal in proposals array with string description set as the parameter _proposalDescription and uint voteCount set to 0
      * @custom:requirement WorkflowStatus must be on ProposalsRegistrationStarted to be abble to add new Proposal
      */
    function registerProposals(string memory _proposalDescription) public flowStatus(WorkflowStatus.ProposalsRegistrationStarted) {
        require(voters[msg.sender].isRegistered, "You are not allowed to make a proposal");
        proposals.push(Proposal(_proposalDescription, 0));
        voters[msg.sender].votedProposalId = proposals.length + 1;
    }
   
    /** @notice Give the owner the ability to end the proposals registering process
      * @dev Change enum WorkflowStatus to ProposalsRegistrationEnded 
      * @custom:requirement WorkflowStatus must be on ProposalsRegistrationStarted to be able to change WorkflowStatus to ProposalsRegistrationEnded
      */
    function endProposalsRegistration() public flowStatus(WorkflowStatus.ProposalsRegistrationStarted) onlyOwner {
        workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
    }

    /** @notice Give the owner the ability to start the voting process
      * @dev Change enum WorkflowStatus to VotingSessionStarted 
      * @custom:requirement WorkflowStatus must be on ProposalsRegistrationEnded to be able to change WorkflowStatus to VotingSessionStarted
      */
    function startVotingSession() public flowStatus(WorkflowStatus.ProposalsRegistrationEnded) onlyOwner {
        workflowStatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
    }

    /** @notice Give the registered voters the ability to vote for a Proposal according to its ID
      * @param _proposalId The uint of the Proposal you want to vote for
      * @dev This function increment the uint voteCount inside the struct Voter of the the proposals array index choosen by _proposalId parameter
      * @custom:requirement WorkflowStatus must be on VotingSessionStarted to be able to vote
      */
    function vote(uint _proposalId) public flowStatus(WorkflowStatus.VotingSessionStarted) {
        require(voters[msg.sender].isRegistered, "You are not allowed to vote");
        require(!voters[msg.sender].hasVoted, "You have already voted");
        proposals[_proposalId].voteCount += 1;
        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedProposalId = _proposalId;
        if (proposals[_proposalId].voteCount > proposals[winningProposalId].voteCount) {
            winningProposalId = _proposalId;
        }
        emit Voted(msg.sender, _proposalId);
    }

    /** @notice Give the owner the ability to end the voting process and then the winner is setted and getWinner is usable
      * @dev Change enum WorkflowStatus to VotingSessionEnded and finish the voting process by setting up the final state of uint winningProposalId
      * @custom:requirement WorkflowStatus must be on VotingSessionStarted to be able to change WorkflowStatus to VotingSessionEnded
      */
    function endVotingSession() public flowStatus(WorkflowStatus.VotingSessionStarted) onlyOwner {
        workflowStatus = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
    }

    /** @notice Give the ability to check which Proposal won the election
      * @dev Retrieves the value of the winning struct Proposal in proposals array ( == proposals[winningProposalId])
      * @return  Proposal Struct from proposals array that won the vote with string description and uint voteCount
      * @custom:requirement WorkflowStatus must be on VotingSessionEnded to be able to get the winning Proposal
      */
    function getWinner() public flowStatus(WorkflowStatus.VotingSessionEnded) view returns (Proposal memory) {
        return proposals[winningProposalId];
    }
}
