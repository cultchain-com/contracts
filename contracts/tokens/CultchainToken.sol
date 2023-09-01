// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CultChainTokenERC20 is ERC20, ERC20Burnable, ERC20Snapshot, Ownable {
    constructor() ERC20("CultChainToken", "CCT") {}

    // Function to mint new tokens
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    // Override _beforeTokenTransfer function to enable snapshot functionality
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC20, ERC20Snapshot) {
        super._beforeTokenTransfer(from, to, amount);
    }

    // Function to take a snapshot for historical balances
    function takeSnapshot() public onlyOwner returns (uint256) {
        return _snapshot();
    }
}
