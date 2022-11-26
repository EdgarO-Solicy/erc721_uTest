import { Erc721 } from "../typechain-types";
import { expect } from "chai";
import { ethers } from "hardhat";
import { mine } from "@nomicfoundation/hardhat-network-helpers";

const BigNumber = require("bignumber.js");

const Web3EthAccounts = require("web3-eth-accounts");
const account = new Web3EthAccounts("ws://localhost:8546");

// smth wrong with this arithmetics. Days more than 10 going with +1
async function mineNDayBlocks(n: number) {
    await mine(11 * n, { interval: 8640 });
}

describe("ERC 721", () => {
  let erc721: Erc721;
  let tempAccount_1: any;
  let tokenId: typeof BigNumber;

  beforeEach(async () => {
    const Erc721 = await ethers.getContractFactory("Erc721");
    erc721 = await Erc721.deploy(
      "SolicyNFT",
      "HNFT",
      "https://ipfs.io/ipfs/QmSsP68DJ3BrXSFFb3e5t7xtLnXZ2mRMutrUkvYiL5yXK6/"
    );
    tempAccount_1 = account.create();

    await erc721.mintToken(tempAccount_1.address, "Solicy");
    tokenId = await erc721.getCurrentTokenId();
  });

  describe("Initialize", () => {
    it("The token Name is correct", async () => {
      expect(await erc721.name()).to.equal("SolicyNFT");
    });
    it("The token Symbol is correct", async () => {
      expect(await erc721.symbol()).to.equal("HNFT");
    });
    it("The token BaseURI is correct", async () => {
      expect(await erc721.baseURI()).to.equal(
        "https://ipfs.io/ipfs/QmSsP68DJ3BrXSFFb3e5t7xtLnXZ2mRMutrUkvYiL5yXK6/"
      );
    });
  });

  describe("Mint", () => {
    it("Creates token URI correctly", async () => {
      let currentTokenId = await erc721.getCurrentTokenId();
      expect((await erc721.baseURI()) + `${currentTokenId}.json`).to.equal(
        `https://ipfs.io/ipfs/QmSsP68DJ3BrXSFFb3e5t7xtLnXZ2mRMutrUkvYiL5yXK6/${currentTokenId}.json`
      );
    });
    it("Token minted successfully", async () => {
      await erc721.mintToken(tempAccount_1.address, "Solicy");
    });
    it("Recipient cannot be the owner of the contract", async () => {
      try {
        await erc721.mintToken(erc721.owner(), "Solicy");
      } catch (error: any) {
        expect(error.message).to.equal(
          "VM Exception while processing transaction: reverted with reason string 'Recipient cannot be the owner of the contract'"
        );
      }
    });
  });

  describe("Token transfer", async () => {
    it ("Token transferred successfully", async () => {
      const tempAccount_2 = account.create();
      tokenId = await erc721.getCurrentTokenId();

      await erc721.transferFrom(tempAccount_1.address, tempAccount_2.address, tokenId-1)
      const ownerAfterTransfer = await erc721.ownerOf(tokenId-1);
      
      expect(ownerAfterTransfer).to.equal(tempAccount_2.address);
    })
  })

  describe("Kill token", () => {
    it("Can't kill token with 0 value address", async () => {
      try {
        await erc721.killToken(3, 0);
      } catch (error: any) {
        expect(error.message).to.equal("VM Exception while processing transaction: reverted with reason string 'ERC721: invalid token ID'");
      }
    })
    it("Can't kill token while experience receiver token is with 0 value address", async () => {
      try {
        await erc721.killToken(0, 20);
      } catch (error: any) {
        expect(error.message).to.equal("VM Exception while processing transaction: reverted with reason string 'ERC721: invalid receiver token ID'");
      }
    })
    it("Token killed successfully", async () => {
      await erc721.mintToken(tempAccount_1.address, "Solicy_1");
      tokenId = await erc721.getCurrentTokenId();
      await erc721.killToken(tokenId - 1, 0);

      try {
        await erc721.ownerOf(tokenId - 1);
      } catch (error: any) {
        expect(error.reason).to.equal("ERC721: invalid token ID");
      }
    });
    it("Burn functionality is blocked", async () => {
      try {
        await erc721.burn(10);
        console.log("we are here");
      } catch (error: any) {
        expect(error.message).to.equal("VM Exception while processing transaction: reverted with reason string 'Explicitly burning of token is blocked'");
      }
    })
  })

  describe("Lock token", async () => {
    it("Token locked successfully", async () => {
      await erc721.lockToken(tokenId - 1, 1);

      expect(await erc721.getLockRecord(tokenId - 1)).to.equal(false);
    });

    it ("Token unlocked successfully", async () => {
        const tokenId_ = tokenId - 1;
        expect(await erc721.getLockRecord(tokenId_)).to.equal(true);
        await erc721.lockToken(tokenId_, 1);

        expect(await erc721.getLockRecord(tokenId_)).to.equal(false);
        
        await mineNDayBlocks(1);
        await erc721.unLockToken(tokenId_);
        expect(await erc721.getLockRecord(tokenId_)).to.equal(true);

    })
  });

  describe("Experience", async () => {
    it ("Added experience successfully.", async () => {
      const tokenId = await erc721.getCurrentTokenId();
      const expToAdd = 1234;
      
      await erc721.addExp(tokenId, expToAdd);
      const tokenData = await erc721.getMetadataRecord(tokenId);

      expect(tokenData.experience).to.equal(1234);
    })
    it ("Claimed experience successfully. Lock Time fixed.", async () => {
      const tokenId = await erc721.getCurrentTokenId();
      const daysToLock = 11;
      const minedDaysAfterLock = 5;

      await erc721.lockToken(tokenId, daysToLock);
      await mineNDayBlocks(minedDaysAfterLock);
      await erc721.claimExp(tokenId);

      const tokenData = await erc721.getMetadataRecord(tokenId);

      expect(tokenData.daysToLock).to.equal(daysToLock - minedDaysAfterLock);
      expect(tokenData.experience).to.equal(minedDaysAfterLock * 100);
    })
    it ("Token rank successfully upgraded", async () => {
      const tokenId = await erc721.getCurrentTokenId();
      const daysToLock = 13;
      const minedDaysAfterLock = 11;

      await erc721.lockToken(tokenId, daysToLock);
      await mineNDayBlocks(minedDaysAfterLock);
      await erc721.claimExp(tokenId);
      await erc721.rankUp(tokenId)

      const tokenData = await erc721.getMetadataRecord(tokenId);

      expect(tokenData.rank).to.equal(1);
    })
  })
});
