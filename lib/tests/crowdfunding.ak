use aiken/builtin
use aiken/collection/pairs
use aiken/crypto.{VerificationKeyHash}
use aiken/interval
use cardano/address
use cardano/assets.{Lovelace}
use cardano/transaction.{
  InlineDatum, Input, NoDatum, Output, OutputReference, Transaction,
}
use crowdfunding
use crowdfunding/types.{
  Address, CampaignDatum, CancelCampaign, FinishCampaign, PledgeCampaign,
}
use crowdfunding/utils

const crowdfunding_address =
  address.from_script(
    #"7fa319dbc885fe6846fa7e648dbbcc9b2cfb9995d3fb0dd1a0d38538",
  )

const min_lovelace = 2_000_000

const creator_1 =
  Address {
    pkh: #"c1a00000000000000000000000000000000000000000000000000056",
    skh: #"c1b00000000000000000000000000000000000000000000000000056",
  }

const creator_2 =
  Address {
    pkh: #"c2a00000000000000000000000000000000000000000000000000056",
    skh: #"c2b00000000000000000000000000000000000000000000000000056",
  }

const backer_1_pkh: VerificationKeyHash =
  #"b1a00000000000000000000000000000000000000000000000000056"

const backer_1_skh: VerificationKeyHash =
  #"b1b00000000000000000000000000000000000000000000000000056"

const backer_1: Pair<Address, Lovelace> =
  Pair(Address(backer_1_pkh, backer_1_skh), 100_000_000)

const backer_2_pkh: VerificationKeyHash =
  #"b2a00000000000000000000000000000000000000000000000000056"

const backer_2_skh: VerificationKeyHash =
  #"b2b00000000000000000000000000000000000000000000000000056"

const backer_2: Pair<Address, Lovelace> =
  Pair(Address(backer_2_pkh, backer_2_skh), 20_000_000)

const backer_3_pkh: VerificationKeyHash =
  #"b3a00000000000000000000000000000000000000000000000000056"

const backer_3_skh: VerificationKeyHash =
  #"b3b00000000000000000000000000000000000000000000000000056"

const backer_3: Pair<Address, Lovelace> =
  Pair(Address(backer_3_pkh, backer_3_skh), 3_000_000)

const now = 1581471270000

const campaign_1 =
  CampaignDatum {
    title: "Campaign 1",
    goal: 9_000_000_000,
    deadline: 1928374650000,
    creator: creator_1,
    backers: [],
  }

// ## PledgeCampaign
// ### PledgeCampaign positive cases

test validate_pledge_campaign_positive_1() {
  trace @"Positive: Initial pledge"

  let Pair(backer_1_address, backer_1_pledge) = backer_1

  let campaign_o_ref =
    OutputReference {
      transaction_id: #"01010000000000000000000000000000000000000000000000000056",
      output_index: 0,
    }

  let tx_input_from_script =
    Input(
      campaign_o_ref,
      Output {
        address: crowdfunding_address,
        value: assets.from_lovelace(min_lovelace),
        datum: InlineDatum(campaign_1),
        reference_script: None,
      },
    )

  let tx_input_from_backer =
    Input(
      OutputReference {
        transaction_id: #"b1010000000000000000000000000000000000000000000000000056",
        output_index: 0,
      },
      Output {
        address: backer_1_address.pkh
          |> address.from_verification_key
          |> address.with_delegation_key(backer_1_address.skh),
        value: assets.from_lovelace(backer_1_pledge),
        datum: NoDatum,
        reference_script: None,
      },
    )

  let tx_output_to_script =
    Output {
      address: crowdfunding_address,
      value: assets.from_lovelace(min_lovelace + backer_1_pledge),
      datum: InlineDatum(
        CampaignDatum {
          ..campaign_1,
          backers: [backer_1, ..campaign_1.backers],
        },
      ),
      reference_script: None,
    }

  campaign_1
    |> crowdfunding.validate_spend_campaign(
        PledgeCampaign,
        campaign_o_ref,
        Transaction {
          ..transaction.placeholder,
          inputs: [tx_input_from_script, tx_input_from_backer],
          outputs: [tx_output_to_script],
          validity_range: interval.between(now, now + 3_600_000),
          extra_signatories: [backer_1_pkh],
        },
      )
}

test validate_pledge_campaign_positive_2() {
  trace @"Positive: Pledge an existing campaign"

  let Pair(backer_2_address, backer_2_pledge) = backer_2
  let Pair(_, backer_1_pledge) = backer_1

  let campaign_o_ref =
    OutputReference {
      transaction_id: #"01020000000000000000000000000000000000000000000000000056",
      output_index: 0,
    }

  let campaign_datum =
    CampaignDatum { ..campaign_1, backers: [backer_1, ..campaign_1.backers] }

  let tx_input_from_script =
    Input(
      campaign_o_ref,
      Output {
        address: crowdfunding_address,
        value: assets.from_lovelace(min_lovelace + backer_1_pledge),
        datum: InlineDatum(campaign_datum),
        reference_script: None,
      },
    )

  let tx_input_from_backer =
    Input(
      OutputReference {
        transaction_id: #"b2010000000000000000000000000000000000000000000000000056",
        output_index: 0,
      },
      Output {
        address: backer_2_address.pkh
          |> address.from_verification_key
          |> address.with_delegation_script(backer_2_address.skh),
        value: assets.from_lovelace(backer_2_pledge),
        datum: NoDatum,
        reference_script: None,
      },
    )

  let tx_output_to_script =
    Output {
      address: crowdfunding_address,
      value: assets.from_lovelace(
        min_lovelace + backer_1_pledge + backer_2_pledge,
      ),
      datum: InlineDatum(
        CampaignDatum {
          ..campaign_datum,
          backers: [backer_2, ..campaign_datum.backers],
        },
      ),
      reference_script: None,
    }

  campaign_datum
    |> crowdfunding.validate_spend_campaign(
        PledgeCampaign,
        campaign_o_ref,
        Transaction {
          ..transaction.placeholder,
          inputs: [tx_input_from_script, tx_input_from_backer],
          outputs: [tx_output_to_script],
          validity_range: interval.between(now + 3_600_000, now + 3_600_000 * 2),
          extra_signatories: [backer_2_pkh],
        },
      )
}

