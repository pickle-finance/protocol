from brownie import ZERO_ADDRESS

WEEK = 86400 * 7


def test_claim_many(alice, bob, charlie, chain, voting_escrow, fee_distributor, coin_a, token):
    amount = 1000 * 10 ** 18

    for acct in (alice, bob, charlie):
        token.approve(voting_escrow, amount * 10, {"from": acct})
        token.transfer(acct, amount, {"from": alice})
        voting_escrow.create_lock(amount, chain.time() + 8 * WEEK, {"from": acct})

    chain.sleep(WEEK)
    chain.mine()
    start_time = int(chain.time())
    chain.sleep(WEEK * 5)

    fee_distributor = fee_distributor(t=start_time)
    coin_a._mint_for_testing(fee_distributor, 10 ** 19)
    charlie.transfer(fee_distributor, 10 ** 19)
    fee_distributor.checkpoint_token()
    chain.sleep(WEEK)
    fee_distributor.checkpoint_token()

    fee_distributor.claim_many([alice, bob, charlie] + [ZERO_ADDRESS] * 17, {"from": alice})

    token_balances = [coin_a.balanceOf(i) for i in (alice, bob, charlie)]
    eth_balances = [i.balance() for i in (alice, bob, charlie)]

    chain.undo()

    fee_distributor.claim({"from": alice})
    fee_distributor.claim({"from": bob})
    fee_distributor.claim({"from": charlie})

    assert token_balances == [coin_a.balanceOf(i) for i in (alice, bob, charlie)]
    assert eth_balances == [i.balance() for i in (alice, bob, charlie)]


def test_claim_many_same_account(
    alice, bob, charlie, chain, voting_escrow, fee_distributor, coin_a, token
):
    amount = 1000 * 10 ** 18

    for acct in (alice, bob, charlie):
        token.approve(voting_escrow, amount * 10, {"from": acct})
        token.transfer(acct, amount, {"from": alice})
        voting_escrow.create_lock(amount, chain.time() + 8 * WEEK, {"from": acct})

    chain.sleep(WEEK)
    chain.mine()
    start_time = int(chain.time())
    chain.sleep(WEEK * 5)

    fee_distributor = fee_distributor(t=start_time)
    coin_a._mint_for_testing(fee_distributor, 10 ** 19)
    charlie.transfer(fee_distributor, 10 ** 19)
    fee_distributor.checkpoint_token()
    chain.sleep(WEEK)
    fee_distributor.checkpoint_token()

    expected_tokens, expected_eth = fee_distributor.claim.call({"from": alice})

    alice_init_eth_bal = alice.balance()
    fee_distributor.claim_many([alice] * 20, {"from": alice})

    assert coin_a.balanceOf(alice) == expected_tokens
    assert alice.balance() - alice_init_eth_bal == expected_eth
