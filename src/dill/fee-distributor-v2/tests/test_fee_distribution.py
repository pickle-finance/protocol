DAY = 86400
WEEK = 7 * DAY

def test_burn(web3, accounts, fee_distributor, coin_a):
    bob = accounts[0]
    fee_distributor = fee_distributor()

    coin_a._mint_for_testing(bob, 100 * 10 ** 18)
    coin_a.approve(fee_distributor.address, 10**18, {"from": bob})

    fee_distributor.burn(coin_a, {"from": bob, "value": 10**18})
    assert coin_a.balanceOf(fee_distributor.address) == 10**18
    web3.eth.get_balance(fee_distributor.address) == 10**18


def test_deposited_after(web3, chain, accounts, voting_escrow, fee_distributor, coin_a, token):
    alice, bob = accounts[0:2]
    amount = 1000 * 10 ** 18
    fee_distributor = fee_distributor()

    token.approve(voting_escrow.address, amount * 10, {"from": alice})
    coin_a._mint_for_testing(bob, 100 * 10 ** 18)

    for i in range(5):
        for j in range(7):
            coin_a.transfer(fee_distributor, 10 ** 18, {"from": bob})
            bob.transfer(fee_distributor, 10 ** 18)
            fee_distributor.checkpoint_token()
            fee_distributor.checkpoint_total_supply()
            chain.sleep(DAY)
            chain.mine()

    chain.sleep(WEEK)
    chain.mine()

    voting_escrow.create_lock(amount, chain[-1].timestamp + 3 * WEEK, {"from": alice})
    chain.sleep(2 * WEEK)

    alice_init_balance = alice.balance()
    fee_distributor.claim({"from": alice})

    assert coin_a.balanceOf(alice) == 0
    assert alice.balance() - alice_init_balance == 0


def test_deposited_during(web3, chain, accounts, voting_escrow, fee_distributor, coin_a, token):
    alice, bob = accounts[0:2]
    amount = 1000 * 10 ** 18

    token.approve(voting_escrow.address, amount * 10, {"from": alice})
    coin_a._mint_for_testing(bob, 100 * 10 ** 18)

    chain.sleep(WEEK)
    voting_escrow.create_lock(amount, chain[-1].timestamp + 8 * WEEK, {"from": alice})
    chain.sleep(WEEK)
    fee_distributor = fee_distributor()

    for i in range(3):
        for j in range(7):
            coin_a.transfer(fee_distributor, 10 ** 18, {"from": bob})
            bob.transfer(fee_distributor, 10 ** 18)
            fee_distributor.checkpoint_token()
            fee_distributor.checkpoint_total_supply()
            chain.sleep(DAY)
            chain.mine()

    chain.sleep(WEEK)
    fee_distributor.checkpoint_token()

    alice_init_balance = alice.balance()

    fee_distributor.claim({"from": alice})

    assert abs(coin_a.balanceOf(alice) - 21 * 10 ** 18) < 10
    assert abs(alice.balance() - alice_init_balance - 21 * 10 ** 18) < 10


def test_deposited_before(web3, chain, accounts, voting_escrow, fee_distributor, coin_a, token):
    alice, bob = accounts[0:2]
    amount = 1000 * 10 ** 18

    token.approve(voting_escrow.address, amount * 10, {"from": alice})
    coin_a._mint_for_testing(bob, 100 * 10 ** 18)

    voting_escrow.create_lock(amount, chain[-1].timestamp + 8 * WEEK, {"from": alice})
    chain.sleep(WEEK)
    chain.mine()
    start_time = int(chain.time())
    chain.sleep(WEEK * 5)

    fee_distributor = fee_distributor(t=start_time)
    coin_a.transfer(fee_distributor, 10 ** 19, {"from": bob})
    bob.transfer(fee_distributor, 10 ** 19)
    fee_distributor.checkpoint_token()
    chain.sleep(WEEK)
    fee_distributor.checkpoint_token()

    alice_init_balance = alice.balance()

    fee_distributor.claim({"from": alice})

    assert abs(coin_a.balanceOf(alice) - 10 ** 19) < 10
    assert abs(alice.balance() - alice_init_balance - 10 ** 19) < 10


def test_deposited_twice(web3, chain, accounts, voting_escrow, fee_distributor, coin_a, token):
    alice, bob = accounts[0:2]
    amount = 1000 * 10 ** 18

    token.approve(voting_escrow.address, amount * 10, {"from": alice})
    coin_a._mint_for_testing(bob, 100 * 10 ** 18)

    voting_escrow.create_lock(amount, chain[-1].timestamp + 4 * WEEK, {"from": alice})
    chain.sleep(WEEK)
    chain.mine()
    start_time = int(chain.time())
    chain.sleep(WEEK * 3)
    voting_escrow.withdraw({"from": alice})
    exclude_time = chain[-1].timestamp // WEEK * WEEK  # Alice had 0 here
    voting_escrow.create_lock(amount, chain[-1].timestamp + 4 * WEEK, {"from": alice})
    chain.sleep(WEEK * 2)

    fee_distributor = fee_distributor(t=start_time)
    coin_a.transfer(fee_distributor, 10 ** 19, {"from": bob})
    bob.transfer(fee_distributor, 10 ** 19)
    fee_distributor.checkpoint_token()
    chain.sleep(WEEK)
    fee_distributor.checkpoint_token()

    alice_init_balance = alice.balance()

    fee_distributor.claim({"from": alice})

    tokens_to_exclude = fee_distributor.tokens_per_week(exclude_time)
    eth_to_exclude = fee_distributor.eth_per_week(exclude_time)

    assert abs(10 ** 19 - coin_a.balanceOf(alice) - tokens_to_exclude) < 10
    assert abs(10 ** 19 - (alice.balance() - alice_init_balance) - eth_to_exclude) < 10


def test_deposited_parallel(web3, chain, accounts, voting_escrow, fee_distributor, coin_a, token):
    alice, bob, charlie = accounts[0:3]
    amount = 1000 * 10 ** 18

    token.approve(voting_escrow.address, amount * 10, {"from": alice})
    token.approve(voting_escrow.address, amount * 10, {"from": bob})
    token.transfer(bob, amount, {"from": alice})
    coin_a._mint_for_testing(charlie, 100 * 10 ** 18)

    voting_escrow.create_lock(amount, chain[-1].timestamp + 8 * WEEK, {"from": alice})
    voting_escrow.create_lock(amount, chain[-1].timestamp + 8 * WEEK, {"from": bob})
    chain.sleep(WEEK)
    chain.mine()
    start_time = int(chain.time())
    chain.sleep(WEEK * 5)

    fee_distributor = fee_distributor(t=start_time)
    coin_a.transfer(fee_distributor, 10 ** 19, {"from": charlie})
    charlie.transfer(fee_distributor, 10 ** 19)
    fee_distributor.checkpoint_token()
    chain.sleep(WEEK)
    fee_distributor.checkpoint_token()

    alice_init_eth_balance = alice.balance()
    bob_init_eth_balance = bob.balance()

    fee_distributor.claim({"from": alice})
    fee_distributor.claim({"from": bob})

    balance_alice = coin_a.balanceOf(alice)
    balance_bob = coin_a.balanceOf(bob)

    alice_eth_received = alice.balance() - alice_init_eth_balance
    bob_eth_received = bob.balance() - bob_init_eth_balance

    assert balance_alice == balance_bob
    assert abs(balance_alice + balance_bob - 10 ** 19) < 20
    assert alice_eth_received == bob_eth_received
    assert abs(alice_eth_received + bob_eth_received - 10 ** 19) < 20