test validate_pledge_campaign_positive_3() {
  trace @"Positive: Pledge an existing campaign consisted of 2 backers already"

  let Pair(backer_3_address, backer_3_pledge) = backer_3
  let Pair(_, backer_1_pledge) = backer_1
  let Pair(_, backer_2_pledge) = backer_2

  let campaign_o_ref =
    OutputReference {
      transaction_id: #"01030000000000000000000000000000000000000000000000000056",
      output_index: 0,
    }

  let campaign_datum =
    CampaignDatum {
      ..campaign_1,
      backers: [backer_1, backer_2, ..campaign_1.backers],
    }

  let tx_input_from_script =
    Input(
      campaign_o_ref,
      Output {
        address: crowdfunding_address,
        value: assets.from_lovelace(
          min_lovelace + backer_1_pledge + backer_2_pledge,
        ),
        datum: InlineDatum(campaign_datum),
        reference_script: None,
      },
    )

  let tx_input_from_backer =
    Input(
      OutputReference {
        transaction_id: #"b3010000000000000000000000000000000000000000000000000056",
        output_index: 0,
      },
      Output {
        address: backer_3_address.pkh
          |> address.from_verification_key
          |> address.with_delegation_key(backer_3_address.skh),
        value: assets.from_lovelace(backer_3_pledge),
        datum: NoDatum,
        reference_script: None,
      },
    )

  let tx_output_to_script =
    Output {
      address: crowdfunding_address,
      value: assets.from_lovelace(
        min_lovelace + backer_1_pledge + backer_2_pledge + backer_3_pledge,
      ),
      datum: InlineDatum(
        CampaignDatum {
          ..campaign_datum,
          backers: [backer_3, ..campaign_datum.backers],
        },
      ),
      reference_script: None,
    }

  campaign_datum
    |> crowdfunding.validate_spend_campaign(
        PledgeCampaign,
        campaign_o_ref,
        Transaction {
          ..transaction.placeholder,
          inputs: [tx_input_from_script, tx_input_from_backer],
          outputs: [tx_output_to_script],
          validity_range: interval.between(
            now + 3_600_000 * 2,
            now + 3_600_000 * 3,
          ),
          extra_signatories: [backer_3_pkh],
        },
      )
}

// ### PledgeCampaign negative cases

test validate_pledge_campaign_negative_1() fail {
  let Pair(backer_1_address, backer_1_pledge) = backer_1

  let campaign_o_ref =
    OutputReference {
      transaction_id: #"01010000000000000000000000000000000000000000000000000056",
      output_index: 0,
    }

  let tx_input_from_script =
    Input(
      campaign_o_ref,
      Output {
        address: crowdfunding_address,
        value: assets.from_lovelace(min_lovelace),
        datum: InlineDatum(campaign_1),
        reference_script: None,
      },
    )

  let tx_input_from_backer =
    Input(
      OutputReference {
        transaction_id: #"b1010000000000000000000000000000000000000000000000000056",
        output_index: 0,
      },
      Output {
        address: backer_1_address.pkh
          |> address.from_verification_key
          |> address.with_delegation_key(backer_1_address.skh),
        value: assets.from_lovelace(backer_1_pledge),
        datum: NoDatum,
        reference_script: None,
      },
    )

  trace @"Negative: Modify Campaign Title"
  let tx_output_to_script =
    Output {
      address: crowdfunding_address,
      value: assets.from_lovelace(min_lovelace + backer_1_pledge),
      datum: InlineDatum(
        CampaignDatum {
          ..campaign_1,
          title: "Campaign 2",
          backers: [backer_1, ..campaign_1.backers],
        },
      ),
      reference_script: None,
    }

  campaign_1
    |> crowdfunding.validate_spend_campaign(
        PledgeCampaign,
        campaign_o_ref,
        Transaction {
          ..transaction.placeholder,
          inputs: [tx_input_from_script, tx_input_from_backer],
          outputs: [tx_output_to_script],
          validity_range: interval.between(now, now + 3_600_000),
          extra_signatories: [backer_1_pkh],
        },
      )
}

