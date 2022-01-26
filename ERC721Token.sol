// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./IERC721LockFirst.sol";
import "./Utils.sol";

contract ERC721Token is Utils, ERC721, ERC721Enumerable, ERC721URIStorage, IERC721LockFirst {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    string  public constant version  = "1.0.0";
    // Mapping from token ID to exclusive license address
    mapping (uint256 => address) private _tokenExclusiveLicenses;
    // All compliant signers
    mapping (address => uint) public signers;
    // Signer corresponding to tokenID
    mapping (uint256 => address) public tokenIDSigner;

    // --- Auth ---
    mapping (address => uint) public wards;
    
    function rely(address guy) external auth { wards[guy] = 1; }
    function deny(address guy) external auth { wards[guy] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "not-authorized");
        _;
    }
    
    constructor() ERC721("BNCH NFT", "BNFT") {
        wards[msg.sender] = 1;
    }
    
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
    
    /**
    * create a unique token
    */
    function mintUniqueTokenTo(address to, uint256 tokenId) external {
        require(to != address(0), "player address cannot be 0");
        _mint(to, tokenId);
    }

    /**
    * create a unique token
    */
    function mintUniqueTokenTo(bytes memory signer_RSV, address to, uint256 tokenId) external {
        require(to != address(0), "player address cannot be 0");
        bytes32 message = encodeMessagep3(to, tokenId);
        bytes32 r;
        bytes32 s;
        uint8 v;
        (r,s,v) = splitRsv(signer_RSV);
        address signer = ecrecover(message, v, r, s);
        require(signers[signer] == 1, "signer incorrect");
        _mint(to, tokenId);
        tokenIDSigner[tokenId] = signer;
    }

    function setTokenURI(uint256 tokenID, string memory _tokenURI) external auth {
        _setTokenURI(tokenID, _tokenURI);
    }
    
    /**
    * Custom accessor to create a unique token
    */
    function setBaseURI(string memory baseUri) public auth {
        super._setBaseURI(baseUri);
    }
    
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
    function lock(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(_msgSender() == owner, "ERC721: lock caller is not owner");
        address tmp = _tokenExclusiveLicenses[tokenId];
        require(tmp == address(0), "ERC721: tokenId is locked");
        approve(to, tokenId);
        _tokenExclusiveLicenses[tokenId] = to;
        if (isContract(to)) {
            IERC721LockFirst(to).lock(owner, tokenId);
        }
        
        emit Lock(_msgSender(), to, tokenId);
    }
    
    function unlock(uint256 tokenId) external virtual override {
        address tmp = _tokenExclusiveLicenses[tokenId];
        require(_msgSender() == tmp, "ERC721: unlock caller is not auth");
        _approve(address(0), tokenId);
        _tokenExclusiveLicenses[tokenId] = address(0);
        emit UnLock(tokenId);
    }
    
    function isLocked(uint256 tokenId) public view virtual override returns (bool) {
        return _tokenExclusiveLicenses[tokenId] != address(0);
    }
    
    function getLocked(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: getLocked query for nonexistent token");
        return _tokenExclusiveLicenses[tokenId];
    }

    function setSigner(address signer) public auth {
        require(signer != address(0), "signer address cannot be 0");
        signers[signer] = 1;
    }

    function delSigner(address signer) public auth {
        require(signer != address(0), "signer address cannot be 0");
        signers[signer] = 0;
    }

    function isSigner(address signer) public view returns (bool) {
        return signers[signer] != 0;
    }

    function getSigner(uint256 tokenId) public view returns (address) {
        return tokenIDSigner[tokenId];
    }
    
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual override {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }
    
    function _transfer(address from, address to, uint256 tokenId) internal virtual override {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        if (_tokenExclusiveLicenses[tokenId] != address(0)) {
            require(_msgSender() == _tokenExclusiveLicenses[tokenId], "ERC721: transfer of token is not locked address");
        }
        require(to != address(0), "ERC721: transfer to the zero address");
        _beforeTokenTransfer(from, to, tokenId);
        // Clear approvals from the previous owner
        _approve(address(0), tokenId);
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }
}