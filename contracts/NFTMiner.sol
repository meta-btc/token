// SPDX-License-Identifier: MIT
import './libs/Counters.sol';
import './libs/ownable.sol';
import './ERC721.sol';

pragma solidity ^0.6.6;

contract NFTMiner is ERC721Pausable, Ownable {

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    mapping(address => bool) private _minters;

    constructor() public ERC721("NFTMiner", "MINER") {
        setBaseURI("https://api.meta-btc.org/nft/");
    }

    modifier onlyMinter() {
        require(_minters[_msgSender()], "ERC721: caller is not the owner");
        _;
    }

    function setBaseURI(string memory baseURI) public onlyOwner virtual {
        emit SetBaseURI(baseURI);
        _setBaseURI(baseURI);
    }

    function mint(address player) public onlyMinter returns (uint256) {
        _tokenIds.increment();
        uint256 id = _tokenIds.current();
        _mint(player, id);
        return id;
    }

    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() public virtual onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() public virtual onlyOwner whenPaused {
        _unpause();
    }

    function addMinter(address minter) public onlyOwner {
        emit AddMinter(minter);
        _minters[minter] = true;
    }

    function removeMinter(address minter) public onlyOwner {
        emit RemoveMinter(minter);
        _minters[minter] = false;
    }

    function isMinter(address minter) public view returns (bool) {
        return _minters[minter];
    }

    event SetBaseURI(string indexed baseURI);
    event AddMinter(address indexed account);
    event RemoveMinter(address indexed account);

}