test validate_pledge_campaign_negative_2() fail {
  let Pair(backer_2_address, backer_2_pledge) = backer_2
  let Pair(_, backer_1_pledge) = backer_1

  let campaign_o_ref =
    OutputReference {
      transaction_id: #"01020000000000000000000000000000000000000000000000000056",
      output_index: 0,
    }

  let campaign_datum =
    CampaignDatum { ..campaign_1, backers: [backer_1, ..campaign_1.backers] }

  let tx_input_from_script =
    Input(
      campaign_o_ref,
      Output {
        address: crowdfunding_address,
        value: assets.from_lovelace(min_lovelace + backer_1_pledge),
        datum: InlineDatum(campaign_datum),
        reference_script: None,
      },
    )

  let tx_input_from_backer =
    Input(
      OutputReference {
        transaction_id: #"b2010000000000000000000000000000000000000000000000000056",
        output_index: 0,
      },
      Output {
        address: backer_2_address.pkh
          |> address.from_verification_key
          |> address.with_delegation_script(backer_2_address.skh),
        value: assets.from_lovelace(backer_2_pledge),
        datum: NoDatum,
        reference_script: None,
      },
    )

  trace @"Negative: Modify Campaign Goal"
  let tx_output_to_script =
    Output {
      address: crowdfunding_address,
      value: assets.from_lovelace(
        min_lovelace + backer_1_pledge + backer_2_pledge,
      ),
      datum: InlineDatum(
        CampaignDatum {
          ..campaign_datum,
          goal: 3_000_000,
          backers: [backer_2, ..campaign_datum.backers],
        },
      ),
      reference_script: None,
    }

  campaign_datum
    |> crowdfunding.validate_spend_campaign(
        PledgeCampaign,
        campaign_o_ref,
        Transaction {
          ..transaction.placeholder,
          inputs: [tx_input_from_script, tx_input_from_backer],
          outputs: [tx_output_to_script],
          validity_range: interval.between(now + 3_600_000, now + 3_600_000 * 2),
          extra_signatories: [backer_2_pkh],
        },
      )
}

test validate_pledge_campaign_negative_3() fail {
  let Pair(backer_3_address, backer_3_pledge) = backer_3
  let Pair(_, backer_1_pledge) = backer_1
  let Pair(_, backer_2_pledge) = backer_2

  let campaign_o_ref =
    OutputReference {
      transaction_id: #"01030000000000000000000000000000000000000000000000000056",
      output_index: 0,
    }

  let campaign_datum =
    CampaignDatum {
      ..campaign_1,
      backers: [backer_1, backer_2, ..campaign_1.backers],
    }

  let tx_input_from_script =
    Input(
      campaign_o_ref,
      Output {
        address: crowdfunding_address,
        value: assets.from_lovelace(
          min_lovelace + backer_1_pledge + backer_2_pledge,
        ),
        datum: InlineDatum(campaign_datum),
        reference_script: None,
      },
    )

  let tx_input_from_backer =
    Input(
      OutputReference {
        transaction_id: #"b3010000000000000000000000000000000000000000000000000056",
        output_index: 0,
      },
      Output {
        address: backer_3_address.pkh
          |> address.from_verification_key
          |> address.with_delegation_key(backer_3_address.skh),
        value: assets.from_lovelace(backer_3_pledge),
        datum: NoDatum,
        reference_script: None,
      },
    )

  trace @"Negative: Modify Campaign Deadline"
  let tx_output_to_script =
    Output {
      address: crowdfunding_address,
      value: assets.from_lovelace(
        min_lovelace + backer_1_pledge + backer_2_pledge + backer_3_pledge,
      ),
      datum: InlineDatum(
        CampaignDatum {
          ..campaign_datum,
          deadline: 1234567890000,
          backers: [backer_3, ..campaign_datum.backers],
        },
      ),
      reference_script: None,
    }

  campaign_datum
    |> crowdfunding.validate_spend_campaign(
        PledgeCampaign,
        campaign_o_ref,
        Transaction {
          ..transaction.placeholder,
          inputs: [tx_input_from_script, tx_input_from_backer],
          outputs: [tx_output_to_script],
          validity_range: interval.between(
            now + 3_600_000 * 2,
            now + 3_600_000 * 3,
          ),
          extra_signatories: [backer_3_pkh],
        },
      )
}

test validate_pledge_campaign_negative_4() fail {
  let Pair(backer_1_address, backer_1_pledge) = backer_1

  let campaign_o_ref =
    OutputReference {
      transaction_id: #"01010000000000000000000000000000000000000000000000000056",
      output_index: 0,
    }

  let tx_input_from_script =
    Input(
      campaign_o_ref,
      Output {
        address: crowdfunding_address,
        value: assets.from_lovelace(min_lovelace),
        datum: InlineDatum(campaign_1),
        reference_script: None,
      },
    )

  let tx_input_from_backer =
    Input(
      OutputReference {
        transaction_id: #"b1010000000000000000000000000000000000000000000000000056",
        output_index: 0,
      },
      Output {
        address: backer_1_address.pkh
          |> address.from_verification_key
          |> address.with_delegation_key(backer_1_address.skh),
        value: assets.from_lovelace(backer_1_pledge),
        datum: NoDatum,
        reference_script: None,
      },
    )

  trace @"Negative: Modify Campaign Creator"
  let tx_output_to_script =
    Output {
      address: crowdfunding_address,
      value: assets.from_lovelace(min_lovelace + backer_1_pledge),
      datum: InlineDatum(
        CampaignDatum {
          ..campaign_1,
          creator: creator_2,
          backers: [backer_1, ..campaign_1.backers],
        },
      ),
      reference_script: None,
    }

  campaign_1
    |> crowdfunding.validate_spend_campaign(
        PledgeCampaign,
        campaign_o_ref,
        Transaction {
          ..transaction.placeholder,
          inputs: [tx_input_from_script, tx_input_from_backer],
          outputs: [tx_output_to_script],
          validity_range: interval.between(now, now + 3_600_000),
          extra_signatories: [backer_1_pkh],
        },
      )
}

