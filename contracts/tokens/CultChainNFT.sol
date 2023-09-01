// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CultChainNFT is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("CultChainNFT", "CCNFT") {}

    // Function to mint new NFTs
    function mint(address recipient) public onlyOwner returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _safeMint(recipient, newTokenId);
        return newTokenId;
    }

    // Optional: Function to set token URI for metadata (if you want to attach metadata to tokens)
    function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyOwner {
        setTokenURI(tokenId, _tokenURI);
    }
}
