import { expect, assert } from "chai";
import { ethers } from "hardhat";

import { waitSeconds, deployMockToken, deployBank, deployUtils, deployLoanableBank, deployMockOracle, deployMockLiquidator } from "./test-helper";
import { Bank, LoanableBank, MockToken, MockLiquidator, MockOracle } from "../typechain-types";
import { SignerWithAddress } from "hardhat-deploy-ethers/signers";



let signers;
let owner: SignerWithAddress;
let admin: SignerWithAddress;
let user1: SignerWithAddress;
let user2: SignerWithAddress;
let operator: SignerWithAddress;
let borrowTokenAddr: string;
let collateralTokenAddr: string;
let unsupportedTokenAddr: string;
let bankAddr: string;
let utilsAddr: string;
let oracleAddr: string;
let liquidatorAddr: string;

let bank: LoanableBank;
let borrowToken: MockToken;
let collateralToken: MockToken;
let unsupportedToken: MockToken;
let oracle: MockOracle;
let liquidator: MockLiquidator;

let tokenId = "MockToken";
let bankId = "LoanableBank";
let oracleId = "MockOracle";
let liquidatorId = "MockLiquidator";

let validPair;
let invalidPair;

let validLoanConfig;
let disabledConfig;
let invalidLoanConfig;


before(async () => {
    signers = await ethers.getSigners();
    owner = signers[0];
    admin = signers[1];
    operator = signers[2]
    user1 = signers[3];
    user2 = signers[4];
    borrowTokenAddr = await deployMockToken("Supported Token 1", "MT1");
    collateralTokenAddr = await deployMockToken("Supported Token 2", "MT2");
    unsupportedTokenAddr = await deployMockToken("Supported Token 3", "MT3");
    utilsAddr = await deployUtils();

    oracleAddr = await deployMockOracle();
    liquidatorAddr = await deployMockLiquidator();

    oracle = await ethers.getContractAt(oracleId, oracleAddr);
    liquidator = await ethers.getContractAt(liquidatorId, liquidatorAddr);

    bankAddr = await deployLoanableBank(utilsAddr, oracleAddr, liquidatorAddr);

    bank = await ethers.getContractAt(bankId, bankAddr) as LoanableBank;
    borrowToken = await ethers.getContractAt(tokenId, borrowTokenAddr);
    await borrowToken.setBalance(user1.address, 1000);
    await borrowToken.setBalance(user2.address, 1000);
    await borrowToken.connect(user1).approve(bankAddr, 100);

    collateralToken = await ethers.getContractAt(tokenId, collateralTokenAddr);
    await collateralToken.setBalance(bank.address, 1000);
    await collateralToken.setBalance(user1.address, 1000);
    await collateralToken.setBalance(user2.address, 1000);
    await collateralToken.connect(user1).approve(bankAddr, 100);

    unsupportedToken = await ethers.getContractAt(tokenId, unsupportedTokenAddr);
    await unsupportedToken.setBalance(user1.address, 1000);
    await unsupportedToken.setBalance(user2.address, 1000);

    await bank.connect(owner).addAdmin(admin.address);

    await bank.connect(admin).addToken(borrowTokenAddr);
    await bank.connect(admin).addToken(collateralTokenAddr);

    await bank.connect(admin).addOperator(operator.address);

    validPair = {
        collateralToken: collateralTokenAddr,
        borrowToken: borrowTokenAddr
    }
    invalidPair = {
        collateralToken: unsupportedTokenAddr,
        borrowToken: borrowTokenAddr
    }
    validLoanConfig = {
        tokenPair: validPair,
        interest: 1234,
        duration: 4,
        liquidationLTV: 7123,
        enabled: true
    }
    disabledConfig = {
        tokenPair: validPair,
        interest: 1234,
        duration: 10,
        liquidationLTV: 7123,
        enabled: true
    }

    invalidLoanConfig = {
        tokenPair: invalidPair,
        interest: 1234,
        duration: 4,
        liquidationLTV: 7123,
        enabled: true
    }





});



describe("Pairs", async () => {

    describe("Adding Pairs", async () => {
        it("Should fail adding pair - Not Admin", async () => {
            await expect(bank.connect(user1).addPair(validPair)).to.be.revertedWith("RoleAccessControl:Only Admin");
        });

        it("Should fail adding pair - Unsupported Pair", async () => {
            await expect(bank.connect(admin).addPair(invalidPair)).to.be.revertedWith("Bank:Invalid token");
        });
        it("Should pass ", async () => {
            await bank.connect(admin).addPair(validPair);
        });
    })

    describe("Removing Pairs", async () => {
        it("Should fail removing pair - Not Admin", async () => {
            await expect(bank.connect(user1).removePair(validPair)).to.be.revertedWith("RoleAccessControl:Only Admin");
        });
        it("Should pass ", async () => {
            await bank.connect(admin).removePair(validPair);
        });
    })

    describe("Disabling Pairs", async () => {
        before(async () => {
            await bank.connect(admin).addPair(validPair);
        });
        it("Should fail disable pair - Not Admin", async () => {
            await expect(bank.connect(user1).disablePair(validPair)).to.be.revertedWith("RoleAccessControl:Only Admin");
        });
        it("Should pass ", async () => {
            await bank.connect(admin).disablePair(validPair);
        });
    })

});


