# Pickle's Security Process

While audits of the protocol can be found [here](https://github.com/pickle-finance/protocol/tree/master/audits), a bug bounty program is necessary to further ensure the safety of the protocol. This document describes the bug bounty in detail and other security considerations.

This document describes the Security Process for Pickle Finance, including vulnerability disclosures and its [Bug Bounty program](#bug-bounty-program). We are committed to conduct our Security Process in a professional and civil manner. Public shaming, under-reporting, or misrepresentation of vulnerabilities will not be tolerated.

Pickle Finance's Bug Bounty Program was born from [discussions](https://forum.pickle.finance/t/rfc-bug-bounty-program/545) on the forum. The program is heavily inspired by Yearn's own [program](https://github.com/iearn-finance/yearn-protocol/blob/develop/SECURITY.md).

To submit a finding, please follow the steps outlined in receiving disclosures [section](#receiving-disclosures).

## Responsible Disclosure Standard

Pickle Finance follows a community [standard](https://github.com/RD-Crypto-Spec/Responsible-Disclosure#the-standard) for responsible disclosure in cryptocurrency and related software. This document is a public commitment to
following the standard.

This standard provides detailed information for:

-   [Initial Contact](https://github.com/RD-Crypto-Spec/Responsible-Disclosure#initial-contact): how to establish initial contact with Pickle Finance's security team.
-   [Giving Details](https://github.com/RD-Crypto-Spec/Responsible-Disclosure#giving-details): what details to include with your vulnerability disclosure after having received a response to your initial contact.
-   [Setting Dates](https://github.com/RD-Crypto-Spec/Responsible-Disclosure#setting-dates): how to agree on timelines for releasing updates and making details of the issue public.

Any expected deviations and necessary clarifications around the standard are explained in the following sections.

## Receiving Disclosures

Pickle Finance is committed to working with researchers who submit security vulnerability notifications to us, to resolve those issues on an appropriate timeline, and to perform a coordinated release, giving credit to the reporter if they would so like.

Please submit issues to **all** of the following main points of contact for
security related issues according to the
[initial contact](https://github.com/RD-Crypto-Spec/Responsible-Disclosure#initial-contact)
and [giving details](https://github.com/RD-Crypto-Spec/Responsible-Disclosure#giving-details)
guidelines.

For all security related issues, Pickle has the following contact information:

| Contact | Email | Keybase |
| ------- | ----- | ------- | 
| BigBrainBriner | bigbrainbriner at protonmail.com | [@bigbrainbriner](https://keybase.io/bigbrainbriner) |
| 0xPenguin | X at X.com | [@username](https://keybase.io/username) |
| Larry the Cucumber | larrythecucumber321 at gmail.com | [@username](https://keybase.io/larrythecucumber) |


Include all contacts in your communication when possible, PGP encrypted to all parties.

You can also reach out informally over keybase encrypted chat to one or more of the contacts as per the details above. If you need help with this, you can ask for help on the Pickle [Discord](http://discord.gg/gR85hmC).

## Sending Disclosures

In the case where we become aware of security issues affecting other projects that has never affected Pickle Finance, our intention is to inform those projects of security issues on a best effort basis.

In the case where we fix a security issue in Pickle Finance that also affects the following neighboring projects, our intention is to engage in responsible disclosures with them as described in the adopted [standard](https://github.com/RD-Crypto-Spec/Responsible-Disclosure), subject to the deviations described in the deviations [section](#deviations-from-the-standard) of this document.

## Bilateral Responsible Disclosure Agreements

_Pickle Finance does not currently have any established bilateral disclosure agreements._

## Bug Bounty Program

Pickle Finance has a Bug Bounty program to encourage security researchers to spend time studying the protocol in order to uncover vulnerabilities. We believe these researchers should get fairly compensated for their time and effort, and acknowledged for their valuable contributions.

### Rules

1. Bug has not been publicly disclosed.
2. Vulnerabilities that have been previously submitted by another contributor or already known by the Pickle Finance development team are not eligible for rewards.
3. The size of the bounty payout depends on the assessment of the severity of the exploit. Please refer to the rewards [section](#rewards) below for additional details.
4. Bugs must be reproducible in order for us to verify the vulnerability.
5. Rewards and the validity of bugs are determined by the Pickle Finance security team and any payouts are made at their sole discretion.
6. Terms and conditions of the Bug Bounty program can be changed at any time at the discretion of Pickle Finance.
7. Details of any valid bugs may be shared with complementary protocols utilized in the Pickle Finance ecosystem in order to promote ecosystem cohesion and safety.

### Classifications

-   **Severe:** Highly likely to have a material impact on availability, integrity, and/or loss of funds.
-   **High:** Likely to have impact on availability, integrity, and/or loss of funds.
-   **Medium:** Possible to have an impact on availability, integrity, and/or loss of funds.
-   **Low:** Unlikely to have a meaningful impact on availability, integrity, and/or loss of funds.

### Rewards

-   **Severe:** 20,000-50,000 USDC
-   **High:** 5,000-20,000 USDC
-   **Medium:** 1,000-5,000 USDC
-   **Low:** 100-1,000 USDC

Actual payouts are determined by classifying the vulnerability based on its impact and likelihood to be exploited successfully, as well as the process working with the disclosing security researcher. The rewards represent the _maximum_ that will be paid out for a disclosure.

Rewards are paid out in [USDC](https://etherscan.io/token/0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48).

### Scope

The scope of the Bug Bounty program spans smart contracts utilized in the Pickle Finance ecosystem – the Solidity smart contracts in the `src` folder of the `master` branch of the protocol [repo](https://github.com/pickle-finance/protocol), including historical deployments that still see active use on Ethereum Mainnet associated with Pickle Finance, and excluding any contracts used in a test-only capacity (including test-only deployments).

Note: Other contracts, outside of the ones mentioned above, might be considered on a case by case basis, please, reach out to the Pickle Finance development team for clarification.

### Bug Bounty FAQ

**Q:** Is there a time limit for the Bug Bounty program?\
**A:** No. The Bug Bounty program currently has no end date, but this can be changed at any time at the discretion of Pickle Finance.

**Q:** How big is the Bug Bounty program?\
**A:** There is currently a rolling \$100,000 bounty for bugs. This amount may be changed by a Pickle Finance governance vote.

**Q:** How are bounties paid out?\
**A:** Rewards are paid out in USDC.

**Q:** Can I submit bugs anonymously and still receive payment?\
**A:** Yes. If you wish to remain anonymous you can do so and still be eligible for rewards as long as they are for valid bugs. Rewards will be sent to the valid Ethereum address that you provide.

**Q:** Can I donate my reward to charity?\
**A:** Yes. You may donate your reward to a charity of your choosing, or to a gitcoin grant.

## Deviations from the Standard

The standard describes reporters of vulnerabilities including full details of an issue, in order to reproduce it. This is necessary for instance in the case of an external researcher both demonstrating and proving that there really is a security issue, and that security issue really has the impact that they say it
has - allowing the development team to accurately prioritize and resolve the issue.

In the case of a counterfeiting or fund-stealing bug affecting Pickle Finance, however, we might decide not to include those details with our reports to partners ahead of coordinated release, as long as we are sure that they are not vulnerable.

## Credits

Parts of this document were inspired by [Yearn's security policy](https://github.com/iearn-finance/yearn-protocol/blob/develop/SECURITY.md).
