pragma solidity ^0.6.7

library Wallets {
  address public constant burn              = 0x000000000000000000000000000000000000dEaD;
  address public constant onesplit          = 0xC586BeF4a0992C495Cf22e1aeEE4E446CECDee0E;
  address public constant wavax             = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
  address public constant pangolinRouter    = 0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106;
  address public constant png               = 0x60781C2586D68229fde47564546784ab3fACA982;
  address public constant png_rewards       = 0x88f26b81c9cae4ea168e31BC6353f493fdA29661;
  address public constant png_avax_sushi_lp = 0xd8B262C0676E13100B33590F10564b46eeF652AD;
  address public constant sushi             = 0x39cf1BD5f15fb22eC3D9Ff86b0727aFc203427cc;



  function burn() constant returns (address) {
    return burn;
  }
  function onesplit() constant returns (address) {
    return onesplit;
  }
  function wavax() constant returns (address) {
    return wavax;
  }
  function pangolinRouter() constant returns (address) {
    return pangolinRouter;
  }
  function png() constant returns (address) {
    return png;
  }
  function png_rewards() constant returns (address) {
    return png_rewards;
  }
  function png_avax_sushi_lp() constant returns (address) {
    return png_avax_sushi_lp;
  }
  function sushi() constant returns (address) {
    return sushi;
  }

}