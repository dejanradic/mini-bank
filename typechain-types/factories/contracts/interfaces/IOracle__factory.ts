/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Contract, Signer, utils } from "ethers";
import type { Provider } from "@ethersproject/providers";
import type {
  IOracle,
  IOracleInterface,
} from "../../../contracts/interfaces/IOracle";

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
        name: "",
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
] as const;

export class IOracle__factory {
  static readonly abi = _abi;
  static createInterface(): IOracleInterface {
    return new utils.Interface(_abi) as IOracleInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): IOracle {
    return new Contract(address, _abi, signerOrProvider) as IOracle;
  }
}
