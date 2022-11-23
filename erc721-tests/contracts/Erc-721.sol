// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "hardhat/console.sol";

contract Erc721 is ERC721, Ownable {
    uint256 tokenId = 0;
    string public __baseURI;
    string public _name;
    string public _symbol;
    mapping(uint256 => TokenMetaData) public metadataRecord;
    mapping(uint256 => bool) internal lockRecord;

    struct TokenMetaData {
        string name;
        uint tokenId;
        uint256 lockedTimeStamp;
        uint256 daysToLock;
        string tokenURI;
        uint experience;
        uint rank;
    }

    modifier isNotLocked (uint256 tokenId_) {
        require(lockRecord[tokenId_] == false, "The token is loked");
        _;
    }

    modifier tokenOwner (uint256 tokenId_) {
        require((msg.sender == ownerOf(tokenId_)), "Don't have permission to manipulate this token");
        _;
    }

    constructor(string memory name_, string memory symbol_, string memory baseURI_) ERC721(name_, symbol_) {
        __baseURI = baseURI_;
    }

    function getLockRecord(uint256 tokenId_) public view returns(bool) {
        return lockRecord[tokenId_] == false;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function baseURI() public view virtual returns (string memory) {
        return __baseURI;
    }

    function tokenURI(uint256 tokenId_) public view virtual override returns (string memory) {
        _requireMinted(tokenId_);

        return bytes(baseURI()).length > 0 ? string(abi.encodePacked(baseURI(), Strings.toString(tokenId_), ".json")) : "";
    }

    function getCurrentTokenId() public view returns (uint256) {
        return tokenId;
    } 
    
    // +
    function mintToken(address recipient, string memory name_) onlyOwner public { 
        require(owner()!=recipient, "Recipient cannot be the owner of the contract");
        _safeMint(recipient, tokenId);

        metadataRecord[tokenId] = TokenMetaData(name_, tokenId, 0, 0, tokenURI(tokenId), 0, 0);

        tokenId = tokenId + 1;
    }

    function transferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public override virtual isNotLocked(tokenId_) tokenOwner(tokenId_) {
        
        _transfer(from_, to_, tokenId_);
    }

    function killToken(uint256 tokenIdToBurn, uint256 tokenIdToTransferExp) external virtual isNotLocked(tokenId) {
        require(_ownerOf(tokenIdToBurn) != address(0), "ERC721: invalid token ID");
        require(_ownerOf(tokenIdToTransferExp) != address(0), "ERC721: invalid reciver token ID");

        uint senderexp = (metadataRecord[tokenIdToBurn].experience * 80) / 100;
        metadataRecord[uint256(tokenIdToTransferExp)].experience += senderexp;

        _burn(tokenIdToBurn);
    }

    function burn(uint256 tokenIdToBurn) external virtual isNotLocked(tokenId) {
        require(false, "Explicitely burning of token is bloked");
        _burn(tokenIdToBurn);
    }

    function lockToken(uint256 tokenId_, uint256 daysToLock) public isNotLocked(tokenId_) {
        metadataRecord[tokenId_].lockedTimeStamp = block.timestamp;
        metadataRecord[tokenId_].daysToLock = daysToLock;

        lockRecord[tokenId_] = true;
    }

    function unLockToken(uint256 tokenId_) public {
        uint256 lockedTimeStamp_ =  metadataRecord[tokenId_].lockedTimeStamp;
        uint256 daysToLock_ = metadataRecord[tokenId_].daysToLock;

        uint diff = (block.timestamp - lockedTimeStamp_) / (1 days);
        bool overLockDeadline = diff >= daysToLock_;

        require(overLockDeadline, "The token lock time is pending ...");

        addExp(tokenId_, diff * 100);

        metadataRecord[tokenId_].lockedTimeStamp = 0;
        metadataRecord[tokenId_].daysToLock = 0;
        lockRecord[tokenId_] = false;
    }

    function claimExp(uint256 tokenId_) public {
        uint diff = (block.timestamp -  metadataRecord[tokenId_].lockedTimeStamp) / 60 / 60 / 24; 
        addExp(tokenId_, diff * 100);
        
        metadataRecord[tokenId_].lockedTimeStamp = block.timestamp;
        metadataRecord[tokenId_].daysToLock -= diff;
    }

    function addExp(uint256 tokenId_, uint256 expToAdd) public {
        metadataRecord[tokenId_].experience += expToAdd;
    }

    function runkUp(uint tokenId_) external tokenOwner(tokenId_) {
        uint experience_ = metadataRecord[tokenId_].experience;
        uint rank_ = (experience_ - (experience_ % 1000)) / 1000;

        metadataRecord[tokenId_].experience = experience_;
        metadataRecord[tokenId_].rank = rank_;
    }
}
