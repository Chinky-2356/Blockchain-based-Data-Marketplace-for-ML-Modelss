// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract MLModelMarketplace {
    address public owner;

    struct Model {
        address payable creator;
        string modelHash;
        uint price;
        bool isListed;
    }

    uint public modelCounter;
    mapping(uint => Model) public models;

    mapping(uint => mapping(address => bool)) public hasPurchased;

    event ModelListed(uint modelId, address creator, uint price);
    event ModelPurchased(uint modelId, address buyer);
    event ModelUnlisted(uint modelId);
    event PriceUpdated(uint modelId, uint newPrice);
    event ModelRelisted(uint modelId);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);
    event ContractDestroyed(address by);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

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
        Model storage model = models[_modelId];
        require(model.isListed, "Model not listed");
        require(msg.value == model.price, "Incorrect payment amount");

        model.isListed = false; // Mark as sold
        model.creator.transfer(msg.value);
        hasPurchased[_modelId][msg.sender] = true;

        emit ModelPurchased(_modelId, msg.sender);
    }

    function getModel(uint _modelId) public view returns (
        address creator,
        string memory modelHash,
        uint price,
        bool isListed
    ) {
        Model memory model = models[_modelId];
        return (model.creator, model.modelHash, model.price, model.isListed);
    }

    function getAllModelHashes() public view returns (string[] memory) {
        string[] memory hashes = new string[](modelCounter);
        for (uint i = 1; i <= modelCounter; i++) {
            hashes[i - 1] = models[i].modelHash;
        }
        return hashes;
    }

    function unlistModel(uint _modelId) public {
        Model storage model = models[_modelId];
        require(model.creator == msg.sender, "Only creator can unlist");
        require(model.isListed, "Already unlisted");

        model.isListed = false;
        emit ModelUnlisted(_modelId);
    }

    function updatePrice(uint _modelId, uint _newPrice) public {
        Model storage model = models[_modelId];
        require(model.creator == msg.sender, "Only creator can update");
        require(model.isListed, "Model must be listed");
        require(_newPrice > 0, "Price must be greater than zero");

        model.price = _newPrice;
        emit PriceUpdated(_modelId, _newPrice);
    }

    function relistModel(uint _modelId, uint _newPrice) public {
        Model storage model = models[_modelId];
        require(model.creator == msg.sender, "Only creator can relist");
        require(!model.isListed, "Already listed");
        require(_newPrice > 0, "Price must be greater than 0");

        model.price = _newPrice;
        model.isListed = true;

        emit ModelRelisted(_modelId);
    }

    function getAllListedModels() public view returns (Model[] memory) {
        uint count = 0;
        for (uint i = 1; i <= modelCounter; i++) {
            if (models[i].isListed) {
                count++;
            }
        }

        Model[] memory listedModels = new Model[](count);
        uint index = 0;
        for (uint i = 1; i <= modelCounter; i++) {
            if (models[i].isListed) {
                listedModels[index] = models[i];
                index++;
            }
        }

        return listedModels;
    }

    function getModelsByCreator(address _creator) public view returns (Model[] memory) {
        uint count = 0;
        for (uint i = 1; i <= modelCounter; i++) {
            if (models[i].creator == _creator) {
                count++;
            }
        }

        Model[] memory creatorModels = new Model[](count);
        uint index = 0;
        for (uint i = 1; i <= modelCounter; i++) {
            if (models[i].creator == _creator) {
                creatorModels[index] = models[i];
                index++;
            }
        }

        return creatorModels;
    }

    function isBuyer(uint _modelId, address _user) public view returns (bool) {
        return hasPurchased[_modelId][_user];
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function destroyContract() public onlyOwner {
        emit ContractDestroyed(msg.sender);
        selfdestruct(payable(owner));
    }
}
