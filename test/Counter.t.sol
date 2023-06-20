// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../src/WormholeRelayerSDK.sol";
import "../src/interfaces/IWormholeReceiver.sol";
import "../src/interfaces/IWormholeRelayer.sol";
import "../src/interfaces/IERC20.sol";

import "../src/testing/WormholeRelayerTest.sol";

import "forge-std/console.sol";

contract Toy is IWormholeReceiver {
    IWormholeRelayer relayer;

    uint public payloadReceived;

    constructor(address _wormholeRelayer) {
        relayer = IWormholeRelayer(_wormholeRelayer);
    }

    function receiveWormholeMessages(
        bytes memory payload,
        bytes[] memory additionalVaas,
        bytes32, //sourceAddress,
        uint16, //sourceChain,
        bytes32 //deliveryHash
    ) public payable {
        require(msg.sender == address(relayer), "Only relayer can call");
        payloadReceived = abi.decode(payload, (uint));

        console.log("Toy received message");
        console.log("Payload", payloadReceived);
        console.log("Value Received", msg.value);
    }
}

contract WormholeSDKTest is WormholeRelayerTest {

    Toy toySource;
    Toy toyTarget;

    function setUpSource() public override {
        toySource = new Toy(address(relayerSource));
    }

    function setUpTarget() public override {
        toyTarget = new Toy(address(relayerTarget));
    }

    function testSendMessage() public {
        vm.recordLogs();
        (uint cost, ) = relayerSource.quoteEVMDeliveryPrice(
            targetChain,
            1e17,
            50_000
        );
        relayerSource.sendPayloadToEvm{value: cost}(
            targetChain,
            address(toyTarget),
            abi.encode(55),
            1e17,
            50_000
        );
        performDelivery();

        vm.selectFork(targetFork);
        require(55 == toyTarget.payloadReceived());
    }

    function testSendMessageSource() public {
        
        vm.selectFork(targetFork);
        vm.recordLogs();

        (uint cost, ) = relayerTarget.quoteEVMDeliveryPrice(
            sourceChain,
            1e17,
            50_000
        );
        relayerTarget.sendPayloadToEvm{value: cost}(
            sourceChain,
            address(toySource),
            abi.encode(56),
            1e17,
            50_000
        );
        performDelivery();

        vm.selectFork(sourceFork);
        require(56 == toySource.payloadReceived());


    }
}
