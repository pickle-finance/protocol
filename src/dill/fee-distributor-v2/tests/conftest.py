import pytest
from brownie import (
    compile_source,
    convert,
)
from brownie_tokens import ERC20

YEAR = 365 * 86400
INITIAL_RATE = 274_815_283
YEAR_1_SUPPLY = INITIAL_RATE * 10 ** 18 // YEAR * YEAR
INITIAL_SUPPLY = 1_303_030_303


def approx(a, b, precision=1e-10):
    if a == b == 0:
        return True
    return 2 * abs(a - b) / (a + b) <= precision


def pack_values(values):
    packed = b"".join(i.to_bytes(1, "big") for i in values)
    padded = packed + bytes(32 - len(values))
    return padded


@pytest.fixture(autouse=True)
def isolation_setup(fn_isolation):
    pass


# helper functions as fixtures


@pytest.fixture(scope="module")
def theoretical_supply(chain, token):
    def _fn():
        epoch = token.mining_epoch()
        q = 1 / 2 ** 0.25
        S = INITIAL_SUPPLY * 10 ** 18
        if epoch > 0:
            S += int(YEAR_1_SUPPLY * (1 - q ** epoch) / (1 - q))
        S += int(YEAR_1_SUPPLY // YEAR * q ** epoch) * (
            chain[-1].timestamp - token.start_epoch_time()
        )
        return S

    yield _fn


# account aliases


@pytest.fixture(scope="session")
def alice(accounts):
    yield accounts[0]


@pytest.fixture(scope="session")
def bob(accounts):
    yield accounts[1]


@pytest.fixture(scope="session")
def charlie(accounts):
    yield accounts[2]


@pytest.fixture(scope="session")
def receiver(accounts):
    yield accounts.at("0x0000000000000000000000000000000000031337", True)


# core contracts


@pytest.fixture(scope="module")
def token(ERC20CRV, accounts):
    yield ERC20CRV.deploy("Curve DAO Token", "CRV", 18, {"from": accounts[0]})


@pytest.fixture(scope="module")
def voting_escrow(VotingEscrow, accounts, token):
    yield VotingEscrow.deploy(
        token, "Voting-escrowed CRV", "veCRV", "veCRV_0.99", {"from": accounts[0]}
    )


@pytest.fixture(scope="module")
def fee_distributor(FeeDistributor, voting_escrow, accounts, coin_a, chain):
    def f(t=None):
        if not t:
            t = chain.time()
        return FeeDistributor.deploy(
            voting_escrow, t, coin_a, accounts[0], accounts[0], {"from": accounts[0]}
        )

    yield f

@pytest.fixture(scope="module")
def coin_a():
    yield ERC20("Coin A", "USDA", 18)