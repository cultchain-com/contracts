// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./RandomizedCommittee.sol";


contract Validator is AccessControl {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    uint256 public constant VALIDATOR_CONFIRMATION_COMMITTEE_SIZE = 3;

    enum ValidationStatus { Pending, Approved, Rejected }

    ValidatorRequest[] public validatorRequests;

    RandomizedCommittee private committeeContract;

    mapping(address => ValidatorProfile) public validatorProfiles;

    constructor(address _committeeAddress) {
        committeeContract = RandomizedCommittee(_committeeAddress);
    }

    struct ValidatorProfile {
        address applicant; 
        uint256 stakingAmount;
        uint256 reputationScore; 
        bytes32 ipfsHash;
    }

    struct ValidatorRequest {
        address applicant;
        uint256 stakingAmount;
        uint256 reputationScore;
        bytes32 ipfsHash;
        ValidationStatus validationStatus; // To check if this request has already been processed by a committee
    }

    event AppliedAsValidator(address applicant, bytes32 _ipfsHash, uint256 committeeId, ValidationStatus status);
    event ValidatorRequestResponded(address applicant, ValidationStatus status);

    function applyForValidator(bytes32 _ipfsHash) external {
        ValidatorRequest memory newRequest = ValidatorRequest({
            applicant: msg.sender,
            stakingAmount: 0,
            reputationScore: 0,
            ipfsHash: _ipfsHash,
            validationStatus: ValidationStatus.Pending
        });

        validatorRequests.push(newRequest);
        uint256 committeeId = committeeContract.formCommittee(VALIDATOR_CONFIRMATION_COMMITTEE_SIZE, validatorRequests.length, 0, RandomizedCommittee.CommitteeType.Validator);
        emit AppliedAsValidator(msg.sender, _ipfsHash, committeeId, ValidationStatus.Pending);
    }

    function getValidatorProfile(address validator) external view returns (ValidatorProfile memory) {
        require(validatorProfiles[validator].applicant != address(0), "Validator does not exist");
        return validatorProfiles[validator];
    }

    function updateValidatorProposalDecision(uint256 committeeTypeId, bool finalDecision) public {
        address aplicatnt;
        if(finalDecision) {
            // Update Committee Decision
            ValidatorRequest memory newApplicant = validatorRequests[committeeTypeId];
            validatorRequests[committeeTypeId].validationStatus = ValidationStatus.Approved;
            // Create a new profile
            validatorProfiles[newApplicant.applicant].applicant = newApplicant.applicant;
            validatorProfiles[newApplicant.applicant].stakingAmount = newApplicant.stakingAmount;
            validatorProfiles[newApplicant.applicant].reputationScore = newApplicant.reputationScore;
            validatorProfiles[newApplicant.applicant].ipfsHash = newApplicant.ipfsHash;
            aplicatnt = newApplicant.applicant;
        } else {
            validatorRequests[committeeTypeId].validationStatus = ValidationStatus.Rejected;
        }
        emit ValidatorRequestResponded(aplicatnt, validatorRequests[committeeTypeId].validationStatus);
    }

}
