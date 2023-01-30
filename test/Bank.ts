import { expect,assert } from "chai";
import { ethers } from "hardhat";

import {waitSeconds,deployMockToken, deployBank, deployUtils} from "./test-helper";
import { Bank, MockToken } from "../typechain-types";
import { SignerWithAddress } from "hardhat-deploy-ethers/signers";


let signers;
let owner:SignerWithAddress;
let admin:SignerWithAddress;
let user1:SignerWithAddress;
let user2:SignerWithAddress;
let supportedToken1Addr:string;
let supportedToken2Addr:string;
let unsupportedTokenAddr:string;
let bankAddr:string;
let utilsAddr:string;

let bank:Bank;
let supportedToken1:MockToken;
let supportedToken2:MockToken;
let unsupportedToken:MockToken;

let tokenId="MockToken";
let bankId="Bank";


before(async() => {
    signers = await ethers.getSigners();
        owner = signers[0];
        admin = signers[1];
        user1 = signers[2];
        user2 = signers[3];
       supportedToken1Addr= await deployMockToken("Supported Token 1","MT1");
       supportedToken2Addr= await deployMockToken("Supported Token 2","MT2");
       unsupportedTokenAddr =await deployMockToken("Supported Token 3","MT3");
       utilsAddr= await deployUtils();
       bankAddr=await deployBank(utilsAddr);

      bank= await ethers.getContractAt(bankId,bankAddr) as Bank;
      supportedToken1 = await ethers.getContractAt(tokenId,supportedToken1Addr);
      await supportedToken1.setBalance(user1.address,1000);
      await supportedToken1.setBalance(user2.address,1000);
      await supportedToken1.connect(user1).approve(bankAddr,100);

      supportedToken2 = await ethers.getContractAt(tokenId,supportedToken2Addr);
      await supportedToken2.setBalance(user1.address,1000);
      await supportedToken2.setBalance(user2.address,1000);
      await supportedToken2.connect(user1).approve(bankAddr,100);

      unsupportedToken = await ethers.getContractAt(tokenId,unsupportedTokenAddr);
      await unsupportedToken.setBalance(user1.address,1000);
      await unsupportedToken.setBalance(user2.address,1000);

});

describe("Add admin",async () => {
    it("Should fail - Not Owner ", async () => {
        await expect(bank.connect(user1).addAdmin(user2.address)).to.be.revertedWith("Ownable: caller is not the owner");
    });
    it("Should pass", async () => {
        await bank.connect(owner).addAdmin(admin.address);
    });
})

describe("Add tokens", async ()=> {

    it("Should fail - Not admin ", async () => {
        await expect(bank.connect(user1).addToken(supportedToken1Addr)).to.be.revertedWith("RoleAccessControl:Only Admin");
    });

    it("Should pass", async () => {
        await bank.connect(admin).addToken(supportedToken1Addr);
        await bank.connect(admin).addToken(supportedToken2Addr);
    });
    
});

describe("Deposit", async ()=> {

    it("Should fail - Unsupported token ", async () => {
        await expect(bank.connect(user1).deposit(unsupportedTokenAddr,100)).to.be.revertedWith("Bank:Invalid token");
    });
    it("Should fail - Insufficient allowance ", async () => {
        await expect(bank.connect(user2).deposit(supportedToken1Addr,100)).to.be.revertedWith("Bank:Insufficient allowance");
    });
    it("Should pass ", async () => {
        await bank.connect(user1).deposit(supportedToken1Addr,100);
    });
});

describe("Withdraw", async ()=> {
    it("Should fail - Unsupported token ", async () => {
        await expect(bank.connect(user1).withdraw(unsupportedTokenAddr,100)).to.be.revertedWith("Bank:Invalid token");
    });
    it("Should fail - Insufficient balance ", async () => {
        await expect(bank.connect(user1).withdraw(supportedToken1Addr,200)).to.be.revertedWith("Bank:Insufficient balance");
    });
    it("Should pass", async () => {
        await bank.connect(user1).withdraw(supportedToken1Addr,100);
    });
});

describe("Transfer", async ()=> {
    before(async() => {
        await supportedToken1.connect(user1).approve(bankAddr,100);
        await bank.connect(user1).deposit(supportedToken1Addr,100);
    });
    it("Should fail - Insufficient balance ", async () => {
        await expect(bank.connect(user1).transfer(supportedToken1Addr,user2.address,1000)).to.be.revertedWith("Bank:Insufficient balance");
    });
    it("Should pass", async () => {
        await bank.connect(user1).transfer(supportedToken1Addr,user2.address, 100);
    });
});









