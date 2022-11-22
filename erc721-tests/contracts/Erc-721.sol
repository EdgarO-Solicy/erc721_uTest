// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "hardhat/console.sol";

contract Erc721 is Ownable, ERC721("SolicyNFT", "HNFT") {
    uint256 tokenId = 0;
    string public _name;
    string public _symbol;
    string public __baseURI;
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

    constructor(string memory name_, string memory symbol_, string memory baseURI_) {
        _name = name_;
        _symbol = symbol_;
        __baseURI = baseURI_;
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

    function mintToken(address recipient, string memory name_) onlyOwner public {
        require(owner()!=recipient, "Recipient cannot be the owner of the contract");
        _safeMint(recipient, tokenId);

        metadataRecord[tokenId] = TokenMetaData(name_, tokenId, 0, 0, tokenURI(tokenId), 0, 0);

        tokenId = tokenId + 1;
    }

    function transfer (
        address from_,
        address to_,
        uint256 tokenId_
    ) external virtual isNotLocked(tokenId) {
        _transfer(from_, to_, tokenId_);
    }

    function burn(uint256 tokenIdToBurn, int256 tokenIdToTransferExp) external virtual isNotLocked(tokenId) {
        require(_ownerOf(tokenIdToBurn) != address(0), "ERC721: invalid token ID");
        require(tokenIdToTransferExp > 0, "ERC721: invalid reciver token ID");

        uint senderexp = (metadataRecord[tokenIdToBurn].experience * 80) / 100;
        metadataRecord[uint256(tokenIdToTransferExp)].experience += senderexp;

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

        uint diff = (block.timestamp - lockedTimeStamp_) / 60 / 60 / 24;
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

    function runkUp(uint tokenId_) external {
        uint experience_ = metadataRecord[tokenId_].experience;
        uint rank_ = (experience_ - (experience_ % 1000)) / 1000;

        metadataRecord[tokenId_].experience = experience_;
        metadataRecord[tokenId_].rank = rank_;
    }
}

