// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract MLModelMarketplace {
    address public owner;

    struct Model {
        address payable creator;
        string modelHash; // IPFS hash or metadata
        uint price;
        bool isListed;
    }

    uint public modelCounter;
    mapping(uint => Model) public models;

    event ModelListed(uint modelId, address creator, uint price);
    event ModelPurchased(uint modelId, address buyer);

    constructor() {
        owner = msg.sender;
    }

    function listModel(string memory _modelHash, uint _price) public {
        require(_price > 0, "Price must be greater than 0");

        modelCounter++;
        models[modelCounter] = Model(payable(msg.sender), _modelHash, _price, true);

        emit ModelListed(modelCounter, msg.sender, _price);
    }

    function purchaseModel(uint _modelId) public payable {
        Model memory model = models[_modelId];
        require(model.isListed, "Model not listed");
        require(msg.value == model.price, "Incorrect payment amount");

        model.creator.transfer(msg.value);
        emit ModelPurchased(_modelId, msg.sender);
    }
}
