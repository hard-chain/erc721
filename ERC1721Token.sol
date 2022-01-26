// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./IERC721LockFirst.sol";
import "./ERC721Token.sol";

contract ERC1721Token is ERC721, ERC721Enumerable, ERC721URIStorage, IERC721LockFirst {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    string  public constant version  = "1.0.0";
    address private _contractAddr;
    string private _contractURI;

    // --- Auth ---
    mapping (address => uint) public wards;
    address private operator;
    function rely(address guy) external auth_ward { wards[guy] = 1; }
    function deny(address guy) external auth_ward { wards[guy] = 0; }
    modifier auth_ward {
        require(wards[msg.sender] == 1, "not-authorized");
        _;
    }
    
    modifier auth_oper {
        require(msg.sender == operator, "not-authorized");
        _;
    }
    
    constructor() ERC721("BNCH NFT", "BNFT") {
        wards[msg.sender] = 1;
    }

    function setContractAddr(address cAddr) external auth_oper {
        _contractAddr = cAddr;
    }
    
    function setOperator(address oper) external auth_ward {
        operator = oper;
    }
    
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
    
    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return ERC721Token(_contractAddr).balanceOf(owner);
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return ERC721Token(_contractAddr).ownerOf(tokenId);
    }
    
    /**
    * create a unique token
    */
    function mintUniqueTokenTo(address to, uint256 tokenId) external {
        require(to != address(0), "player address cannot be 0");
        ERC721Token(_contractAddr).mintUniqueTokenTo(to, tokenId);
        emit Transfer(address(0), to, tokenId);
    }

    function setTokenURI(uint256 tokenID, string memory _tokenURI) external auth_oper {
        ERC721Token(_contractAddr).setTokenURI(tokenID, _tokenURI);
    }
    
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return ERC721Token(_contractAddr).tokenURI(tokenId);
    }
    
    /**
    * Custom accessor to create a unique token
    */
    function setBaseURI(string memory baseUri) public auth_oper {
        ERC721Token(_contractAddr).setBaseURI(baseUri);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Token(_contractAddr).ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }
    
    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual override {
        _tokenApprovals[tokenId] = to;
        emit Approval(_msgSender(), to, tokenId);
    }
    
    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        // require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }
    
    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual override returns (bool) {
        // require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721Token(_contractAddr).ownerOf(tokenId);
        return spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender);
    }
    
    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        ERC721Token(_contractAddr).transferFrom(from, to, tokenId);
        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        ERC721Token(_contractAddr).safeTransferFrom(from, to, tokenId, _data);
        emit Transfer(from, to, tokenId);
    }
    
    function setContractURI(string memory uri) external auth_oper {
        _contractURI = uri;
    }
    
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
    
    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        return ERC721Token(_contractAddr).tokenOfOwnerByIndex(owner, index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return ERC721Token(_contractAddr).totalSupply();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        return ERC721Token(_contractAddr).tokenByIndex(index);
    }
    
    function lock(address to, uint256 tokenId) public virtual override {
        require(_msgSender() == _contractAddr, "ERC721: lock caller is not auth");
        emit Transfer(address(0), to, tokenId);
    }
    
    function unlock(uint256 tokenId) public auth_oper virtual override {
        ERC721Token(_contractAddr).unlock(tokenId);
    }
    
    function isLocked(uint256 tokenId) public view virtual override returns (bool) {
        return ERC721Token(_contractAddr).isLocked(tokenId);
    }
    
    function getLocked(uint256 tokenId) public view virtual override returns (address) {
        return ERC721Token(_contractAddr).getLocked(tokenId);
    }
    
    function recoveryEth(uint256 amount) external auth_oper {
        payable(operator).transfer(amount);
    }

    receive() external payable {}
}