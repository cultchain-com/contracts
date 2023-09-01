// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract CultChainAccessControl is AccessControl {
    // Define roles as bytes32 constants
    bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");
    bytes32 public constant DONOR_ROLE = keccak256("DONOR_ROLE");
    bytes32 public constant COMMITTEE_MEMBER_ROLE = keccak256("COMMITTEE_MEMBER_ROLE");
    bytes32 public constant PROPOSAL_CREATOR_ROLE = keccak256("PROPOSAL_CREATOR_ROLE");

    constructor() {
        // Grant the contract deployer the default admin role: it will be able
        // to grant and revoke any roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(VALIDATOR_ROLE, msg.sender);
        _setupRole(DONOR_ROLE, msg.sender);
        _setupRole(COMMITTEE_MEMBER_ROLE, msg.sender);
        _setupRole(PROPOSAL_CREATOR_ROLE, msg.sender);
    }

    // Function to grant Validator role
    function grantValidatorRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(VALIDATOR_ROLE, account);
    }

    // Function to revoke Validator role
    function revokeValidatorRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(VALIDATOR_ROLE, account);
    }

    // Function to grant Committee Member role
    function grantCommitteeMemberRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(COMMITTEE_MEMBER_ROLE, account);
    }

    // Function to revoke Committee Member role
    function revokeCommitteeMemberRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(COMMITTEE_MEMBER_ROLE, account);
    }


    // Function to grant Proposal Creator role
    function grantProposalCreatorRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(PROPOSAL_CREATOR_ROLE, account);
    }

    // Function to revoke Proposal Creator role
    function revokeProposalCreatorRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(PROPOSAL_CREATOR_ROLE, account);
    }

    // Function to grant Donor role
    function grantDonorRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(DONOR_ROLE, account);
    }

    // Function to revoke Donor role
    function revokeDonorRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(DONOR_ROLE, account);
    }

}
