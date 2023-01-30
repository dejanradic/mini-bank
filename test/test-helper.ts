import {  ethers } from "hardhat";



export async function waitSeconds (value:number, delay:number)  {
    if (!delay) {
        delay = 0;
    }
    const setTimeoutPromise = (timeout:number) => {
        return new Promise((resolve) => setTimeout(resolve, timeout));
    };
    await setTimeoutPromise(value * 1000);
    return 0;
} 

export async function deployContract( contractId:string)  {
    let factory=await ethers.getContractFactory(contractId);
    let contract = await factory.deploy();
    await contract.deployed();
    console.log(`${contractId} deployed to: ${contract.address}`)
    return contract.address;
}

export async function deployMockToken (name:string,symbol:string)  {
    let contractId = "MockToken";
    let factory=await ethers.getContractFactory(contractId);
    let contract = await factory.deploy(name,symbol);
    await contract.deployed();
    console.log(`${contractId} deployed to: ${contract.address}`)
    return contract.address
   
}
export async function deployUtils() {
    return await deployContract("Utils");
}
export async function deployBank(utilAddress:string) {
    let contractId = "Bank";
    let factory=await ethers.getContractFactory(contractId,{
        libraries:{
            Utils:utilAddress
        }
    });
    let contract = await factory.deploy();
    await contract.deployed();
    console.log(`${contractId} deployed to: ${contract.address}`)
    return contract.address
} 

export async function deployLoanableBank(utilAddress:string, ltvOracle:string, liquidator:string ) {
    let contractId = "LoanableBank";
    let factory=await ethers.getContractFactory(contractId,{
        libraries:{
            Utils:utilAddress
        }
    });
    let contract = await factory.deploy(ltvOracle,liquidator);
    await contract.deployed();
    console.log(`${contractId} deployed to: ${contract.address}`)
    return contract.address
} 

export async function deployMockOracle() {
    let contractId = "MockOracle";
    let factory=await ethers.getContractFactory(contractId);
    let contract = await factory.deploy();
    await contract.deployed();
    console.log(`${contractId} deployed to: ${contract.address}`)
    return contract.address
}

export async function deployMockLiquidator() {
    let contractId = "MockLiquidator";
    let factory=await ethers.getContractFactory(contractId);
    let contract = await factory.deploy();
    await contract.deployed();
    console.log(`${contractId} deployed to: ${contract.address}`)
    return contract.address
}




// module.exports={
//     waitSeconds: async (value:number, delay:number) => {
//         if (!delay) {
//             delay = 0;
//         }
//         const setTimeoutPromise = (timeout:number) => {
//             return new Promise((resolve) => setTimeout(resolve, timeout));
//         };
//         await setTimeoutPromise(value * 1000);
//         return 0;
//     },
//     deployContract: async ( contractId:string, args: any[]) => {
//         let factory=await ethers.getContractFactory(contractId);
//         let contract = await factory.deploy(args);
//         await contract.deployed();
//         console.log(`${contractId} deployed to: ${contract.address}`)
//         return contract.address;
//     },
//     // deployMockToken: async (name:string,symbol:string) => {
//     //     let contractId = "MockToken";
//     //     let factory=await ethers.getContractFactory(contractId);
//     //     let contract = await factory.deploy(name,symbol);
//     //     await contract.deployed();
//     //     console.log(`${contractId} deployed to: ${contract.address}`)
//     //     return contract.address;
//     // },

//     deployMockToken: async (name:string,symbol:string) => {
//         return await deployContract()
//         let contractId = "MockToken";
//         let factory=await ethers.getContractFactory(contractId);
//         let contract = await factory.deploy(name,symbol);
//         await contract.deployed();
//         console.log(`${contractId} deployed to: ${contract.address}`)
//         return contract.address;
//     },
// }