// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract CultChainAccessControl is AccessControl {
    // Define roles as bytes32 constants
    bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");
    bytes32 public constant DONOR_ROLE = keccak256("DONOR_ROLE");

    constructor() {
        // Grant the contract deployer the default admin role: it will be able
        // to grant and revoke any roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // Function to grant Validator role
    function grantValidatorRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(VALIDATOR_ROLE, account);
    }

    // Function to revoke Validator role
    function revokeValidatorRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(VALIDATOR_ROLE, account);
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
