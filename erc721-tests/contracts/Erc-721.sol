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
    string public uriSuffix = ".json";
    mapping(address => TokenMetaData[]) public ownershipRecord;
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

    function _baseURI() internal view virtual override returns (string memory) {
        return __baseURI;
    }

    function tokenURI(uint256 tokenId_) public view virtual override returns (string memory) {
        _requireMinted(tokenId_);

        return bytes(_baseURI()).length > 0 ? string(abi.encodePacked(_baseURI(), Strings.toString(tokenId_), uriSuffix)) : "";
    }

    function mintToken(address recipient, string memory name_) onlyOwner public {
        require(owner()!=recipient, "Recipient cannot be the owner of the contract");
        _safeMint(recipient, tokenId);
        ownershipRecord[recipient].push(TokenMetaData(name_, tokenId, 0, 0, tokenURI(tokenId), 0, 0));
        tokenId = tokenId + 1;
    }

    function transfer(
        address from_,
        address to_,
        uint256 tokenId_
    ) external virtual isNotLocked(tokenId) {
        _transfer(from_, to_, tokenId_);
    }

    function burn(uint256 tokenIdToBurn, int256 tokenIdToTransferExp) external virtual isNotLocked(tokenId) {
        require(_ownerOf(tokenIdToBurn) != address(0), "ERC721: invalid token ID");
        require(tokenIdToTransferExp > 0, "ERC721: invalid reciver token ID");

        uint senderexp = (getTockenMetadata(tokenIdToBurn).experience / 100) * 80;
        getTockenMetadata(uint(tokenIdToTransferExp)).experience += senderexp;

        _burn(tokenIdToBurn);
    }

    function getTockenMetadata(uint256 tokenId_) public view returns(TokenMetaData memory) {
        address tokenAddress = _ownerOf(tokenId_);
        TokenMetaData[] memory dataList = ownershipRecord[tokenAddress];
        for (uint256 i = 0; i < dataList.length; i++) {
            if (dataList[i].tokenId == tokenId_) {
                return dataList[i];
            }
        }
    }

    function lockToken(uint256 tokenId_, uint256 daysToLock) public isNotLocked(tokenId_) {
        TokenMetaData memory tokenMetaData_ = getTockenMetadata(tokenId_);

        lockRecord[tokenId_] = true;
        tokenMetaData_ = TokenMetaData(
            tokenMetaData_.name, tokenId_, block.timestamp, daysToLock, 
            tokenURI(tokenId_), tokenMetaData_.experience, tokenMetaData_.rank
        );
    }

    function unLockToken(uint256 tokenId_) public {
        TokenMetaData memory tokenMetaData_ = getTockenMetadata(tokenId_);
        uint256 lockedTimeStamp_ = tokenMetaData_.lockedTimeStamp;
        uint256 daysToLock_ = tokenMetaData_.daysToLock;

        uint diff = (block.timestamp - lockedTimeStamp_) / 60 / 60 / 24; 
        bool overLockDeadline = diff >= daysToLock_;

        require(overLockDeadline, "The token lock time is pending ...");

        addExp(tokenId_, diff * 100);
        lockRecord[tokenId_] = false;
        tokenMetaData_ = TokenMetaData(
            tokenMetaData_.name, tokenId_, tokenMetaData_.lockedTimeStamp, 0, 
            tokenURI(tokenId_), tokenMetaData_.experience, tokenMetaData_.rank
        );
    }

    function claimExp(uint256 tokenId_) public {
        TokenMetaData memory tokenMetaData_ = getTockenMetadata(tokenId_);
        uint diff = (block.timestamp - tokenMetaData_.lockedTimeStamp) / 60 / 60 / 24; 

        addExp(tokenId_, diff * 100);
        tokenMetaData_ = TokenMetaData(
            tokenMetaData_.name, tokenId_, block.timestamp, tokenMetaData_.daysToLock - diff, 
            tokenURI(tokenId_), tokenMetaData_.experience, tokenMetaData_.rank
        );
    }

    function addExp(uint256 tokenId_, uint256 expToAdd) internal {
        TokenMetaData memory tokenMetaData_ = getTockenMetadata(tokenId);

        tokenMetaData_ = TokenMetaData(
            tokenMetaData_.name, tokenId_, tokenMetaData_.lockedTimeStamp, tokenMetaData_.daysToLock, 
            tokenURI(tokenId_), tokenMetaData_.experience + expToAdd, tokenMetaData_.rank
        );
    }

    function runkUp(uint tokenId_) external {
        TokenMetaData memory tokenMetaData_ = getTockenMetadata(tokenId);
        uint experience_ = tokenMetaData_.experience;
        uint rank_ = (experience_ - (experience_ % 1000)) / 1000;

        tokenMetaData_ = TokenMetaData(tokenMetaData_.name, tokenId_, 0, 0, tokenURI(tokenId), experience_, rank_);
    }
}
