// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./RandomizedCommittee.sol"; // Assuming the committee contract is named RandomizedCommittee

contract FundDistribution is AccessControl {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    bytes32 public constant PROPOSAL_CREATOR_ROLE = keccak256("PROPOSAL_CREATOR_ROLE");

    Counters.Counter private _requestIdCounter;
    Counters.Counter private _milestoneIdCounter;

    RandomizedCommittee public committeeContract; // Reference to the committee contract

    struct Milestone {
        string description;
        uint256 amount;
        bool isCompleted;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted;
        bool fundsReleased;
    }

    struct FundRequest {
        address creator;
        uint256 eventId;
        uint256 requestedAmount;
        uint256 approvedAmount;
        uint256 releasedAmount;
        uint256[] milestones;
        bool approved;
        address recipient;
    }


    mapping(uint256 => FundRequest) public fundRequests;
    mapping(uint256 => Milestone) public milestones;

    event FundRequested(uint256 indexed requestId, address indexed recipient, uint256 totalAmount, string purpose);
    event MilestoneFundsReleased(uint256 indexed requestId, uint256 indexed milestoneId, uint256 amount);
    event MilestoneCreated(uint256 indexed milestoneId, string description, uint256 amount);

    constructor(address _committeeContractAddress) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        committeeContract = RandomizedCommittee(_committeeContractAddress);
    }

    function createMilestone(uint256 requestId, string memory description, uint256 targetAmount) external onlyRole(PROPOSAL_CREATOR_ROLE) {
        require(fundRequests[requestId].creator == msg.sender, "Only the proposal creator can add milestones");

        _milestoneIdCounter.increment();
        uint256 newMilestoneId = _milestoneIdCounter.current();

        Milestone storage newMilestone = milestones[newMilestoneId]; // Create a new storage reference
        newMilestone.description = description;
        newMilestone.amount = targetAmount;
        newMilestone.isCompleted = false;
        newMilestone.fundsReleased = false;

        fundRequests[requestId].milestones.push(newMilestoneId);
    }

    function requestFunds(address payable _recipient, uint256 totalAmount, string memory purpose, string[] memory milestoneDescriptions, uint256[] memory milestoneAmounts) external onlyRole(PROPOSAL_CREATOR_ROLE) {
        require(milestoneDescriptions.length == milestoneAmounts.length, "Mismatch in milestone descriptions and amounts");

        _requestIdCounter.increment();
        uint256 newRequestId = _requestIdCounter.current();

        uint256[] memory createdMilestoneIds = new uint256[](milestoneDescriptions.length);

        for (uint i = 0; i < milestoneDescriptions.length; i++) {
            _milestoneIdCounter.increment();
            uint256 newMilestoneId = _milestoneIdCounter.current();

            Milestone storage newMilestone = milestones[newMilestoneId];
            newMilestone.description = milestoneDescriptions[i];
            newMilestone.amount = milestoneAmounts[i];
            newMilestone.isCompleted = false;
            newMilestone.votesFor = 0;
            newMilestone.votesAgainst = 0;
            newMilestone.fundsReleased = false;

            createdMilestoneIds[i] = newMilestoneId;
        }

        FundRequest storage newFundRequest = fundRequests[newRequestId];
        newFundRequest.creator = msg.sender;
        newFundRequest.eventId = 0; // You might want to adjust this based on your logic.
        newFundRequest.requestedAmount = totalAmount;
        newFundRequest.approvedAmount = 0;
        newFundRequest.releasedAmount = 0;
        newFundRequest.recipient = _recipient;
        for (uint i = 0; i < createdMilestoneIds.length; i++) {
            newFundRequest.milestones.push(createdMilestoneIds[i]);
        }
        newFundRequest.approved = false;

        emit FundRequested(newRequestId, _recipient, totalAmount, purpose);
    }





    function voteOnMilestoneCompletion(uint256 requestId, uint256 milestoneIndex, bool vote) external {
        require(hasRole(committeeContract.COMMITTEE_MEMBER_ROLE(), msg.sender), "Only committee members can vote");
        require(fundRequests[requestId].recipient != address(0), "Invalid request ID");
        uint256 milestoneId = fundRequests[requestId].milestones[milestoneIndex];
        require(!milestones[milestoneId].isCompleted, "Milestone already completed");
        require(!milestones[milestoneId].hasVoted[msg.sender], "You have already voted on this milestone");


        if (vote) {
            milestones[milestoneId].votesFor++;
        } else {
            milestones[milestoneId].votesAgainst++;
        }

        milestones[milestoneId].hasVoted[msg.sender] = true;

        // Check if the milestone has received a majority of positive votes
        if (milestones[milestoneId].votesFor > milestones[milestoneId].votesAgainst) {
            releaseFundsForMilestone(requestId, milestoneIndex);
        }
    }

    function releaseFundsForMilestone(uint256 requestId, uint256 milestoneIndex) internal {
        require(fundRequests[requestId].recipient != address(0), "Invalid request ID");
        uint256 milestoneId = fundRequests[requestId].milestones[milestoneIndex];
        require(!milestones[milestoneId].isCompleted, "Milestone already completed");

        address payable payableRecipient = payable(fundRequests[requestId].recipient);
        uint256 amount = milestones[milestoneId].amount;
        payableRecipient.transfer(amount);

        milestones[milestoneId].isCompleted = true;

        emit MilestoneFundsReleased(requestId, milestoneIndex, amount);
    }

}
