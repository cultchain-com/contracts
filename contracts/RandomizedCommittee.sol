// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./access_control/AccessControl.sol";

contract RandomizedCommittee is CultChainAccessControl {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _committeeIdCounter;

    address[] public validators;

    struct ValidatorProfile {
        address publicKey; 
        uint256 stakingAmount;
        uint256 reputationScore; 
        bytes32 ipfsHash;
    }

    struct CommitteeMember {
        bool exists;
        bool hasVoted;
        bool decision;
        string feedback;
    }

    struct CommitteeDecisionDetails {
        bool isCompleted;
        address[] validatorAddresses;
        bool[] validatorVotes;
        string[] validatorFeedbacks;
        uint256 totalValidators;
        bool finalDecision;
        string concatenatedFeedback;
    }

    struct Committee {
        mapping(address => CommitteeMember) members;
        address[] memberAddresses;
        uint256 totalMembers;
        uint256 yesVotes;
        uint256 noVotes;
    }

    mapping(uint256 => Committee) public committees;
    mapping(address => ValidatorProfile) public validatorProfiles;

    // Mapping to track which committees each validator is a part of
    mapping(address => uint256[]) public validatorCommittees;

    event CommitteeFormed(uint256 indexed committeeId, address[] members);
    event DecisionRecorded(uint256 indexed committeeId, address indexed member, bool decision, string feedback);
    event FinalDecision(uint256 indexed committeeId, bool finalDecision);


    function formCommittee(uint256 size) external onlyRole(VALIDATOR_ROLE) returns (uint256) {
        require(size <= validators.length, "Size exceeds number of validators");

        address[] memory selectedMembers = new address[](size);
        address[] memory tempSelectedMembers = new address[](validators.length); // Temporary array to track selected members

        uint256 tempCount = 0;

        for (uint256 i = 0; i < size; i++) {
            uint256 randomIndex = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, i))) % validators.length;
            address selectedMember = validators[randomIndex];

            // Ensure unique members in the committee
            bool exists = false;
            for (uint256 j = 0; j < tempCount; j++) {
                if (tempSelectedMembers[j] == selectedMember) {
                    exists = true;
                    break;
                }
            }

            while (exists) {
                randomIndex = (randomIndex + 1) % validators.length;
                selectedMember = validators[randomIndex];
                exists = false;
                for (uint256 j = 0; j < tempCount; j++) {
                    if (tempSelectedMembers[j] == selectedMember) {
                        exists = true;
                        break;
                    }
                }
            }

            tempSelectedMembers[tempCount] = selectedMember;
            tempCount++;

            selectedMembers[i] = selectedMember;
        }

        _committeeIdCounter.increment();
        uint256 newCommitteeId = _committeeIdCounter.current();

        Committee storage newCommittee = committees[newCommitteeId];
        newCommittee.totalMembers = size;
        newCommittee.yesVotes = 0;
        newCommittee.noVotes = 0;

        for (uint256 i = 0; i < size; i++) {
            newCommittee.members[selectedMembers[i]] = CommitteeMember({
                exists: true,
                hasVoted: false,
                decision: false,
                feedback: ""
            });
            committees[newCommitteeId].memberAddresses.push(selectedMembers[i]);
            validatorCommittees[selectedMembers[i]].push(newCommitteeId);
        }

        emit CommitteeFormed(newCommitteeId, selectedMembers);

        return newCommitteeId;
    }

    function GetMyDecisions() external view returns (uint256[] memory) {
        return validatorCommittees[msg.sender];
    }

    function isCommitteeMember(uint256 committeeId, address member) external view returns (bool) {
        require(committeeId <= _committeeIdCounter.current(), "Invalid committee ID");
        require(committees[committeeId].memberAddresses.length == committees[committeeId].totalMembers, "Committee not formed");

        for (uint256 i = 0; i < committees[committeeId].totalMembers; i++) {
            if (committees[committeeId].memberAddresses[i] == member) {
                return true;
            }
        }
        return false;
    }


    function recordDecision(uint256 committeeId, bool decision, string memory feedback) external onlyRole(VALIDATOR_ROLE) {
        require(committeeId <= _committeeIdCounter.current(), "Invalid committee ID");
        require(committees[committeeId].totalMembers > 0, "Committee not formed");

        Committee storage committee = committees[committeeId];

        require(!committee.members[msg.sender].hasVoted, "Already voted");

        committee.members[msg.sender] = CommitteeMember({
            exists: true,
            hasVoted: true,
            decision: decision,
            feedback: feedback
        });

        if (decision) {
            committee.yesVotes = committee.yesVotes.add(1);
        } else {
            committee.noVotes = committee.noVotes.add(1);
        }

        emit DecisionRecorded(committeeId, msg.sender, decision, feedback);

        // Check if all committee members have voted
        if (committee.yesVotes.add(committee.noVotes) == committee.totalMembers) {
            bool finalDecision = committee.yesVotes > committee.noVotes;
            emit FinalDecision(committeeId, finalDecision);
        }
    }

    function getValidatorCount() external view returns (uint256) {
        return validators.length;
    }

    function getCommitteeDecision(uint256 committeeId) external view returns (CommitteeDecisionDetails memory) {
        require(committeeId <= _committeeIdCounter.current(), "Invalid committee ID");

        Committee storage committee = committees[committeeId];
        bool isCompleted = (committee.yesVotes.add(committee.noVotes) == committee.totalMembers);

        address[] memory validatorAddresses = committee.memberAddresses;
        bool[] memory validatorVotes = new bool[](committee.totalMembers);
        string[] memory validatorFeedbacks = new string[](committee.totalMembers);

        string memory concatenatedFeedback = "";
        uint256 yesVotes = 0;
        uint256 noVotes = 0;

        for (uint256 i = 0; i < committee.totalMembers; i++) {
            address member = validatorAddresses[i];
            CommitteeMember storage committeeMember = committee.members[member];

            validatorVotes[i] = committeeMember.decision;
            validatorFeedbacks[i] = committeeMember.feedback;

            if (committeeMember.decision) {
                yesVotes++;
            } else {
                noVotes++;
            }

            concatenatedFeedback = string(abi.encodePacked(concatenatedFeedback, committeeMember.feedback, "; "));
        }

        bool finalDecision = yesVotes > noVotes;

        return CommitteeDecisionDetails({
            isCompleted: isCompleted,
            validatorAddresses: validatorAddresses,
            validatorVotes: validatorVotes,
            validatorFeedbacks: validatorFeedbacks,
            totalValidators: committee.totalMembers,
            finalDecision: finalDecision,
            concatenatedFeedback: concatenatedFeedback
        });
    }

    function getMyPastDecisions() external view returns (uint256[] memory) {
        uint256[] memory myCommittees = validatorCommittees[msg.sender];
        uint256[] memory pastCommittees = new uint256[](0); // Initialize an empty memory array
        uint256 pastCount = 0;

        for (uint256 i = 0; i < myCommittees.length; i++) {
            uint256 committeeId = myCommittees[i];
            Committee storage committee = committees[committeeId];
            if (committee.yesVotes.add(committee.noVotes) == committee.totalMembers) {
                // This is a past committee

                // Create a new memory array with a length one greater than pastCommittees
                uint256[] memory newPastCommittees = new uint256[](pastCount + 1);

                // Copy the existing elements
                for (uint256 j = 0; j < pastCount; j++) {
                    newPastCommittees[j] = pastCommittees[j];
                }

                // Add the new element
                newPastCommittees[pastCount] = committeeId;

                // Replace the old array with the new one
                pastCommittees = newPastCommittees;

                // Increment the past committee count
                pastCount++;
            }
        }

        return pastCommittees;
    }

    function getMyOngoingDecisions() external view returns (uint256[] memory) {
        uint256[] memory myCommittees = validatorCommittees[msg.sender];
        uint256[] memory ongoingCommittees = new uint256[](0); // Initialize an empty memory array
        uint256 ongoingCount = 0;

        for (uint256 i = 0; i < myCommittees.length; i++) {
            uint256 committeeId = myCommittees[i];
            Committee storage committee = committees[committeeId];
            if (committee.yesVotes.add(committee.noVotes) < committee.totalMembers) {
                // This is an ongoing committee

                // Create a new memory array with a length one greater than ongoingCommittees
                uint256[] memory newOngoingCommittees = new uint256[](ongoingCount + 1);

                // Copy the existing elements
                for (uint256 j = 0; j < ongoingCount; j++) {
                    newOngoingCommittees[j] = ongoingCommittees[j];
                }

                // Add the new element
                newOngoingCommittees[ongoingCount] = committeeId;

                // Replace the old array with the new one
                ongoingCommittees = newOngoingCommittees;

                // Increment the ongoing committee count
                ongoingCount++;
            }
        }

        return ongoingCommittees;
    }

    function getAllOngoingDecisions() external view returns (uint256[] memory) {
        uint256 ongoingCount = 0;
        uint256[] memory ongoingCommittees = new uint256[](_committeeIdCounter.current());

        for (uint256 i = 1; i <= _committeeIdCounter.current(); i++) {
            Committee storage committee = committees[i];
            if (committee.yesVotes.add(committee.noVotes) < committee.totalMembers) {
                ongoingCommittees[ongoingCount] = i;
                ongoingCount++;
            }
        }

        // Trim the array to the correct size
        uint256[] memory trimmedOngoingCommittees = new uint256[](ongoingCount);
        for (uint256 i = 0; i < ongoingCount; i++) {
            trimmedOngoingCommittees[i] = ongoingCommittees[i];
        }

        return trimmedOngoingCommittees;
    }


    function getAllPastDecisions() external view returns (uint256[] memory) {
        uint256 pastCount = 0;
        uint256[] memory pastCommittees = new uint256[](_committeeIdCounter.current());

        for (uint256 i = 1; i <= _committeeIdCounter.current(); i++) {
            Committee storage committee = committees[i];
            if (committee.yesVotes.add(committee.noVotes) == committee.totalMembers) {
                pastCommittees[pastCount] = i;
                pastCount++;
            }
        }

        // Trim the array to the correct size
        uint256[] memory trimmedPastCommittees = new uint256[](pastCount);
        for (uint256 i = 0; i < pastCount; i++) {
            trimmedPastCommittees[i] = pastCommittees[i];
        }

        return trimmedPastCommittees;
    }


    function addValidator(address newValidator) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Check if the newValidator is not already a validator
        for (uint256 i = 0; i < validators.length; i++) {
            require(validators[i] != newValidator, "Address is already a validator");
        }
    
        // Add newValidator to the validators array
        validators.push(newValidator);
        grantRole(VALIDATOR_ROLE, newValidator);
    }

    function removeValidator(address validatorToRemove) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 index = validators.length + 1; // Initialize to an invalid index
    
        // Find the index of the validator to remove
        for (uint256 i = 0; i < validators.length; i++) {
            if (validators[i] == validatorToRemove) {
                index = i;
                break;
            }
        }
    
        // Check if the validator was found
        require(index < validators.length, "Validator not found");
    
        // Remove the validator by swapping it with the last element and then popping from the array
        validators[index] = validators[validators.length - 1];
        validators.pop();
        revokeRole(VALIDATOR_ROLE, validatorToRemove);
    }

    function getValidatorProfile(address validator) external view returns (ValidatorProfile memory) {
        require(validatorProfiles[validator].publicKey != address(0), "Validator does not exist");
        return validatorProfiles[validator];
    }
}