describe("Loan config", async () => {

    describe("Adding config", async () => {
        it("Should fail adding config - Not Admin", async () => {
            await expect(bank.connect(user1).addLoanConfig(validLoanConfig)).to.be.revertedWith("RoleAccessControl:Only Admin");
        });

        it("Should fail adding config - Unsupported Pair", async () => {
            await expect(bank.connect(admin).addLoanConfig(invalidLoanConfig)).to.be.revertedWith("Bank:Invalid token");
        });
        it("Should pass ", async () => {
            await bank.connect(admin).addLoanConfig(validLoanConfig);
            await bank.connect(admin).addLoanConfig(disabledConfig);
        });

    });

    describe("Disabling config", async () => {
        it("Should fail disable config - Not Admin", async () => {
            await expect(bank.connect(user1).disableLoanConfig(disabledConfig)).to.be.revertedWith("RoleAccessControl:Only Admin");
        });
        it("Should pass ", async () => {
            await bank.connect(admin).disableLoanConfig(disabledConfig);
        });
    })



    describe("Removing config", async () => {
        it("Should fail removing config - Not Admin", async () => {
            await expect(bank.connect(user1).removeLoanConfig(validLoanConfig)).to.be.revertedWith("RoleAccessControl:Only Admin");
        });
        it("Should pass ", async () => {
            await bank.connect(admin).removeLoanConfig(validLoanConfig)
        });
    })

});

describe("Get Loan", async () => {

    before(async () => {
        await collateralToken.connect(user1).setBalance(user1.address, 200);
        await collateralToken.connect(user1).approve(bankAddr, 200);

        await bank.connect(admin).addLoanConfig(validLoanConfig);
        await bank.connect(admin).addLoanConfig(disabledConfig);

        await oracle.setPairRatio(validLoanConfig.tokenPair, 5000);
        await bank.connect(user1).deposit(collateralTokenAddr, 200);
    });

    it("Should fail - Invalid config", async () => {
        await expect(bank.connect(user1).requestLoan(validLoanConfig.tokenPair, validLoanConfig.interest, 1, 100)).to.be.revertedWith("LoanableBank: Invalid loan configuration");
    });

    it("Should fail - LTV ", async () => {
        await oracle.setPairRatio(validLoanConfig.tokenPair, 8000);
        await expect(bank.connect(user1).requestLoan(validLoanConfig.tokenPair, validLoanConfig.interest, validLoanConfig.duration, 100)).to.be.revertedWith("LoanableBank: LTV");
    });
    it("Should pass ", async () => {
        await oracle.setPairRatio(validLoanConfig.tokenPair, 5000);
        await bank.connect(user1).requestLoan(validLoanConfig.tokenPair, validLoanConfig.interest, validLoanConfig.duration, 100);

    });

    it("Should fail - Unpaid loan ", async () => {
        await expect(bank.connect(user1).requestLoan(validLoanConfig.tokenPair, validLoanConfig.interest, validLoanConfig.duration, 100)).to.be.revertedWith("LoananbleBank: You have unpaid loan");
    });


});

describe("Pay Loan", async () => {


    it("Should pass - paid ", async () => {
        await bank.connect(user1).payLoan(user1.address, 200);
    });
    it("Should pass - partial paid ", async () => {
        await oracle.setPairRatio(validLoanConfig.tokenPair, 5000);
        await bank.connect(user1).requestLoan(validLoanConfig.tokenPair, validLoanConfig.interest, validLoanConfig.duration, 100);
        await bank.connect(user1).payLoan(user1.address, 2);

    });

});

describe("Liquidate Loan", async () => {
    before(async () => {

        await collateralToken.connect(user2).setBalance(user2.address, 200);
        await collateralToken.connect(user2).approve(bankAddr, 200);

        await borrowToken.connect(user2).setBalance(bankAddr, 2000);

        await oracle.setPairRatio(validLoanConfig.tokenPair, 5000);
        await bank.connect(user2).deposit(collateralTokenAddr, 200);
        await bank.connect(user2).requestLoan(validLoanConfig.tokenPair, validLoanConfig.interest, validLoanConfig.duration, 100);

    });

    it("Should fail - Liquidation conditions not met", async () => {
        await oracle.setPairRatio(validLoanConfig.tokenPair, 5000);
        await expect(bank.connect(operator).liquidateLoan(user2.address)).to.be.revertedWith("LoanableBank: Can't liquidate");
    });

    it("Should pass ", async () => {
        await oracle.setPairRatio(validLoanConfig.tokenPair, 8000);
        await bank.connect(operator).liquidateLoan(user2.address);
    });

});

after(async () => {
    await waitSeconds(5, 0).then(await bank.connect(operator).updateLoans());
});