test validate_pledge_campaign_negative_5() fail {
  let Pair(backer_2_address, backer_2_pledge) = backer_2
  let Pair(_, backer_1_pledge) = backer_1

  let campaign_o_ref =
    OutputReference {
      transaction_id: #"01020000000000000000000000000000000000000000000000000056",
      output_index: 0,
    }

  let campaign_datum =
    CampaignDatum { ..campaign_1, backers: [backer_1, ..campaign_1.backers] }

  let tx_input_from_script =
    Input(
      campaign_o_ref,
      Output {
        address: crowdfunding_address,
        value: assets.from_lovelace(min_lovelace + backer_1_pledge),
        datum: InlineDatum(campaign_datum),
        reference_script: None,
      },
    )

  let tx_input_from_backer =
    Input(
      OutputReference {
        transaction_id: #"b2010000000000000000000000000000000000000000000000000056",
        output_index: 0,
      },
      Output {
        address: backer_2_address.pkh
          |> address.from_verification_key
          |> address.with_delegation_script(backer_2_address.skh),
        value: assets.from_lovelace(backer_2_pledge),
        datum: NoDatum,
        reference_script: None,
      },
    )

  trace @"Negative: Claiming other's pledge to self"
  let tx_output_to_script =
    Output {
      address: crowdfunding_address,
      value: assets.from_lovelace(
        min_lovelace + backer_1_pledge + backer_2_pledge,
      ),
      datum: InlineDatum(
        CampaignDatum {
          ..campaign_datum,
          backers: []
            |> pairs.insert_with_by_ascending_key(
                key: backer_2_address,
                value: backer_2_pledge,
                compare: utils.compare_address,
                with: builtin.add_integer,
              )
            |> pairs.insert_with_by_ascending_key(
                key: backer_2_address,
                value: backer_1_pledge,
                compare: utils.compare_address,
                with: builtin.add_integer,
              ),
        },
      ),
      reference_script: None,
    }

  campaign_datum
    |> crowdfunding.validate_spend_campaign(
        PledgeCampaign,
        campaign_o_ref,
        Transaction {
          ..transaction.placeholder,
          inputs: [tx_input_from_script, tx_input_from_backer],
          outputs: [tx_output_to_script],
          validity_range: interval.between(now + 3_600_000, now + 3_600_000 * 2),
          extra_signatories: [backer_2_pkh],
        },
      )
}

test validate_pledge_campaign_negative_6() fail {
  let Pair(backer_3_address, backer_3_pledge) = backer_3
  let Pair(_, backer_1_pledge) = backer_1
  let Pair(_, backer_2_pledge) = backer_2

  let campaign_o_ref =
    OutputReference {
      transaction_id: #"01030000000000000000000000000000000000000000000000000056",
      output_index: 0,
    }

  let campaign_datum =
    CampaignDatum {
      ..campaign_1,
      backers: [backer_1, backer_2, ..campaign_1.backers],
    }

  let tx_input_from_script =
    Input(
      campaign_o_ref,
      Output {
        address: crowdfunding_address,
        value: assets.from_lovelace(
          min_lovelace + backer_1_pledge + backer_2_pledge,
        ),
        datum: InlineDatum(campaign_datum),
        reference_script: None,
      },
    )

  let tx_input_from_backer =
    Input(
      OutputReference {
        transaction_id: #"b3010000000000000000000000000000000000000000000000000056",
        output_index: 0,
      },
      Output {
        address: backer_3_address.pkh
          |> address.from_verification_key
          |> address.with_delegation_key(backer_3_address.skh),
        value: assets.from_lovelace(backer_3_pledge),
        datum: NoDatum,
        reference_script: None,
      },
    )

  let tx_output_to_script =
    Output {
      address: crowdfunding_address,
      value: assets.from_lovelace(min_lovelace),
      datum: InlineDatum(
        CampaignDatum {
          ..campaign_datum,
          backers: [backer_3, ..campaign_datum.backers],
        },
      ),
      reference_script: None,
    }

  trace @"Negative: Paying pledges to self address instead of the Crowdfunding address"
  let tx_output_to_backer =
    Output {
      address: backer_3_address.pkh
        |> address.from_verification_key
        |> address.with_delegation_key(backer_3_address.skh),
      value: assets.from_lovelace(
        backer_1_pledge + backer_2_pledge + backer_3_pledge,
      ),
      datum: NoDatum,
      reference_script: None,
    }

  campaign_datum
    |> crowdfunding.validate_spend_campaign(
        PledgeCampaign,
        campaign_o_ref,
        Transaction {
          ..transaction.placeholder,
          inputs: [tx_input_from_script, tx_input_from_backer],
          outputs: [tx_output_to_script, tx_output_to_backer],
          validity_range: interval.between(
            now + 3_600_000 * 2,
            now + 3_600_000 * 3,
          ),
          extra_signatories: [backer_3_pkh],
        },
      )
}

