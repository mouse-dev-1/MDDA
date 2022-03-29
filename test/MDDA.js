const { expect } = require("chai");
const { ethers, waffle } = require("hardhat");
const Promise = require("bluebird");


let _NFT;
let NFT;

let owner;

provider = waffle.provider;

before(async function () {
  _NFT = await ethers.getContractFactory("NFT");
  NFT = await _NFT.deploy();

  [owner, minter2, minter3] = await ethers.getSigners();
});

const setCurrentBlockTime = async (newTimestamp) => {
  await network.provider.send("evm_setNextBlockTimestamp", [newTimestamp]);
  await network.provider.send("evm_mine");
};

const sendEth = (amt) => {
  return { value: ethers.utils.parseEther(amt) };
};

describe("Greeter", function () {
  it("Sets DA data", async function () {

    await NFT.initializeAuctionData(
      ethers.utils.parseEther("0.5"),
      ethers.utils.parseEther("0.1"),
      ethers.utils.parseEther("0.05"),
      180,
      Math.floor(Date.now() / 1000) - 2,
      5,
      7000
    );
  });

  it("Should expect price to be 0.5", async function () {
    console.log();
    expect((await NFT.currentPrice()).toString()).to.equal(
      "500000000000000000"
    );
  });

  it("Should mint lotsa nfts", async function () {
    for (var i = 0; i < 200; i++) {
      await NFT.connect(owner).mintDutchAuction(5, sendEth("3"));
    }
    for (var i = 0; i < 0; i++) {
      await NFT.connect(minter2).mintDutchAuction(5, sendEth("3"));
    }

    expect(await NFT.totalSupply()).to.equal(5 * 200);
  });

  it("nft should now cost 0.45", async function () {
    expect((await NFT.currentPrice()).toString()).to.equal(
      "450000000000000000"
    );
  });

  it("Should mint rest", async function () {
    for (var i = 0; i < 1200; i++) {
      await NFT.connect(minter2).mintDutchAuction(5, sendEth("3"));
    }

    expect(await NFT.totalSupply()).to.equal(5 * 200 + 5 * 1200);
  });

  it("Logs ending DA price", async function () {
    console.log(await NFT.DA_FINAL_PRICE());
  });

  it("Refunds itself all da eth", async function () {
    console.log({
      "Contract balance": (await provider.getBalance(NFT.address)).toString(),
      "User balance": (await provider.getBalance(owner.address)).toString(),
      claims: (await NFT.userToTokenBatches(owner.address)).length,
    });

    console.log("Refunding extra eth.");
    await NFT.connect(owner).refundExtraETH();

    console.log({
      "Contract balance": (await provider.getBalance(NFT.address)).toString(),
      "User balance": (await provider.getBalance(owner.address)).toString(),
      claims: (await NFT.userToTokenBatches(owner.address)).length,
    });
  });
});
