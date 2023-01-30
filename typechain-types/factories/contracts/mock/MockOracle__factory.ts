/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PromiseOrValue } from "../../../common";
import type {
  MockOracle,
  MockOracleInterface,
} from "../../../contracts/mock/MockOracle";

const _abi = [
  {
    inputs: [
      {
        components: [
          {
            internalType: "address",
            name: "collateralToken",
            type: "address",
          },
          {
            internalType: "address",
            name: "borrowToken",
            type: "address",
          },
        ],
        internalType: "struct Globals.Pair",
        name: "pair",
        type: "tuple",
      },
    ],
    name: "getPairRatio",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        components: [
          {
            internalType: "address",
            name: "collateralToken",
            type: "address",
          },
          {
            internalType: "address",
            name: "borrowToken",
            type: "address",
          },
        ],
        internalType: "struct Globals.Pair",
        name: "pair",
        type: "tuple",
      },
      {
        internalType: "uint256",
        name: "ratio",
        type: "uint256",
      },
    ],
    name: "setPairRatio",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
] as const;

const _bytecode =
  "0x608060405234801561001057600080fd5b50610260806100206000396000f3fe608060405234801561001057600080fd5b50600436106100365760003560e01c806362486b1c1461003b5780636ef5806c14610050575b600080fd5b61004e6100493660046101dc565b610075565b005b61006361005e366004610207565b6100dd565b60405190815260200160405180910390f35b806000806100c885602081810151915160408051606094851b6bffffffffffffffffffffffff19908116828601529290941b90911660348401528051602881850301815260489093019052815191012090565b81526020810191909152604001600020555050565b600080600061013184602081810151915160408051606094851b6bffffffffffffffffffffffff19908116828601529290941b90911660348401528051602881850301815260489093019052815191012090565b8152602001908152602001600020549050919050565b803573ffffffffffffffffffffffffffffffffffffffff8116811461016b57600080fd5b919050565b60006040828403121561018257600080fd5b6040516040810181811067ffffffffffffffff821117156101b357634e487b7160e01b600052604160045260246000fd5b6040529050806101c283610147565b81526101d060208401610147565b60208201525092915050565b600080606083850312156101ef57600080fd5b6101f98484610170565b946040939093013593505050565b60006040828403121561021957600080fd5b6102238383610170565b939250505056fea2646970667358221220dad11b4ad227f33c66d82f2538022cbecf61654dfee8cf1b18e6412983d1ab4364736f6c63430008110033";

type MockOracleConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: MockOracleConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class MockOracle__factory extends ContractFactory {
  constructor(...args: MockOracleConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override deploy(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<MockOracle> {
    return super.deploy(overrides || {}) as Promise<MockOracle>;
  }
  override getDeployTransaction(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(overrides || {});
  }
  override attach(address: string): MockOracle {
    return super.attach(address) as MockOracle;
  }
  override connect(signer: Signer): MockOracle__factory {
    return super.connect(signer) as MockOracle__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): MockOracleInterface {
    return new utils.Interface(_abi) as MockOracleInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): MockOracle {
    return new Contract(address, _abi, signerOrProvider) as MockOracle;
  }
}
