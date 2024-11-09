use aiken/builtin
use aiken/collection/list
use aiken/collection/pairs
use aiken/crypto.{VerificationKeyHash}
use aiken/interval
use aiken/primitive/bytearray
use cardano/address.{Inline, VerificationKey}
use cardano/assets.{Lovelace}
use cardano/transaction.{
  InlineDatum, Input, Output, OutputReference, Transaction,
}
use crowdfunding/types.{
  Address, Backer, Backers, CampaignDatum, CancelCampaign, FinishCampaign,
  PaymentKeyHash, PledgeCampaign, RedeemerAction, StakeKeyHash,
}
use crowdfunding/utils

pub fn validate_spend_campaign(
  campaign: CampaignDatum,
  action: RedeemerAction,
  o_ref: OutputReference,
  tx: Transaction,
) -> Bool {
  when action is {
    PledgeCampaign -> campaign |> validate_pledge_campaign(o_ref, tx)
    FinishCampaign -> campaign |> validate_finish_campaign(o_ref, tx)
    CancelCampaign -> campaign |> validate_cancel_campaign(o_ref, tx)
  }
}

// ## Validation Functions

fn validate_pledge_campaign(
  CampaignDatum { title, goal, deadline, creator, backers }: CampaignDatum,
  o_ref: OutputReference,
  Transaction { inputs, outputs, extra_signatories, validity_range, .. }: Transaction,
) -> Bool {
  // Extract backer's signatory
  expect [backer_pkh]: List<PaymentKeyHash> = extra_signatories

  // Extract backer's address
  expect Some(Input { output: Output { address: backer_address, .. }, .. }) = {
    let input <- list.find(inputs)
    when input.output.address.payment_credential is {
      VerificationKey(verification_key_hash) ->
        verification_key_hash == backer_pkh
      _ -> False
    }
  }
  let backer_skh: StakeKeyHash =
    when backer_address.stake_credential is {
      Some(Inline(credential)) -> utils.credential_to_hash(credential)
      _ -> ""
    }

  expect Some(Input { output: campaign_utxo, .. }) =
    inputs |> transaction.find_input(o_ref)
  let get_input_lovelace =
    fn() { assets.lovelace_of(campaign_utxo.value) }

  let sort_input_backers =
    fn() { backers |> sort_backers }

  // Must NOT pledge to self campaign
  expect backer_pkh != creator.pkh

  // Must pledge before deadline
  expect validity_range |> interval.is_entirely_before(deadline)

  // Must only have 1 output to the Crowdfunding address
  expect 1 = {
    let Output { address, .. } <- list.count(outputs)
    address == campaign_utxo.address
  }

  // Must resend datum
  let must_resend_datum: Bool = {
    let Output { address, value, datum, .. } <- list.any(outputs)
    when datum is {
      InlineDatum(campaign) ->
        if campaign
        is CampaignDatum {
          title: output_title,
          goal: output_goal,
          deadline: output_deadline,
          creator: output_creator,
          backers: output_backers,
        }: CampaignDatum {
          let get_output_lovelace =
            fn() { assets.lovelace_of(value) }
          let get_pledge_amount =
            fn() { get_output_lovelace() - get_input_lovelace() }

          let sort_output_backers =
            fn() { output_backers |> sort_backers }

          and {
            address == campaign_utxo.address,
            output_title == title,
            output_goal == goal,
            output_deadline == deadline,
            output_creator == creator,
            get_output_lovelace() > get_input_lovelace(),
            sort_output_backers() == pairs.insert_with_by_ascending_key(
              sort_input_backers(),
              key: Address(backer_pkh, backer_skh),
              value: get_pledge_amount(),
              compare: utils.compare_address,
              with: builtin.add_integer,
            ),
          }
        } else {
          // campaign is NOT a CampaignDatum:
          False
        }
      // datum is NOT an InlineDatum:
      _ -> False
    }
  }
  must_resend_datum?
}

fn validate_finish_campaign(
  CampaignDatum { creator, goal, .. }: CampaignDatum,
  o_ref: OutputReference,
  Transaction { extra_signatories, inputs, .. }: Transaction,
) -> Bool {
  and {
    must_be_signed_by(extra_signatories, signer: creator.pkh)?,
    must_reach_goal(inputs, o_ref, goal)?,
  }
}

fn validate_cancel_campaign(
  CampaignDatum { creator, backers, .. }: CampaignDatum,
  _o_ref: OutputReference,
  Transaction { extra_signatories, outputs, .. }: Transaction,
) -> Bool {
  and {
    must_be_signed_by(extra_signatories, signer: creator.pkh)?,
    must_refund_all(outputs, backers)?,
  }
}

// ## Helper Functions

fn must_be_signed_by(
  signatories: List<VerificationKeyHash>,
  signer: VerificationKeyHash,
) -> Bool {
  signatories |> list.has(signer)
}

fn must_refund_all(
  transaction_outputs: List<Output>,
  refund_to: Backers,
) -> Bool {
  let Pair(backer_address, backer_lovelace) <- list.all(refund_to)
  let Output { address, value, .. } <- list.any(transaction_outputs)
  and {
    utils.credential_to_hash(address.payment_credential) == backer_address.pkh,
    assets.lovelace_of(value) == backer_lovelace,
  }
}

fn must_reach_goal(
  transaction_inputs: List<Input>,
  o_ref: OutputReference,
  goal: Lovelace,
) -> Bool {
  expect Some(Input { output: Output { datum, .. }, .. }) =
    transaction_inputs |> transaction.find_input(o_ref)
  expect InlineDatum(campaign) = datum
  expect CampaignDatum { backers, .. } = campaign
  list.reduce(backers, 0, fn(sum, Pair(_, lovelace)) { sum + lovelace }) >= goal
}

// ## Utility Functions

fn sort_backers(backers: Backers) -> Backers {
  list.sort(
    backers,
    fn(Pair(left_address, _l): Backer, Pair(right_address, _r): Backer) {
      bytearray.compare(left_address.pkh, right_address.pkh)
    },
  )
}
