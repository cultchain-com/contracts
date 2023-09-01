// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Validator is AccessControl {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");
    bytes32 public constant DAO_COMMITTEE_ROLE = keccak256("DAO_COMMITTEE_ROLE");

    Counters.Counter private _validatorIdCounter;
    Counters.Counter private _proposalIdCounter;

    address[] public validatorList;

    struct ValidatorProfile {
        address account;
        string name;
        bool isApproved;
    }

    struct Proposal {
        uint256 id;
        address creator;
        string description;
        uint256 yesVotes;
        uint256 noVotes;
        mapping(address => bool) hasVoted;
    }

    mapping(address => ValidatorProfile) public validators;
    mapping(uint256 => Proposal) public proposals;

    event ValidatorApplied(address indexed applicant, string name);
    event ValidatorApproved(address indexed validator);
    event ProposalCreated(uint256 indexed proposalId, address indexed creator, string description);
    event Voted(address indexed validator, uint256 indexed proposalId, bool vote);
    event ValidatorAssigned(address indexed validator, uint256 indexed proposalId);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function applyAsValidator(string memory name) external {
        require(!hasRole(VALIDATOR_ROLE, msg.sender), "Already a validator");
        require(validators[msg.sender].account == address(0), "Already applied");

        validators[msg.sender] = ValidatorProfile({
            account: msg.sender,
            name: name,
            isApproved: false
        });

        emit ValidatorApplied(msg.sender, name);
    }

    function approveValidator(address validatorAddress) external onlyRole(DAO_COMMITTEE_ROLE) {
        require(validators[validatorAddress].account != address(0), "Validator not found");
        require(!validators[validatorAddress].isApproved, "Validator already approved");

        validators[validatorAddress].isApproved = true;
        _setupRole(VALIDATOR_ROLE, validatorAddress);
        validatorList.push(validatorAddress);

        emit ValidatorApproved(validatorAddress);
    }

    function createProposal(string memory description) external onlyRole(VALIDATOR_ROLE) {
        _proposalIdCounter.increment();
        uint256 newProposalId = _proposalIdCounter.current();

        Proposal storage newProposal = proposals[newProposalId];
        newProposal.id = newProposalId;
        newProposal.creator = msg.sender;
        newProposal.description = description;
        newProposal.yesVotes = 0;
        newProposal.noVotes = 0;

        emit ProposalCreated(newProposalId, msg.sender, description);

        // Assign a random validator for the proposal
        address randomValidator = getRandomValidator();
        emit ValidatorAssigned(randomValidator, newProposalId);
    }


    function vote(uint256 proposalId, bool vote) external onlyRole(VALIDATOR_ROLE) {
        require(proposals[proposalId].id == proposalId, "Proposal not found");
        require(!proposals[proposalId].hasVoted[msg.sender], "Already voted on this proposal");

        if (vote) {
            proposals[proposalId].yesVotes = proposals[proposalId].yesVotes.add(1);
        } else {
            proposals[proposalId].noVotes = proposals[proposalId].noVotes.add(1);
        }

        proposals[proposalId].hasVoted[msg.sender] = true;

        emit Voted(msg.sender, proposalId, vote);
    }

    function getRandomValidator() internal view returns (address) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, validatorList.length)));
        return validatorList[random % validatorList.length];
    }

}