test validate_pledge_campaign_negative_7() fail {
  trace @"Negative: Pledge to self campaign"
  let Address { pkh: backer_1_pkh, skh: backer_1_skh } = creator_1
  let backer_1_address =
    backer_1_pkh
      |> address.from_verification_key
      |> address.with_delegation_key(backer_1_skh)
  let Pair(_, backer_1_pledge) = backer_1

  let campaign_o_ref =
    OutputReference {
      transaction_id: #"01010000000000000000000000000000000000000000000000000056",
      output_index: 0,
    }

  let tx_input_from_script =
    Input(
      campaign_o_ref,
      Output {
        address: crowdfunding_address,
        value: assets.from_lovelace(min_lovelace),
        datum: InlineDatum(campaign_1),
        reference_script: None,
      },
    )

  let tx_input_from_backer =
    Input(
      OutputReference {
        transaction_id: #"b1010000000000000000000000000000000000000000000000000056",
        output_index: 0,
      },
      Output {
        address: backer_1_address,
        value: assets.from_lovelace(backer_1_pledge),
        datum: NoDatum,
        reference_script: None,
      },
    )

  let tx_output_to_script =
    Output {
      address: crowdfunding_address,
      value: assets.from_lovelace(min_lovelace + backer_1_pledge),
      datum: InlineDatum(
        CampaignDatum {
          ..campaign_1,
          backers: [backer_1, ..campaign_1.backers],
        },
      ),
      reference_script: None,
    }

  campaign_1
    |> crowdfunding.validate_spend_campaign(
        PledgeCampaign,
        campaign_o_ref,
        Transaction {
          ..transaction.placeholder,
          inputs: [tx_input_from_script, tx_input_from_backer],
          outputs: [tx_output_to_script],
          validity_range: interval.between(now, now + 3_600_000),
          extra_signatories: [backer_1_pkh],
        },
      )
}

test validate_pledge_campaign_negative_8() fail {
  let Pair(backer_2_address, backer_2_pledge) = backer_2
  let Pair(_, backer_1_pledge) = backer_1

  let campaign_o_ref =
    OutputReference {
      transaction_id: #"01020000000000000000000000000000000000000000000000000056",
      output_index: 0,
    }

  let campaign_datum =
    CampaignDatum { ..campaign_1, backers: [backer_1, ..campaign_1.backers] }

  let tx_input_from_script =
    Input(
      campaign_o_ref,
      Output {
        address: crowdfunding_address,
        value: assets.from_lovelace(min_lovelace + backer_1_pledge),
        datum: InlineDatum(campaign_datum),
        reference_script: None,
      },
    )

  let tx_input_from_backer =
    Input(
      OutputReference {
        transaction_id: #"b2010000000000000000000000000000000000000000000000000056",
        output_index: 0,
      },
      Output {
        address: backer_2_address.pkh
          |> address.from_verification_key
          |> address.with_delegation_script(backer_2_address.skh),
        value: assets.from_lovelace(backer_2_pledge),
        datum: NoDatum,
        reference_script: None,
      },
    )

  let tx_output_to_script =
    Output {
      address: crowdfunding_address,
      value: assets.from_lovelace(
        min_lovelace + backer_1_pledge + backer_2_pledge,
      ),
      datum: InlineDatum(
        CampaignDatum {
          ..campaign_datum,
          backers: [backer_2, ..campaign_datum.backers],
        },
      ),
      reference_script: None,
    }

  trace @"Negative: Pledge after deadline"
  let now = campaign_datum.deadline
  campaign_datum
    |> crowdfunding.validate_spend_campaign(
        PledgeCampaign,
        campaign_o_ref,
        Transaction {
          ..transaction.placeholder,
          inputs: [tx_input_from_script, tx_input_from_backer],
          outputs: [tx_output_to_script],
          validity_range: interval.between(now + 3_600_000, now + 3_600_000 * 2),
          extra_signatories: [backer_2_pkh],
        },
      )
}

test validate_pledge_campaign_negative_9() fail {
  let Pair(backer_3_address, backer_3_pledge) = backer_3
  let Pair(_, backer_1_pledge) = backer_1
  let Pair(_, backer_2_pledge) = backer_2

  let campaign_o_ref =
    OutputReference {
      transaction_id: #"01030000000000000000000000000000000000000000000000000056",
      output_index: 0,
    }

  let campaign_datum =
    CampaignDatum {
      ..campaign_1,
      backers: [backer_1, backer_2, ..campaign_1.backers],
    }

  let tx_input_from_script =
    Input(
      campaign_o_ref,
      Output {
        address: crowdfunding_address,
        value: assets.from_lovelace(
          min_lovelace + backer_1_pledge + backer_2_pledge,
        ),
        datum: InlineDatum(campaign_datum),
        reference_script: None,
      },
    )

  let tx_input_from_backer =
    Input(
      OutputReference {
        transaction_id: #"b3010000000000000000000000000000000000000000000000000056",
        output_index: 0,
      },
      Output {
        address: backer_3_address.pkh
          |> address.from_verification_key
          |> address.with_delegation_key(backer_3_address.skh),
        value: assets.from_lovelace(backer_3_pledge),
        datum: NoDatum,
        reference_script: None,
      },
    )

  trace @"Negative: Split outputs sent to the Crowdfunding address"

  let tx_output_to_script_1 =
    Output {
      address: crowdfunding_address,
      value: assets.from_lovelace(
        min_lovelace + backer_1_pledge + backer_2_pledge,
      ),
      datum: InlineDatum(campaign_datum),
      reference_script: None,
    }

  let tx_output_to_script_2 =
    Output {
      address: crowdfunding_address,
      value: assets.from_lovelace(backer_3_pledge),
      datum: InlineDatum(
        CampaignDatum { ..campaign_datum, backers: [backer_3] },
      ),
      reference_script: None,
    }

  campaign_datum
    |> crowdfunding.validate_spend_campaign(
        PledgeCampaign,
        campaign_o_ref,
        Transaction {
          ..transaction.placeholder,
          inputs: [tx_input_from_script, tx_input_from_backer],
          outputs: [tx_output_to_script_1, tx_output_to_script_2],
          validity_range: interval.between(
            now + 3_600_000 * 2,
            now + 3_600_000 * 3,
          ),
          extra_signatories: [backer_3_pkh],
        },
      )
}

