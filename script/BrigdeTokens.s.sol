//SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;
import {Script} from "forge-std/Script.sol";
import {IRouterClient} from "@ccip/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@ccip/contracts/src/v0.8/ccip/libraries/Client.sol";
import {IERC20} from "@ccip/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/ERC20.sol";

contract BridgeTokens is Script {
    function run(
        uint64 destinationChainSelector,
        address routerAdrress,
        address localToken,
        uint256 amountToBridge,
        address receiverAddress,
        address linkTokenAddress
    ) public {
        vm.startBroadcast();
        Client.EVMTokenAmount[]
            memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({
            token: address(localToken),
            amount: amountToBridge
        });
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(receiverAddress),
            data: "",
            tokenAmounts: tokenAmounts,
            feeToken: linkTokenAddress,
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: 0}))
        });
        uint256 fee = IRouterClient(routerAdrress).getFee(
            destinationChainSelector,
            message
        );
        IERC20(linkTokenAddress).approve(routerAdrress, fee);
        IERC20(localToken).approve(routerAdrress, amountToBridge);
        IRouterClient(routerAdrress).ccipSend(
            destinationChainSelector,
            message
        );

        vm.stopBroadcast();
    }
}
