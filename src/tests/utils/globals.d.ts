declare module Chai {
  interface Assertion {
    eqApprox(property: BigNumber): void;
  }
}