// ## FinishCampaign
// ### FinishCampaign positive case

test validate_finish_campaign_positive_1() {
  trace @"Positive: Reached goal"

  let backer_pledge = campaign_1.goal
  let backer = Pair(Address(backer_1_pkh, backer_1_skh), backer_pledge)

  let campaign_datum =
    CampaignDatum { ..campaign_1, backers: [backer, ..campaign_1.backers] }

  let campaign_o_ref =
    OutputReference {
      transaction_id: #"01010000000000000000000000000000000000000000000000000056",
      output_index: 0,
    }

  let tx_input_from_script =
    Input(
      campaign_o_ref,
      Output {
        address: crowdfunding_address,
        value: assets.from_lovelace(min_lovelace + backer_pledge),
        datum: InlineDatum(campaign_datum),
        reference_script: None,
      },
    )

  let tx_output_to_creator =
    Output {
      address: campaign_1.creator.pkh
        |> address.from_verification_key
        |> address.with_delegation_key(campaign_1.creator.skh),
      value: assets.from_lovelace(min_lovelace + backer_pledge),
      datum: NoDatum,
      reference_script: None,
    }

  campaign_datum
    |> crowdfunding.validate_spend_campaign(
        FinishCampaign,
        campaign_o_ref,
        Transaction {
          ..transaction.placeholder,
          inputs: [tx_input_from_script],
          outputs: [tx_output_to_creator],
          extra_signatories: [campaign_1.creator.pkh],
        },
      )
}

// ### FinishCampaign negative cases

test validate_finish_campaign_negative_1() fail {
  let backer_pledge = campaign_1.goal
  let backer = Pair(Address(backer_1_pkh, backer_1_skh), backer_pledge)

  let campaign_datum =
    CampaignDatum { ..campaign_1, backers: [backer, ..campaign_1.backers] }

  let campaign_o_ref =
    OutputReference {
      transaction_id: #"01010000000000000000000000000000000000000000000000000056",
      output_index: 0,
    }

  let tx_input_from_script =
    Input(
      campaign_o_ref,
      Output {
        address: crowdfunding_address,
        value: assets.from_lovelace(min_lovelace + backer_pledge),
        datum: InlineDatum(campaign_datum),
        reference_script: None,
      },
    )

  trace @"Negative: Signed by another creator"
  let tx_output_to_a_different_creator =
    Output {
      address: creator_2.pkh
        |> address.from_verification_key
        |> address.with_delegation_key(creator_2.skh),
      value: assets.from_lovelace(min_lovelace + backer_pledge),
      datum: NoDatum,
      reference_script: None,
    }

  campaign_datum
    |> crowdfunding.validate_spend_campaign(
        FinishCampaign,
        campaign_o_ref,
        Transaction {
          ..transaction.placeholder,
          inputs: [tx_input_from_script],
          outputs: [tx_output_to_a_different_creator],
          extra_signatories: [creator_2.pkh],
        },
      )
}

test validate_finish_campaign_negative_2() fail {
  let Pair(_, backer_1_pledge) = backer_1

  let campaign_datum =
    CampaignDatum { ..campaign_1, backers: [backer_1, ..campaign_1.backers] }

  let campaign_o_ref =
    OutputReference {
      transaction_id: #"01010000000000000000000000000000000000000000000000000056",
      output_index: 0,
    }

  let tx_input_from_script =
    Input(
      campaign_o_ref,
      Output {
        address: crowdfunding_address,
        value: assets.from_lovelace(min_lovelace + backer_1_pledge),
        datum: InlineDatum(campaign_datum),
        reference_script: None,
      },
    )

  let tx_output_to_creator =
    Output {
      address: campaign_1.creator.pkh
        |> address.from_verification_key
        |> address.with_delegation_key(campaign_1.creator.skh),
      value: assets.from_lovelace(min_lovelace + backer_1_pledge),
      datum: NoDatum,
      reference_script: None,
    }

  campaign_datum
    |> crowdfunding.validate_spend_campaign(
        FinishCampaign,
        campaign_o_ref,
        Transaction {
          ..transaction.placeholder,
          inputs: [tx_input_from_script],
          outputs: [tx_output_to_creator],
          extra_signatories: [campaign_1.creator.pkh],
        },
      )
}

// ## CancelCampaign
// ### CancelCampaign positive cases

