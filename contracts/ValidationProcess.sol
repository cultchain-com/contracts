// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RandomizedCommittee.sol";

contract ValidationProcess {
    using SafeMath for uint256;

    uint256 public constant COMMITTEE_SIZE = 3;

    RandomizedCommittee private committeeContract;

    enum ValidationStatus { PENDING, APPROVED, REJECTED }

    struct ValidationRequest {
        uint256 requestId;
        uint256 proposalId;
        address requester;
        ValidationStatus status;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted;
        uint256 committeeId;
    }

    mapping(uint256 => ValidationRequest) public validationRequests;
    uint256 public validationRequestCounter;

    event ValidationRequested(uint256 requestId, uint256 proposalId, address requester);
    event Voted(address indexed validator, uint256 indexed requestId, bool vote);
    event ValidationFinalized(uint256 requestId, ValidationStatus status);

    constructor(address _committeeAddress) {
        committeeContract = RandomizedCommittee(_committeeAddress);
    }

    function createValidationRequest(uint256 proposalId) external {
        validationRequestCounter++;
        uint256 newRequestId = validationRequestCounter;

        uint256 newCommitteeId = committeeContract.formCommittee(COMMITTEE_SIZE); // Assuming COMMITTEE_SIZE is a predefined constant

        ValidationRequest storage newRequest = validationRequests[newRequestId];
        newRequest.requestId = newRequestId;
        newRequest.proposalId = proposalId;
        newRequest.requester = msg.sender;
        newRequest.status = ValidationStatus.PENDING;
        newRequest.votesFor = 0;
        newRequest.votesAgainst = 0;
        newRequest.committeeId = newCommitteeId;

        emit ValidationRequested(newRequestId, proposalId, msg.sender);
    }

    // Validators will use this function to vote on a validation request
    function voteOnValidation(uint256 requestId, bool approve) external {
        uint256 committeeId = validationRequests[requestId].committeeId;
        require(committeeContract.isCommitteeMember(committeeId, msg.sender), "Caller is not a member of the committee");
        require(!validationRequests[requestId].hasVoted[msg.sender], "Validator has already voted on this request");

        if (approve) {
            validationRequests[requestId].votesFor++;
        } else {
            validationRequests[requestId].votesAgainst++;
        }

        validationRequests[requestId].hasVoted[msg.sender] = true;

        emit Voted(msg.sender, requestId, approve);

        // Check if all validators have voted and finalize the validation
        if (committeeContract.getValidatorCount() == validationRequests[requestId].votesFor.add(validationRequests[requestId].votesAgainst)) {
            finalizeValidation(requestId);
        }
    }

    function finalizeValidation(uint256 requestId) internal {
        if (validationRequests[requestId].votesFor > validationRequests[requestId].votesAgainst) {
            validationRequests[requestId].status = ValidationStatus.APPROVED;
        } else {
            validationRequests[requestId].status = ValidationStatus.REJECTED;
        }

        emit ValidationFinalized(requestId, validationRequests[requestId].status);
    }
}
