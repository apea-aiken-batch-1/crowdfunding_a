use aiken/crypto.{VerificationKeyHash}
use cardano/assets.{Lovelace}

pub type PaymentKeyHash =
  VerificationKeyHash

pub type StakeKeyHash =
  VerificationKeyHash

pub type Address {
  pkh: PaymentKeyHash,
  skh: StakeKeyHash,
}

pub type Backer =
  Pair<Address, Lovelace>

pub type Backers =
  List<Backer>

/// Datum
pub type CampaignDatum {
  title: ByteArray,
  goal: Lovelace,
  deadline: Int,
  creator: Address,
  backers: Backers,
}

/// Redeemer
pub type RedeemerAction {
  PledgeCampaign
  FinishCampaign
  CancelCampaign
}