test validate_cancel_campaign_positive_1() {
  trace @"Positive: No backer"

  let campaign_o_ref =
    OutputReference {
      transaction_id: #"01010000000000000000000000000000000000000000000000000056",
      output_index: 0,
    }

  let tx_input_from_script =
    Input(
      campaign_o_ref,
      Output {
        address: crowdfunding_address,
        value: assets.from_lovelace(min_lovelace),
        datum: InlineDatum(campaign_1),
        reference_script: None,
      },
    )

  let tx_output_to_creator =
    Output {
      address: campaign_1.creator.pkh
        |> address.from_verification_key
        |> address.with_delegation_key(campaign_1.creator.skh),
      value: assets.from_lovelace(min_lovelace),
      datum: NoDatum,
      reference_script: None,
    }

  campaign_1
    |> crowdfunding.validate_spend_campaign(
        CancelCampaign,
        campaign_o_ref,
        Transaction {
          ..transaction.placeholder,
          inputs: [tx_input_from_script],
          outputs: [tx_output_to_creator],
          extra_signatories: [campaign_1.creator.pkh],
        },
      )
}

test validate_cancel_campaign_positive_2() {
  trace @"Positive: Refund 1 backer"

  let Pair(backer_1_address, backer_1_pledge) = backer_1

  let campaign_datum =
    CampaignDatum { ..campaign_1, backers: [backer_1, ..campaign_1.backers] }

  let campaign_o_ref =
    OutputReference {
      transaction_id: #"01020000000000000000000000000000000000000000000000000056",
      output_index: 0,
    }

  let tx_input_from_script =
    Input(
      campaign_o_ref,
      Output {
        address: crowdfunding_address,
        value: assets.from_lovelace(min_lovelace + backer_1_pledge),
        datum: InlineDatum(campaign_datum),
        reference_script: None,
      },
    )

  let tx_output_to_backer =
    Output {
      address: backer_1_address.pkh
        |> address.from_verification_key
        |> address.with_delegation_key(backer_1_address.skh),
      value: assets.from_lovelace(backer_1_pledge),
      datum: NoDatum,
      reference_script: None,
    }

  campaign_datum
    |> crowdfunding.validate_spend_campaign(
        CancelCampaign,
        campaign_o_ref,
        Transaction {
          ..transaction.placeholder,
          inputs: [tx_input_from_script],
          outputs: [tx_output_to_backer],
          extra_signatories: [campaign_datum.creator.pkh],
        },
      )
}

test validate_cancel_campaign_positive_3() {
  trace @"Positive: Refund 2 backers"

  let Pair(backer_1_address, backer_1_pledge) = backer_1
  let Pair(backer_2_address, backer_2_pledge) = backer_2

  let campaign_datum =
    CampaignDatum {
      ..campaign_1,
      backers: [backer_1, backer_2, ..campaign_1.backers],
    }

  let campaign_o_ref =
    OutputReference {
      transaction_id: #"01030000000000000000000000000000000000000000000000000056",
      output_index: 0,
    }

  let tx_input_from_script =
    Input(
      campaign_o_ref,
      Output {
        address: crowdfunding_address,
        value: assets.from_lovelace(
          min_lovelace + backer_1_pledge + backer_2_pledge,
        ),
        datum: InlineDatum(campaign_datum),
        reference_script: None,
      },
    )

  let tx_output_to_backer_1 =
    Output {
      address: backer_1_address.pkh
        |> address.from_verification_key
        |> address.with_delegation_key(backer_1_address.skh),
      value: assets.from_lovelace(backer_1_pledge),
      datum: NoDatum,
      reference_script: None,
    }
  let tx_output_to_backer_2 =
    Output {
      address: backer_2_address.pkh
        |> address.from_verification_key
        |> address.with_delegation_key(backer_2_address.skh),
      value: assets.from_lovelace(backer_2_pledge),
      datum: NoDatum,
      reference_script: None,
    }

  campaign_datum
    |> crowdfunding.validate_spend_campaign(
        CancelCampaign,
        campaign_o_ref,
        Transaction {
          ..transaction.placeholder,
          inputs: [tx_input_from_script],
          outputs: [tx_output_to_backer_1, tx_output_to_backer_2],
          extra_signatories: [campaign_datum.creator.pkh],
        },
      )
}

test validate_cancel_campaign_positive_4() {
  trace @"Positive: Refund 3 backers"

  let Pair(backer_1_address, backer_1_pledge) = backer_1
  let Pair(backer_2_address, backer_2_pledge) = backer_2
  let Pair(backer_3_address, backer_3_pledge) = backer_3

  let campaign_datum =
    CampaignDatum {
      ..campaign_1,
      backers: [backer_1, backer_2, backer_3, ..campaign_1.backers],
    }

  let campaign_o_ref =
    OutputReference {
      transaction_id: #"01040000000000000000000000000000000000000000000000000056",
      output_index: 0,
    }

  let tx_input_from_script =
    Input(
      campaign_o_ref,
      Output {
        address: crowdfunding_address,
        value: assets.from_lovelace(
          min_lovelace + backer_1_pledge + backer_2_pledge + backer_3_pledge,
        ),
        datum: InlineDatum(campaign_datum),
        reference_script: None,
      },
    )

  let tx_output_to_backer_1 =
    Output {
      address: backer_1_address.pkh
        |> address.from_verification_key
        |> address.with_delegation_key(backer_1_address.skh),
      value: assets.from_lovelace(backer_1_pledge),
      datum: NoDatum,
      reference_script: None,
    }
  let tx_output_to_backer_2 =
    Output {
      address: backer_2_address.pkh
        |> address.from_verification_key
        |> address.with_delegation_key(backer_2_address.skh),
      value: assets.from_lovelace(backer_2_pledge),
      datum: NoDatum,
      reference_script: None,
    }
  let tx_output_to_backer_3 =
    Output {
      address: backer_3_address.pkh
        |> address.from_verification_key
        |> address.with_delegation_key(backer_3_address.skh),
      value: assets.from_lovelace(backer_3_pledge),
      datum: NoDatum,
      reference_script: None,
    }

  campaign_datum
    |> crowdfunding.validate_spend_campaign(
        CancelCampaign,
        campaign_o_ref,
        Transaction {
          ..transaction.placeholder,
          inputs: [tx_input_from_script],
          outputs: [
            tx_output_to_backer_1, tx_output_to_backer_2, tx_output_to_backer_3,
          ],
          extra_signatories: [campaign_datum.creator.pkh],
        },
      )
}

