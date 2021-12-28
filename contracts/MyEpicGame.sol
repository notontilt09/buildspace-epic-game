// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

// NFT contract to inherit from.
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// Helper functions OpenZeppelin provides.
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "hardhat/console.sol";
import "./libraries/Base64.sol";

contract MyEpicGame is ERC721 {
  // store character attributes in a struct
  struct CharacterAttributes {
    uint characterIndex;
    string name;
    string imageURI;
    uint hp;
    uint maxHp;
    uint attackDamage;
    string weapon;
  }

  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  // array to hold default data for characters, helpful when we mint new characters
  CharacterAttributes[] defaultCharacters;

  // mapping from tokenId to attributes struct
  mapping(uint256 => CharacterAttributes) public nftHolderAttributes;

  // mapping from address to tokenId to lookup which NFT a certain address holds
  mapping(address => uint256) public nftHolders;

  // events to listen for from the Web app
  event CharacterNFTMinted(address sender, uint256 tokenId, uint256 characterIndex);
  event AttackComplete(uint newBossHp, uint newPlayerHp);

  struct BigBoss {
    string name;
    string imageURI;
    uint hp;
    uint maxHp;
    uint attackDamage;
  }

  BigBoss public bigBoss;

// data passed into contract when it's first created
// will be passed in from run.js
  constructor(
    string[] memory characterNames,
    string[] memory characterImageURIs,
    uint[] memory characterHp,
    uint[] memory characterAttackDmg,
    string[] memory weapons,
    string memory bossName,
    string memory bossImageURI,
    uint bossHp,
    uint bossAttackDamage
  ) 
    ERC721("Whale Hunters", "WHALE")
  {
    // Initialize the boss to our global bigBoss state variable.
    bigBoss = BigBoss({
      name: bossName,
      imageURI: bossImageURI,
      hp: bossHp,
      maxHp: bossHp,
      attackDamage: bossAttackDamage
    });

    console.log("Done initializing boss %s w/ HP %s", bigBoss.name, bigBoss.hp);

    // Loop through all the characters and save their values in our contract so we can use them later when we mint
    for (uint i = 0; i < characterNames.length; i++) {
      defaultCharacters.push(
        CharacterAttributes({
          characterIndex: i,
          name: characterNames[i],
          imageURI: characterImageURIs[i],
          hp: characterHp[i],
          maxHp: characterHp[i],
          attackDamage: characterAttackDmg[i],
          weapon: weapons[i]
        })
      );

      CharacterAttributes memory c = defaultCharacters[i];
      console.log("Done initializing %s w/ HP %s to %s", c.name, c.hp, c.imageURI);
    }
    // increment tokenId so first NFT minted has ID of 1
    _tokenIds.increment();
  }

  // function for users to mint characters
  function mintCharacterNFT(uint _characterIndex) external {
    uint256 newItemId = _tokenIds.current();

    _safeMint(msg.sender, newItemId);

    // map the tokenId to the character attributes
    nftHolderAttributes[newItemId] = CharacterAttributes({
      characterIndex: _characterIndex,
      name: defaultCharacters[_characterIndex].name,
      imageURI: defaultCharacters[_characterIndex].imageURI,
      hp: defaultCharacters[_characterIndex].hp,
      maxHp: defaultCharacters[_characterIndex].hp,
      attackDamage: defaultCharacters[_characterIndex].attackDamage,
      weapon: defaultCharacters[_characterIndex].weapon
    });

    console.log("Minted an NFT with token ID %s and character index %s.", newItemId, _characterIndex);

    // update mapping to show minting address holds this itemId
    nftHolders[msg.sender] = newItemId;

    // update tokenID for next minter
    _tokenIds.increment();

    // emit Minted event
    emit CharacterNFTMinted(msg.sender, newItemId, _characterIndex);
  }

  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    CharacterAttributes memory charAttributes = nftHolderAttributes[_tokenId];

    string memory strHp = Strings.toString(charAttributes.hp);
    string memory strMaxHp = Strings.toString(charAttributes.maxHp);
    string memory strAttackDamage = Strings.toString(charAttributes.attackDamage);

    string memory json = Base64.encode(
    bytes(
      string(
        abi.encodePacked(
          '{"name": "',
          charAttributes.name,
          ' -- NFT #: ',
          Strings.toString(_tokenId),
          '", "description": "This is an NFT that lets people play in the game Beached Whale Slayer!", "image": "https://cloudflare-ipfs.com/ipfs/',
          charAttributes.imageURI,
          '", "attributes": [ { "trait_type": "Health Points", "value": ',strHp,', "max_value":',strMaxHp,'}, {"trait_type": "Weapon", "value": "',charAttributes.weapon,'"}, { "trait_type": "Attack Damage", "value": ',
          strAttackDamage,'} ]}'
          )
        )
      )
    );

    string memory output = string(
      abi.encodePacked("data:application/json;base64,", json)
    );
  
    return output;
  }

  function attackBoss() public {
    // Get the state of the player's NFT.
    uint256 nftTokenId = nftHolders[msg.sender];
    CharacterAttributes storage player = nftHolderAttributes[nftTokenId];
    console.log("\n%s is about to attack. Has %s HP and %s attack damange", player.name, player.hp, player.attackDamage);
    console.log("%s has %s HP and %s attack damage", bigBoss.name, bigBoss.hp, bigBoss.attackDamage); 
    // Make sure the player has more than 0 HP.
    require(player.hp > 0, "Player is dead and therefore cannot attack");
    // Make sure the boss has more than 0 HP.
    require(bigBoss.hp > 0, "Boss is already dead and cannot be attacked");
    // Allow player to attack boss.
    if (bigBoss.hp < player.attackDamage) {
      bigBoss.hp = 0;
    } else {
      bigBoss.hp -= player.attackDamage;
    }
    // Allow boss to attack player.
    if (keccak256(bytes(player.weapon)) == keccak256(bytes("Bush"))) { // string comparison in Solidity is weird.  Checking if player has the "Bush" Weapon to reduce boss attack damage
      uint256 bossAttack = bigBoss.attackDamage / 2;
      if (player.hp < bossAttack) {
        player.hp = 0;
      } else {
        player.hp -= bossAttack;
      }
    } else {
      if (player.hp < bigBoss.attackDamage) {
        player.hp = 0;
      } else {
        player.hp -= bigBoss.attackDamage;
      }
    }

    // log result of attack
    console.log("\nThe attack was successful. %s attacked back!  New player HP: %s.  New boss HP: %s", bigBoss.name, player.hp, bigBoss.hp);
    // emit Attack event
    emit AttackComplete(bigBoss.hp, player.hp);
  }

  function checkIfUserHasNFT() public view returns (CharacterAttributes memory) {
    // Get the tokenId of the user's character NFT
    uint256 tokenId = nftHolders[msg.sender];
    // If the user has a tokenID, return the character
    if (tokenId > 0) {
      return nftHolderAttributes[tokenId];
    } else {
    // Else, return empty character
      CharacterAttributes memory emptyStruct;
      return emptyStruct;
    }
  }

  function getAllDefaultCharacters() public view returns (CharacterAttributes[] memory) {
    return defaultCharacters;
  }

  function getBigBoss() public view returns (BigBoss memory) {
    return bigBoss;
  }
}