// ### CancelCampaign negative cases

test validate_cancel_campaign_negative_1() fail {
  let Pair(backer_1_address, backer_1_pledge) = backer_1
  let Pair(backer_2_address, backer_2_pledge) = backer_2
  let Pair(backer_3_address, backer_3_pledge) = backer_3

  let campaign_datum =
    CampaignDatum {
      ..campaign_1,
      backers: [backer_1, backer_2, backer_3, ..campaign_1.backers],
    }

  let campaign_o_ref =
    OutputReference {
      transaction_id: #"01010000000000000000000000000000000000000000000000000056",
      output_index: 0,
    }

  let tx_input_from_script =
    Input(
      campaign_o_ref,
      Output {
        address: crowdfunding_address,
        value: assets.from_lovelace(
          min_lovelace + backer_1_pledge + backer_2_pledge + backer_3_pledge,
        ),
        datum: InlineDatum(campaign_datum),
        reference_script: None,
      },
    )

  let tx_output_to_backer_1 =
    Output {
      address: backer_1_address.pkh
        |> address.from_verification_key
        |> address.with_delegation_key(backer_1_address.skh),
      value: assets.from_lovelace(backer_1_pledge),
      datum: NoDatum,
      reference_script: None,
    }
  let tx_output_to_backer_2 =
    Output {
      address: backer_2_address.pkh
        |> address.from_verification_key
        |> address.with_delegation_key(backer_2_address.skh),
      value: assets.from_lovelace(backer_2_pledge),
      datum: NoDatum,
      reference_script: None,
    }
  let tx_output_to_backer_3 =
    Output {
      address: backer_3_address.pkh
        |> address.from_verification_key
        |> address.with_delegation_key(backer_3_address.skh),
      value: assets.from_lovelace(backer_3_pledge),
      datum: NoDatum,
      reference_script: None,
    }

  trace @"Negative: Signed by another creator"
  campaign_datum
    |> crowdfunding.validate_spend_campaign(
        CancelCampaign,
        campaign_o_ref,
        Transaction {
          ..transaction.placeholder,
          inputs: [tx_input_from_script],
          outputs: [
            tx_output_to_backer_1, tx_output_to_backer_2, tx_output_to_backer_3,
          ],
          extra_signatories: [creator_2.pkh],
        },
      )
}

test validate_cancel_campaign_negative_2() fail {
  let Pair(backer_1_address, backer_1_pledge) = backer_1
  let Pair(_, backer_2_pledge) = backer_2
  let Pair(backer_3_address, backer_3_pledge) = backer_3

  let campaign_datum =
    CampaignDatum {
      ..campaign_1,
      backers: [backer_1, backer_2, backer_3, ..campaign_1.backers],
    }

  let campaign_o_ref =
    OutputReference {
      transaction_id: #"01020000000000000000000000000000000000000000000000000056",
      output_index: 0,
    }

  let tx_input_from_script =
    Input(
      campaign_o_ref,
      Output {
        address: crowdfunding_address,
        value: assets.from_lovelace(
          min_lovelace + backer_1_pledge + backer_2_pledge + backer_3_pledge,
        ),
        datum: InlineDatum(campaign_datum),
        reference_script: None,
      },
    )

  let tx_output_to_backer_1 =
    Output {
      address: backer_1_address.pkh
        |> address.from_verification_key
        |> address.with_delegation_key(backer_1_address.skh),
      value: assets.from_lovelace(backer_1_pledge),
      datum: NoDatum,
      reference_script: None,
    }

  trace @"Negative: Does not refund to all backers"
  let tx_output_to_creator =
    Output {
      address: campaign_datum.creator.pkh
        |> address.from_verification_key
        |> address.with_delegation_key(campaign_datum.creator.skh),
      value: assets.from_lovelace(backer_2_pledge),
      datum: NoDatum,
      reference_script: None,
    }

  let tx_output_to_backer_3 =
    Output {
      address: backer_3_address.pkh
        |> address.from_verification_key
        |> address.with_delegation_key(backer_3_address.skh),
      value: assets.from_lovelace(backer_3_pledge),
      datum: NoDatum,
      reference_script: None,
    }

  campaign_datum
    |> crowdfunding.validate_spend_campaign(
        CancelCampaign,
        campaign_o_ref,
        Transaction {
          ..transaction.placeholder,
          inputs: [tx_input_from_script],
          outputs: [
            tx_output_to_backer_1, tx_output_to_creator, tx_output_to_backer_3,
          ],
          extra_signatories: [campaign_datum.creator.pkh],
        },
      )
}
